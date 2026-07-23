import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import 'model_fetcher.dart';
import 'text_recognizer.dart';

/// Real [TextRecognizer] backed by Manga OCR (kha-white/manga-ocr-base,
/// Apache-2.0) run on-device via ONNX Runtime -- see docs/research/r3-ocr.md
/// §1 for the model background this implementation was built against.
///
/// The model is a Transformers `VisionEncoderDecoderModel`: a ViT/DeiT image
/// encoder feeding a character-level decoder, generated **autoregressively**.
/// There is no official ONNX export; this uses the community export at
/// [defaultEncoderModelUrl]/[defaultDecoderModelUrl] (a standard Optimum
/// `vision2seq-lm` export: separate `encoder_model.onnx` +
/// `decoder_model.onnx`, no KV-cache/`_with_past` variant, so every decode
/// step re-runs the decoder over the *entire* sequence generated so far --
/// see [_decodeLoop]).
///
/// **`vertical` is intentionally ignored.** Unlike Tesseract (which reads
/// vertical text horizontally unless told otherwise -- r3-ocr.md §2.2),
/// Manga OCR has no reading-direction concept at all: it's a generative
/// decoder over one fixed 224x224 crop, not a line-oriented recognizer, so
/// there is nothing in this model's inputs to configure per direction.
/// Accepted only because [TextRecognizer.recognizeCrop] requires it.
///
/// **Confidence** is the *minimum* per-token softmax probability across the
/// decoded sequence (each decode step's probability of the token it chose is
/// already computed to pick that token via argmax, so capturing it is free).
/// Minimum rather than mean: this value flows verbatim into
/// [RecognizedText.confidence] and from there into every `Token` sliced out
/// of the eventual OCR region (see `OcrRegionResult.confidence`'s doc
/// comment), which is meant to let low-confidence output be flagged for
/// review rather than silently trusted (r3-ocr.md's recommendation section).
/// A mean would let one badly-misrecognized character hide inside an
/// otherwise-long, mostly-correct string; min surfaces exactly that
/// character's uncertainty instead, matching the "flag if anything looks
/// wrong" purpose rather than an "overall average quality" one.
///
/// **Safety caps against decoder runaway** (r3-ocr.md §1.4: a desktop
/// reference implementation saw 1.8-40s/crop, with bad crops grinding to the
/// max-length cap instead of hitting EOS): [maxDecodeLength] mirrors the
/// reference's 300-token cap, and [decodeTimeout] is an independent
/// wall-clock budget checked between decode steps. Neither the model's own
/// EOS behavior nor the max-length cap alone is trusted -- if the loop is
/// abandoned without reaching EOS for *either* reason, the resulting
/// [RecognizedText.confidence] is explicitly capped low (see
/// [_abandonedConfidenceCeiling]) rather than reported at whatever the
/// per-step probabilities happened to average out to.
///
/// **A real, verified discrepancy versus how this model is sometimes
/// summarized** (including in this project's own r3-ocr.md): the reference
/// Python pipeline (`manga_ocr/ocr.py`) calls
/// `model.generate(pixel_values, max_length=300)` with no explicit
/// `num_beams` override. That looks like greedy decoding, but
/// kha-white/manga-ocr-base's actual `config.json` (confirmed directly, and
/// corroborated by the auto-derived `generation_config.json` shipped
/// alongside the mayocream ONNX export) sets `num_beams: 4`,
/// `length_penalty: 2.0`, `no_repeat_ngram_size: 3`, `early_stopping: true`
/// as the real generation defaults -- meaning the true upstream reference
/// almost certainly runs **beam search**, not greedy decoding. This
/// implementation still deliberately uses **greedy** decoding per this
/// task's explicit scope (matching output *shape* was prioritized over
/// matching upstream defaults, and beam search was explicitly out of
/// scope) -- but that means this recognizer's output is not guaranteed to
/// match kha-white/manga-ocr's actual default output on the same input,
/// even with byte-identical pre/post-processing. Worth knowing before using
/// this as an accuracy baseline.
class MangaOcrRecognizer implements TextRecognizer {
  MangaOcrRecognizer._({
    required this.vocab,
    required this._encoderSession,
    required this._decoderSession,
    required this.maxDecodeLength,
    required this.decodeTimeout,
  });

  /// mayocream/manga-ocr-onnx: a standard Optimum `vision2seq-lm` export of
  /// kha-white/manga-ocr-base (docs/research/r3-ocr.md §1.2). Chosen over
  /// the research doc's other listed option,
  /// l0wgear/manga-ocr-2025-onnx, after actually checking both repos' file
  /// sizes: l0wgear's `encoder_model.onnx` is only ~22MB, implausibly small
  /// for this DeiT-base-patch16-224 encoder (mayocream's is ~343MB, which
  /// matches manga-ocr-rs's independently-reported ~328MB fp32 encoder size
  /// almost exactly) -- so l0wgear's export is suspected broken/incomplete
  /// rather than a legitimate smaller variant, and wasn't investigated
  /// further given mayocream's sizes already corroborate the known-good
  /// reference data point.
  static const defaultEncoderModelUrl =
      'https://huggingface.co/mayocream/manga-ocr-onnx/resolve/main/encoder_model.onnx';
  static const defaultDecoderModelUrl =
      'https://huggingface.co/mayocream/manga-ocr-onnx/resolve/main/decoder_model.onnx';

  static const _inputSize = 224;

  // Fixed by kha-white/manga-ocr-base's config.json + vocab.txt ordering
  // (verified directly: vocab.txt line 1-5 are [PAD] [UNK] [CLS] [SEP]
  // [MASK] at 0-based indices 0-4, matching config.json's
  // decoder_start_token_id=2, eos_token_id=3, pad_token_id=0 exactly).
  static const _padTokenId = 0;
  static const _unkTokenId = 1;
  static const _clsTokenId = 2;
  static const _sepTokenId = 3;
  static const _maskTokenId = 4;
  static const _specialTokenIds = {
    _padTokenId,
    _unkTokenId,
    _clsTokenId,
    _sepTokenId,
    _maskTokenId,
  };

  static const _inputIdsInputName = 'input_ids';
  static const _encoderHiddenStatesInputName = 'encoder_hidden_states';
  static const _encoderAttentionMaskInputName = 'encoder_attention_mask';
  static const _logitsOutputName = 'logits';

  /// Confidence ceiling applied when the decode loop is abandoned (hit
  /// [maxDecodeLength] or [decodeTimeout]) without the model reaching EOS
  /// itself. See class doc comment.
  static const _abandonedConfidenceCeiling = 0.1;

  /// Character-level vocab: `vocab[tokenId]` is the token's string (almost
  /// always a single character). Index-aligned with the ONNX decoder's
  /// output logits and with the special token ids above.
  final List<String> vocab;
  final OrtSession _encoderSession;
  final OrtSession _decoderSession;

  /// Hard cap on generated sequence length, mirroring the reference's
  /// `generate(..., max_length=300)`. Counts the initial decoder-start
  /// token, i.e. at most `maxDecodeLength - 1` new tokens are generated.
  final int maxDecodeLength;

  /// Wall-clock budget for the whole decode loop for one crop, checked
  /// between steps (not preemptive mid-step -- see [_decodeLoop]). Chosen
  /// generously relative to r3-ocr.md's 1.8-40s/crop desktop data point,
  /// since this implementation is additionally uncached (no
  /// `decoder_with_past` ONNX variant exists in the community export -- see
  /// class doc comment), so every step redoes attention over the whole
  /// sequence so far and is expected to be slower than that reference.
  final Duration decodeTimeout;

  /// Loads both ONNX sessions (via [modelFetcher], fetch-on-first-use +
  /// locally cached -- see `ModelFetcher`'s own doc comment) and the
  /// character vocab, and returns a ready-to-use recognizer. Downloads and
  /// session creation happen eagerly here (not lazily on first
  /// [recognizeCrop]) so that a successfully-returned instance is already
  /// proof the real ONNX Runtime native init path actually worked on this
  /// platform, rather than deferring that discovery to first use.
  static Future<MangaOcrRecognizer> create({
    ModelFetcher modelFetcher = const HttpModelFetcher(),
    OnnxRuntime? onnxRuntime,
    String encoderUrl = defaultEncoderModelUrl,
    String decoderUrl = defaultDecoderModelUrl,
    int maxDecodeLength = 300,
    Duration decodeTimeout = const Duration(seconds: 60),
    List<String>? vocab,
    AssetBundle? assetBundle,
  }) async {
    final ort = onnxRuntime ?? OnnxRuntime();
    final resolvedVocab = vocab ?? await loadMangaOcrVocab(bundle: assetBundle);

    final encoderFile = await modelFetcher.ensureDownloaded(
      url: encoderUrl,
      subDir: 'manga_ocr',
      fileName: 'encoder_model.onnx',
    );
    final decoderFile = await modelFetcher.ensureDownloaded(
      url: decoderUrl,
      subDir: 'manga_ocr',
      fileName: 'decoder_model.onnx',
    );

    final encoderSession = await ort.createSession(encoderFile.path);
    final decoderSession = await ort.createSession(decoderFile.path);

    // Fail fast and loud if the community export doesn't match the shape
    // this implementation was written against, rather than silently
    // mis-mapping tensors -- see class doc comment re: this export's
    // provenance not being an officially-supported path.
    if (encoderSession.inputNames.length != 1 ||
        encoderSession.outputNames.length != 1) {
      throw StateError(
        'MangaOcrRecognizer: expected the encoder ONNX session to have '
        'exactly 1 input and 1 output; got '
        'inputNames=${encoderSession.inputNames}, '
        'outputNames=${encoderSession.outputNames}. The community ONNX '
        'export may not match the expected Optimum vision2seq-lm shape.',
      );
    }
    final decoderInputSet = decoderSession.inputNames.toSet();
    if (!decoderInputSet.contains(_inputIdsInputName) ||
        !decoderInputSet.contains(_encoderHiddenStatesInputName)) {
      throw StateError(
        'MangaOcrRecognizer: expected the decoder ONNX session to have '
        'inputs named "$_inputIdsInputName" and '
        '"$_encoderHiddenStatesInputName"; got '
        '${decoderSession.inputNames}. The community ONNX export may use '
        'different input names than expected.',
      );
    }

    return MangaOcrRecognizer._(
      vocab: resolvedVocab,
      encoderSession: encoderSession,
      decoderSession: decoderSession,
      maxDecodeLength: maxDecodeLength,
      decodeTimeout: decodeTimeout,
    );
  }

  @override
  Future<RecognizedText> recognizeCrop(
    Uint8List cropPixels, {
    required int width,
    required int height,
    required bool vertical, // ignored -- see class doc comment.
  }) async {
    final pixelValues = _preprocessToTensor(cropPixels, width, height);
    final pixelTensor = await OrtValue.fromList(pixelValues, [
      1,
      3,
      _inputSize,
      _inputSize,
    ]);

    final Map<String, OrtValue> encoderOutputs;
    try {
      encoderOutputs = await _encoderSession.run({
        _encoderSession.inputNames.single: pixelTensor,
      });
    } finally {
      await pixelTensor.dispose();
    }

    final encoderHiddenStates =
        encoderOutputs[_encoderSession.outputNames.single]!;
    try {
      return await _decodeLoop(encoderHiddenStates);
    } finally {
      await encoderHiddenStates.dispose();
    }
  }

  /// Builds the ViT input tensor from a raw BGRA8888 crop: grayscale -> RGB
  /// (luma replicated across channels) -> resized to a fixed 224x224 square
  /// -> normalized to [-1, 1] -- see docs/research/r3-ocr.md §1.1 and
  /// §1.3, and `preprocessor_config.json`
  /// (kha-white/manga-ocr-base, verified directly): `do_resize: true,
  /// size: 224, do_normalize: true, image_mean/std: [0.5,0.5,0.5],
  /// resample: 2 (PIL BILINEAR)`.
  ///
  /// The resize is a direct (aspect-ratio-ignoring) squash to a square, not
  /// a crop -- correct for `ViTFeatureExtractor` with an integer `size`, but
  /// meaning a tall vertical text column will be squashed badly if handed
  /// to this method whole; chunking tall columns into near-square sub-crops
  /// is the caller's job (a separate region-detection step), not this
  /// method's -- see [TextRecognizer]'s own doc comment.
  Float32List _preprocessToTensor(Uint8List cropPixels, int width, int height) {
    img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: cropPixels.buffer,
      bytesOffset: cropPixels.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.bgra,
    );
    // Reference: `img.convert("L").convert("RGB")`. `image`'s grayscale()
    // uses the same ITU-R BT.601 luma weights PIL does (0.299/0.587/0.114),
    // replicated across r/g/b -- verified directly against both packages'
    // source rather than assumed.
    image = img.grayscale(image);
    image = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // NCHW float32, mean/std 0.5 per channel => pixel/255*2 - 1.
    final tensor = Float32List(3 * _inputSize * _inputSize);
    final plane = _inputSize * _inputSize;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        final idx = y * _inputSize + x;
        tensor[idx] = (pixel.r / 255.0) * 2 - 1;
        tensor[plane + idx] = (pixel.g / 255.0) * 2 - 1;
        tensor[2 * plane + idx] = (pixel.b / 255.0) * 2 - 1;
      }
    }
    return tensor;
  }

  /// Runs the encoder once, then greedily decodes token-by-token (no beam
  /// search -- see class doc comment) until EOS, [maxDecodeLength], or
  /// [decodeTimeout], whichever comes first.
  ///
  /// There is no `decoder_with_past` ONNX variant in this community export
  /// (only a plain `decoder_model.onnx`), so every step below re-runs the
  /// decoder over the *entire* token sequence generated so far and discards
  /// every output row except the last -- this is the O(n^2)-total-work
  /// shape r3-ocr.md's latency warning is about, not a bug in this loop.
  Future<RecognizedText> _decodeLoop(OrtValue encoderHiddenStates) async {
    final encoderSeqLen = encoderHiddenStates.shape[1];
    final decoderNeedsAttentionMask = _decoderSession.inputNames.contains(
      _encoderAttentionMaskInputName,
    );
    final attentionMask = decoderNeedsAttentionMask
        ? await OrtValue.fromList(Int64List.fromList(List.filled(encoderSeqLen, 1)), [
            1,
            encoderSeqLen,
          ])
        : null;

    final tokenIds = <int>[_clsTokenId];
    final stepConfidences = <double>[];
    final stopwatch = Stopwatch()..start();
    var reachedEos = false;

    try {
      while (tokenIds.length < maxDecodeLength) {
        if (stopwatch.elapsed > decodeTimeout) break;

        final inputIdsTensor = await OrtValue.fromList(
          Int64List.fromList(tokenIds),
          [1, tokenIds.length],
        );
        final Map<String, OrtValue> outputs;
        try {
          outputs = await _decoderSession.run({
            _inputIdsInputName: inputIdsTensor,
            _encoderHiddenStatesInputName: encoderHiddenStates,
            _encoderAttentionMaskInputName: ?attentionMask,
          });
        } finally {
          await inputIdsTensor.dispose();
        }

        try {
          final logitsValue =
              outputs[_logitsOutputName] ?? outputs[_decoderSession.outputNames.single];
          if (logitsValue == null) {
            throw StateError(
              'MangaOcrRecognizer: decoder output missing '
              '"$_logitsOutputName" (actual output names: '
              '${_decoderSession.outputNames}).',
            );
          }
          if (logitsValue.shape.length != 3) {
            throw StateError(
              'MangaOcrRecognizer: expected decoder logits to be rank 3 '
              '[batch, seq, vocab]; got shape ${logitsValue.shape}.',
            );
          }
          final vocabSize = logitsValue.shape.last;
          final flatLogits = await logitsValue.asFlattenedList();

          final lastRowStart = flatLogits.length - vocabSize;
          final lastLogits = <double>[
            for (var i = lastRowStart; i < flatLogits.length; i++)
              (flatLogits[i] as num).toDouble(),
          ];
          final step = argmaxSoftmaxProbability(lastLogits);
          tokenIds.add(step.index);
          stepConfidences.add(step.probability);

          if (step.index == _sepTokenId) {
            reachedEos = true;
            break;
          }
        } finally {
          for (final value in outputs.values) {
            await value.dispose();
          }
        }
      }
    } finally {
      stopwatch.stop();
      await attentionMask?.dispose();
    }

    final rawText = _idsToRawText(tokenIds);
    final text = mangaOcrPostProcess(rawText);

    var confidence = stepConfidences.isEmpty
        ? 0.0
        : stepConfidences.reduce(math.min);
    if (!reachedEos) {
      confidence = math.min(confidence, _abandonedConfidenceCeiling);
    }

    return RecognizedText(text: text, confidence: confidence);
  }

  /// Maps generated token ids to their vocab strings, skipping special
  /// tokens (mirrors the reference's `tokenizer.decode(x,
  /// skip_special_tokens=True)`). No separator is inserted between
  /// characters: this is a character-level tokenizer (not wordpiece), so
  /// the reference's own `tokenizer.decode` would join tokens with spaces
  /// and [mangaOcrPostProcess]'s very first step immediately strips all of
  /// them again (`"".join(text.split())`) -- concatenating directly here is
  /// simpler and produces an identical result after postprocessing.
  String _idsToRawText(List<int> ids) {
    final buffer = StringBuffer();
    for (final id in ids) {
      if (_specialTokenIds.contains(id)) continue;
      if (id < 0 || id >= vocab.length) {
        throw StateError(
          'MangaOcrRecognizer: decoded token id $id is out of vocab range '
          '(vocab size ${vocab.length}).',
        );
      }
      buffer.write(vocab[id]);
    }
    return buffer.toString();
  }

  /// Releases both ONNX sessions' native resources. Not part of
  /// [TextRecognizer]; callers that own a [MangaOcrRecognizer] directly
  /// (rather than through the interface) should call this when done with
  /// it.
  Future<void> dispose() async {
    await _encoderSession.close();
    await _decoderSession.close();
  }
}

/// Loads Manga OCR's character-level vocab from the bundled asset
/// (`assets/manga_ocr/vocab.txt`, committed verbatim from
/// kha-white/manga-ocr-base -- see pubspec.yaml's `assets:` entry). Small
/// and stable enough to bundle, unlike the ~450MB ONNX model weights, which
/// stay gitignored and are fetched at runtime via [ModelFetcher].
///
/// Splits on `\n` (tolerating a `\r` per line and a single trailing
/// newline) without trimming each line's own content, since a line could
/// legitimately *be* a single space character -- `String.trim()` would
/// silently corrupt that entry into an empty string.
Future<List<String>> loadMangaOcrVocab({AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(
    'assets/manga_ocr/vocab.txt',
  );
  final withoutTrailingNewline = raw.endsWith('\n')
      ? raw.substring(0, raw.length - 1)
      : raw;
  return withoutTrailingNewline
      .split('\n')
      .map((line) => line.endsWith('\r') ? line.substring(0, line.length - 1) : line)
      .toList();
}

/// Index of the largest logit and the softmax probability of that same
/// index -- i.e. the confidence of the greedy (argmax) choice. Computed
/// without materializing the full softmax vector (only the chosen token's
/// probability is ever needed): since `softmax(logits)[argmax] = 1 /
/// sum(exp(logits[i] - max(logits)))`, and `exp(max-max) = 1` is exactly
/// the numerator, this is both correct and numerically stable (the usual
/// max-subtraction trick) without an extra pass to look the numerator back
/// up.
({int index, double probability}) argmaxSoftmaxProbability(
  List<double> logits,
) {
  if (logits.isEmpty) {
    throw ArgumentError('argmaxSoftmaxProbability: logits must not be empty');
  }
  var maxIndex = 0;
  var maxLogit = logits[0];
  for (var i = 1; i < logits.length; i++) {
    if (logits[i] > maxLogit) {
      maxLogit = logits[i];
      maxIndex = i;
    }
  }
  var sumExp = 0.0;
  for (final logit in logits) {
    sumExp += math.exp(logit - maxLogit);
  }
  return (index: maxIndex, probability: 1.0 / sumExp);
}

/// Faithful port of kha-white/manga-ocr's `post_process`
/// (`manga_ocr/ocr.py`, fetched and read directly rather than reimplemented
/// from a description -- see docs/research/r3-ocr.md §1.1):
///
/// ```python
/// def post_process(text):
///     text = "".join(text.split())
///     text = text.replace("…", "...")
///     text = re.sub("[・.]{2,}", lambda x: (x.end() - x.start()) * ".", text)
///     text = jaconv.h2z(text, ascii=True, digit=True)
///     return text
/// ```
///
/// **A correction versus how step 4 is sometimes summarized**: jaconv's
/// `h2z(text, ignore='', kana=True, ascii=False, digit=False)` defaults
/// `kana` to `True`, and the reference call above does not override it --
/// verified directly against jaconv's source
/// (ikegami-yukino/jaconv/jaconv.py). So this step *also* normalizes
/// half-width katakana (merging dakuten/handakuten pairs into a single
/// full-width character first, then mapping the rest via a table), not
/// just ASCII and digits. See [_applyDakutenMerge] and
/// [_kanaSeionCodepoints].
String mangaOcrPostProcess(String text) {
  var result = text;
  // 1. "".join(text.split()) -- strip all whitespace.
  result = result.replaceAll(RegExp(r'\s'), '');
  // 2. "…" -> "...".
  result = result.replaceAll('…', '...');
  // 3. re.sub("[・.]{2,}", lambda x: (x.end()-x.start())*".", text) -- a run
  // of 2+ ・ or . becomes that same number of '.'.
  result = result.replaceAllMapped(
    RegExp('[・.]{2,}'),
    (match) => '.' * match.group(0)!.length,
  );
  // 4. jaconv.h2z(text, ascii=True, digit=True) (kana=True by default).
  result = _applyDakutenMerge(result);
  result = _h2zAsciiDigitKana(result);
  return result;
}

/// (half-width kana codepoint 1, half-width dakuten/handakuten mark
/// codepoint 2, merged full-width codepoint) triples, mechanically
/// extracted from jaconv's `_conv_dakuten` (ikegami-yukino/jaconv/jaconv.py)
/// by running that exact function source through Python and dumping its
/// literal `.replace()` pairs as hex codepoints -- not hand-transcribed --
/// to eliminate any risk of a silent transcription error among ~50
/// Japanese characters. U+FF9E/U+FF9F are the half-width dakuten/handakuten
/// combining marks.
const _dakutenTriples = <(int, int, int)>[
  (0xFF76, 0xFF9E, 0x30AC),
  (0xFF77, 0xFF9E, 0x30AE),
  (0xFF78, 0xFF9E, 0x30B0),
  (0xFF79, 0xFF9E, 0x30B2),
  (0xFF7A, 0xFF9E, 0x30B4),
  (0xFF7B, 0xFF9E, 0x30B6),
  (0xFF7C, 0xFF9E, 0x30B8),
  (0xFF7D, 0xFF9E, 0x30BA),
  (0xFF7E, 0xFF9E, 0x30BC),
  (0xFF7F, 0xFF9E, 0x30BE),
  (0xFF80, 0xFF9E, 0x30C0),
  (0xFF81, 0xFF9E, 0x30C2),
  (0xFF82, 0xFF9E, 0x30C5),
  (0xFF83, 0xFF9E, 0x30C7),
  (0xFF84, 0xFF9E, 0x30C9),
  (0xFF8A, 0xFF9E, 0x30D0),
  (0xFF8B, 0xFF9E, 0x30D3),
  (0xFF8C, 0xFF9E, 0x30D6),
  (0xFF8D, 0xFF9E, 0x30D9),
  (0xFF8E, 0xFF9E, 0x30DC),
  (0xFF8A, 0xFF9F, 0x30D1),
  (0xFF8B, 0xFF9F, 0x30D4),
  (0xFF8C, 0xFF9F, 0x30D7),
  (0xFF8D, 0xFF9F, 0x30DA),
  (0xFF8E, 0xFF9F, 0x30DD),
  (0xFF73, 0xFF9E, 0x30F4),
];

String _applyDakutenMerge(String text) {
  var result = text;
  for (final (half1, half2, full) in _dakutenTriples) {
    result = result.replaceAll(
      String.fromCharCodes([half1, half2]),
      String.fromCharCode(full),
    );
  }
  return result;
}

/// Half-width katakana (JIS X 0201, seion/unvoiced forms only -- voiced and
/// semi-voiced forms are already merged by [_applyDakutenMerge] before this
/// table is consulted) -> full-width katakana codepoint. Mechanically
/// extracted from jaconv's own `H2Z_K` table (ikegami-yukino/jaconv,
/// conv_table.py: `_to_dict(HALF_KANA_SEION_ORD, FULL_KANA_SEION)`) by
/// executing that module's real source through Python and dumping the
/// resulting dict as hex codepoint pairs -- not hand-transcribed -- for the
/// same reason as [_dakutenTriples]. (jaconv's own table additionally maps
/// seven already-full-width characters with no half-width JIS X 0201 form,
/// e.g. ヮヰヱヵヶヽヾ, to themselves as harmless no-ops; omitted here since a
/// table miss already leaves a character unchanged, which is the same
/// result.)
const _kanaSeionCodepoints = <int, int>{
  0xFF61: 0x3002,
  0xFF62: 0x300C,
  0xFF63: 0x300D,
  0xFF64: 0x3001,
  0xFF65: 0x30FB,
  0xFF66: 0x30F2,
  0xFF67: 0x30A1,
  0xFF68: 0x30A3,
  0xFF69: 0x30A5,
  0xFF6A: 0x30A7,
  0xFF6B: 0x30A9,
  0xFF6C: 0x30E3,
  0xFF6D: 0x30E5,
  0xFF6E: 0x30E7,
  0xFF6F: 0x30C3,
  0xFF70: 0x30FC,
  0xFF71: 0x30A2,
  0xFF72: 0x30A4,
  0xFF73: 0x30A6,
  0xFF74: 0x30A8,
  0xFF75: 0x30AA,
  0xFF76: 0x30AB,
  0xFF77: 0x30AD,
  0xFF78: 0x30AF,
  0xFF79: 0x30B1,
  0xFF7A: 0x30B3,
  0xFF7B: 0x30B5,
  0xFF7C: 0x30B7,
  0xFF7D: 0x30B9,
  0xFF7E: 0x30BB,
  0xFF7F: 0x30BD,
  0xFF80: 0x30BF,
  0xFF81: 0x30C1,
  0xFF82: 0x30C4,
  0xFF83: 0x30C6,
  0xFF84: 0x30C8,
  0xFF85: 0x30CA,
  0xFF86: 0x30CB,
  0xFF87: 0x30CC,
  0xFF88: 0x30CD,
  0xFF89: 0x30CE,
  0xFF8A: 0x30CF,
  0xFF8B: 0x30D2,
  0xFF8C: 0x30D5,
  0xFF8D: 0x30D8,
  0xFF8E: 0x30DB,
  0xFF8F: 0x30DE,
  0xFF90: 0x30DF,
  0xFF91: 0x30E0,
  0xFF92: 0x30E1,
  0xFF93: 0x30E2,
  0xFF94: 0x30E4,
  0xFF95: 0x30E6,
  0xFF96: 0x30E8,
  0xFF97: 0x30E9,
  0xFF98: 0x30EA,
  0xFF99: 0x30EB,
  0xFF9A: 0x30EC,
  0xFF9B: 0x30ED,
  0xFF9C: 0x30EF,
  0xFF9D: 0x30F3,
};

/// jaconv.h2z(text, ascii=True, digit=True) with kana at its default of
/// True. ASCII/digit is a single uniform `codepoint + 0xFEE0` shift over
/// 0x21-0x7E plus space(0x20)->U+3000 -- verified equivalent to jaconv's
/// actual (separately-tabled) `H2Z_A`/`H2Z_D` union for this specific
/// ascii=True+digit=True combination by executing jaconv's real source and
/// comparing dicts, not assumed.
String _h2zAsciiDigitKana(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x21 && rune <= 0x7E) {
      buffer.writeCharCode(rune + 0xFEE0);
    } else if (rune == 0x20) {
      buffer.writeCharCode(0x3000);
    } else {
      final mapped = _kanaSeionCodepoints[rune];
      buffer.writeCharCode(mapped ?? rune);
    }
  }
  return buffer.toString();
}
