import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';

import 'model_fetcher.dart';
import 'text_region_detector.dart';

/// [TextRegionDetector] backed by [comic-text-detector](https://github.com/dmMaze/comic-text-detector)'s
/// pretrained ONNX weights -- see docs/research/r6-manga-text-detection.md §2
/// for the full research behind this choice.
///
/// **Licensing note (flag, don't assume):** comic-text-detector is
/// GPL-3.0-licensed (r6 §2.5). Wiring this class into the app is fine for
/// local development/testing, but bundling/shipping this model in a
/// distributed build is a real distribution-license decision that has not
/// been made -- do not treat its presence here as that decision having
/// already happened.
///
/// ### What this does and doesn't port
///
/// The real model has a shared backbone feeding two heads: a YOLOv5 head
/// (ONNX output `blk`, raw text-*block* bounding boxes) and a DBNet-style
/// segmentation head (`seg`/`det`, a per-pixel text mask plus the raw
/// probability maps DB's box-formation algorithm turns into per-*line*
/// polygons). This class **only decodes `blk`**: standard YOLO postprocessing
/// (confidence filter, xywh->xyxy, NMS), then maps boxes from the model's
/// letterboxed input frame back to the source page's pixel coordinates. This
/// alone replaces `ScannedPdfImporter`'s whole-page-is-one-region stub with
/// real per-block detection. It deliberately does **not** port DB's
/// box-formation/polygon-extraction algorithm (`utils/db_utils.py`'s
/// `SegDetectorRepresenter` in the reference repo) to get finer-grained
/// per-line regions from `seg`/`det` -- a separate, larger porting task
/// (r6-manga-text-detection.md §2.4) left for later.
///
/// Detections are always axis-aligned, per [DetectedTextRegion]'s own doc
/// comment -- this model's raw YOLO boxes are already axis-aligned rectangles
/// (rotation only would show up via DB's polygon path, which isn't ported
/// here), so no reduction step is even needed in practice.
///
/// ### Pretrained weights
///
/// Fetched on first use via [ModelFetcher] (same fetch-on-first-use pattern
/// as the Yomitan/Sudachi dictionary assets) from the pretrained ONNX export
/// comic-text-detector's own README points to:
/// `https://github.com/zyddnys/manga-image-translator/releases/download/beta-0.2.1/comictextdetector.pt.onnx`.
/// Confirmed via a real `HEAD` request against that URL (not just quoted from
/// research notes) to be a real, reachable, 94,669,756-byte file, matching
/// r6's own independently-sourced figure. ONNX graph: `input_names=['images']`,
/// `output_names=['blk','seg','det']` (confirmed directly from the reference
/// repo's own `utils/export.py`).
///
/// ### Preprocessing -- ported from the reference repo's own source, not just
/// the research summary
///
/// Fetched and read `inference.py`/`basemodel.py`/`utils/imgproc_utils.py`
/// directly from github.com/dmMaze/comic-text-detector to confirm the exact
/// pipeline (some details the research doc didn't spell out, notably the
/// padding alignment below, matter for correctness):
///
/// 1. BGRA8888 -> RGB (alpha dropped; the model has no use for it).
/// 2. **Letterbox** to a 1024x1024 square: resize preserving aspect ratio so
///    the *longer* source dimension becomes 1024 (`r = min(1024/h, 1024/w)`,
///    matching `imgproc_utils.letterbox`'s `scaleup=True` default -- this
///    upscales small pages too, not just downscales large ones), then pad
///    the remainder with **black, added only to the bottom/right** -- *not*
///    centered. This project's first instinct (and standard YOLOv5-tutorial
///    letterboxing) centers the padding, but this reference repo's own copy
///    of `letterbox()` has that centering step commented out
///    (`# dw /= 2  # divide padding into 2 sides` is dead code in the
///    fetched source), so the resized image is anchored at the input's
///    top-left corner instead. Getting this wrong wouldn't break inference
///    (the model would still run) but would silently shift every detected
///    box by half the padding width/height once mapped back to page
///    coordinates -- exactly the kind of bug that looks plausible without a
///    real image to check it against.
/// 3. Normalize by `/255` only (no mean/std subtraction) -- confirmed via
///    `basemodel.py`'s `TextDetBaseDNN.__call__`:
///    `cv2.dnn.blobFromImage(im_in, scalefactor=1/255.0, size=(1024,1024))`
///    with `swapRB` left at its default `False`, i.e. no further channel
///    reordering beyond step 1's BGRA->RGB (the size the model is fed here is
///    already exactly 1024x1024 from step 2, so blobFromImage's own resize is
///    a no-op).
/// 4. NCHW, batch size 1.
///
/// ### Postprocessing
///
/// `blk` is standard, already-decoded YOLOv5 export output (boxes already in
/// absolute-pixel `[cx, cy, w, h, objectness, ...classScores]` form, shape
/// `[1, numAnchors, 5+numClasses]` -- the number of classes is read from the
/// tensor's own shape rather than hardcoded, since it varies across training
/// runs/exports and doesn't matter for this class's purpose anyway: box
/// geometry, not the eng/ja/unknown language label). Postprocessing mirrors
/// `utils/yolov5_utils.non_max_suppression`: combined confidence =
/// objectness x best class score, xywh -> xyxy, then greedy NMS. One
/// deliberate deviation from the reference: NMS here is **class-agnostic**
/// (boxes of different predicted classes can still suppress each other),
/// whereas the reference offsets boxes by class index before computing IoU so
/// NMS runs independently per class. Since [DetectedTextRegion] has no class
/// label at all (this class only ever returns bounding boxes, never which
/// language a block is predicted to contain), class-agnostic NMS is
/// equivalent-or-more-conservative for this use case (it can only merge
/// *more* overlapping boxes, never fewer) and is simpler to implement and
/// verify.
class ComicTextDetector implements TextRegionDetector {
  ComicTextDetector({
    this.modelFetcher = const HttpModelFetcher(),
    this.confidenceThreshold = defaultConfidenceThreshold,
    this.iouThreshold = defaultIouThreshold,
  });

  static const String modelUrl =
      'https://github.com/zyddnys/manga-image-translator/releases/download/'
      'beta-0.2.1/comictextdetector.pt.onnx';

  /// [ModelFetcher.ensureDownloaded]'s `subDir`/`fileName` for this model --
  /// public (not private) so callers/tests can pre-warm or independently
  /// inspect the cached file (e.g. to time/measure the download separately
  /// from session creation + inference) without duplicating these strings.
  static const String modelSubDir = 'comic_text_detector';
  static const String modelFileName = 'comictextdetector.pt.onnx';

  /// Square input resolution the pretrained weights were exported/traced
  /// for. 1024, not the 640 YOLOv5 conventionally uses -- confirmed directly
  /// from `inference.py`'s own usage (`TextDetector(model_path,
  /// input_size=1024, ...)`), not the unrelated `export_onnx` docstring that
  /// mentions 640 (see r6-manga-text-detection.md §2.3's own callout of this
  /// exact mixup risk).
  static const int inputSize = 1024;

  /// Objectness x class-confidence threshold below which a raw detection is
  /// discarded before NMS.
  ///
  /// Reuses the reference implementation's own default
  /// (`inference.py`'s `TextDetector.__init__` default `conf_thresh=0.4`)
  /// rather than a freshly-tuned value: this is the upstream model authors'
  /// own empirically-chosen operating point for these exact weights, and
  /// this project has no held-out labeled validation set of its own to tune
  /// a "better" number against -- reusing their default is more trustworthy
  /// than guessing a new one, and re-tuning for accuracy is explicitly out
  /// of scope for this pass anyway.
  static const double defaultConfidenceThreshold = 0.4;

  /// IoU threshold above which two candidate boxes are treated as the same
  /// detection during NMS (the higher-confidence one is kept).
  ///
  /// Reuses the reference's own default (`nms_thresh=0.35`), for the same
  /// reason as [defaultConfidenceThreshold] -- an upstream-tuned operating
  /// point beats a fresh guess.
  static const double defaultIouThreshold = 0.35;

  /// Supplies (and caches) the local ONNX weights file -- see
  /// `model_fetcher.dart`'s own doc comment. Public (matching this
  /// codebase's convention for injected dependencies, e.g.
  /// `OcrResultCache.directoryOverride`) so tests can both inject a fake and
  /// inspect which one an instance is using.
  final ModelFetcher modelFetcher;

  /// See [defaultConfidenceThreshold]'s doc comment.
  final double confidenceThreshold;

  /// See [defaultIouThreshold]'s doc comment.
  final double iouThreshold;

  Future<OrtSession>? _sessionFuture;

  Future<OrtSession> _ensureSession() {
    final existing = _sessionFuture;
    if (existing != null) return existing;
    final created = _createSession();
    _sessionFuture = created;
    // Don't memoize a *failure*: a transient network blip while downloading
    // the ~90MB model shouldn't permanently wedge this detector instance for
    // the rest of its lifetime. The caller's own awaited `created` still
    // sees the real error; this only resets internal state so the next
    // `detect()` call gets a fresh retry instead of replaying a stale one.
    created.catchError((Object error) {
      if (identical(_sessionFuture, created)) _sessionFuture = null;
      // Return type is `OrtSession`, unreachable in practice since this
      // callback only runs when `created` completed with an error and
      // `catchError` here exists purely for its state-reset side effect;
      // rethrowing keeps that error visible to anyone else awaiting
      // `created` (harmless if no one else is).
      throw error;
    });
    return created;
  }

  Future<OrtSession> _createSession() async {
    final modelFile = await modelFetcher.ensureDownloaded(
      url: modelUrl,
      subDir: modelSubDir,
      fileName: modelFileName,
    );
    return OnnxRuntime().createSession(modelFile.path);
  }

  /// Releases the underlying ONNX Runtime session, if one was created.
  /// Not part of [TextRegionDetector] (that interface has no lifecycle
  /// beyond [detect]) -- callers/tests that construct a real
  /// [ComicTextDetector] should call this when done to free native
  /// resources, the same way [OrtSession.close] itself must be called.
  Future<void> dispose() async {
    final future = _sessionFuture;
    _sessionFuture = null;
    if (future == null) return;
    final session = await future;
    await session.close();
  }

  @override
  Future<List<DetectedTextRegion>> detect(
    Uint8List pageImage, {
    required int width,
    required int height,
  }) async {
    final session = await _ensureSession();
    final input = preprocess(pageImage, width: width, height: height);

    OrtValue? inputTensor;
    Map<String, OrtValue>? outputs;
    try {
      inputTensor = await OrtValue.fromList(input.tensor, [
        1,
        3,
        inputSize,
        inputSize,
      ]);
      // 'images' matches the ONNX graph's own `input_names=['images']`
      // (confirmed via the reference repo's `utils/export.py`), not a name
      // this class invented.
      outputs = await session.run({'images': inputTensor});
      final blk = outputs['blk'];
      if (blk == null) {
        throw StateError(
          "ComicTextDetector: model output has no 'blk' tensor (got "
          '${outputs.keys.join(', ')}); expected output_names '
          "['blk','seg','det'] per docs/research/r6-manga-text-detection.md "
          '§2.3.',
        );
      }
      final flat = (await blk.asFlattenedList())
          .map((e) => (e as num).toDouble())
          .toList(growable: false);
      return postprocessBlkOutput(
        flat,
        blk.shape,
        originalWidth: width,
        originalHeight: height,
        unpaddedWidth: input.unpaddedWidth,
        unpaddedHeight: input.unpaddedHeight,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
      );
    } finally {
      await inputTensor?.dispose();
      if (outputs != null) {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    }
  }

  /// Letterboxes+normalizes [pageImage] into the model's expected input
  /// tensor. Pure/static and `@visibleForTesting` so the letterbox math and
  /// pixel-format handling can be verified directly against known pixel
  /// values, without a real ONNX session -- see this class's doc comment for
  /// the exact algorithm this implements and why (top-left-anchored padding
  /// in particular).
  @visibleForTesting
  static ({Float32List tensor, int unpaddedWidth, int unpaddedHeight})
  preprocess(Uint8List pageImage, {required int width, required int height}) {
    final src = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pageImage.buffer,
      bytesOffset: pageImage.offsetInBytes,
      order: img.ChannelOrder.bgra,
      numChannels: 4,
    );

    // r = min(inputSize/h, inputSize/w): scale so the *longer* source
    // dimension exactly reaches inputSize, matching
    // `imgproc_utils.letterbox`'s `scaleup=True` default (upscales small
    // pages, not just downscales large ones).
    final ratio = math.min(inputSize / height, inputSize / width);
    final unpaddedWidth = (width * ratio).round();
    final unpaddedHeight = (height * ratio).round();

    final resized = img.copyResize(
      src,
      width: unpaddedWidth,
      height: unpaddedHeight,
      interpolation: img.Interpolation.linear,
    );

    // Black canvas, resized image pasted at (0,0) -- top-left anchored, any
    // remaining space along the bottom/right stays black padding. See class
    // doc comment for why this is *not* centered despite that being the more
    // common YOLOv5-letterbox convention.
    final canvas = img.Image(
      width: inputSize,
      height: inputSize,
      numChannels: 3,
    );
    canvas.clear(img.ColorUint8.rgb(0, 0, 0));
    img.compositeImage(
      canvas,
      resized,
      dstX: 0,
      dstY: 0,
      blend: img.BlendMode.direct,
    );

    // NCHW, channel-planar (all R, then all G, then all B), normalized to
    // [0,1] -- matches `cv2.dnn.blobFromImage(..., scalefactor=1/255.0, ...)`
    // with no mean/std subtraction (see class doc comment).
    final planeSize = inputSize * inputSize;
    final tensor = Float32List(3 * planeSize);
    var i = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = canvas.getPixel(x, y);
        tensor[i] = pixel.r / 255.0;
        tensor[planeSize + i] = pixel.g / 255.0;
        tensor[2 * planeSize + i] = pixel.b / 255.0;
        i++;
      }
    }

    return (
      tensor: tensor,
      unpaddedWidth: unpaddedWidth,
      unpaddedHeight: unpaddedHeight,
    );
  }

  /// Decodes a raw `blk` YOLO output tensor into final, page-space
  /// [DetectedTextRegion]s: confidence filter, xywh->xyxy, NMS, then
  /// un-letterbox back to `originalWidth`x`originalHeight` pixel space using
  /// [unpaddedWidth]/[unpaddedHeight] (the pre-padding resized dimensions
  /// [preprocess] computed -- since padding was only ever added to the
  /// bottom/right, un-letterboxing needs only a scale factor, never an
  /// offset subtraction; see class doc comment).
  ///
  /// Pure/static and `@visibleForTesting` so NMS/threshold/coordinate-mapping
  /// logic is directly testable against hand-constructed synthetic tensors,
  /// without a real model. [flatBlk] is the tensor's data flattened in
  /// row-major order; [blkShape] is its shape, expected `[1, numAnchors,
  /// 5+numClasses]` (batch dimension is otherwise unused: this class only
  /// ever runs single-image inference, so it is always 1).
  @visibleForTesting
  static List<DetectedTextRegion> postprocessBlkOutput(
    List<double> flatBlk,
    List<int> blkShape, {
    required int originalWidth,
    required int originalHeight,
    required int unpaddedWidth,
    required int unpaddedHeight,
    double confidenceThreshold = defaultConfidenceThreshold,
    double iouThreshold = defaultIouThreshold,
  }) {
    if (blkShape.length != 3) {
      throw ArgumentError(
        'ComicTextDetector: expected blk output rank 3 '
        '[batch, numAnchors, 5+numClasses], got shape $blkShape',
      );
    }
    final numAnchors = blkShape[1];
    final rowLength = blkShape[2];
    if (rowLength < 6) {
      throw ArgumentError(
        'ComicTextDetector: blk output row length $rowLength leaves no room '
        'for at least one class score ([cx,cy,w,h,obj,cls0,...]); shape '
        '$blkShape',
      );
    }

    final candidates = <_Candidate>[];
    for (var i = 0; i < numAnchors; i++) {
      final base = i * rowLength;
      final objConf = flatBlk[base + 4];
      if (objConf <= 0) continue;
      // Combined confidence = objectness x best class score, mirroring
      // `non_max_suppression`'s `x[:, 5:] *= x[:, 4:5]; conf, j =
      // x[:, 5:].max(1)` -- a box can have high "is this text" mass but low
      // confidence in every specific class, so objectness alone isn't
      // enough.
      var bestClassConf = 0.0;
      for (var c = 5; c < rowLength; c++) {
        final v = flatBlk[base + c];
        if (v > bestClassConf) bestClassConf = v;
      }
      final confidence = objConf * bestClassConf;
      if (confidence <= confidenceThreshold) continue;

      final cx = flatBlk[base];
      final cy = flatBlk[base + 1];
      final w = flatBlk[base + 2];
      final h = flatBlk[base + 3];
      candidates.add(
        _Candidate(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, confidence),
      );
    }

    final kept = _nms(candidates, iouThreshold);

    final scaleX = originalWidth / unpaddedWidth;
    final scaleY = originalHeight / unpaddedHeight;
    final regions = <DetectedTextRegion>[];
    for (final box in kept) {
      final x1 = (box.x1 * scaleX).clamp(0.0, originalWidth.toDouble());
      final y1 = (box.y1 * scaleY).clamp(0.0, originalHeight.toDouble());
      final x2 = (box.x2 * scaleX).clamp(0.0, originalWidth.toDouble());
      final y2 = (box.y2 * scaleY).clamp(0.0, originalHeight.toDouble());
      final w = x2 - x1;
      final h = y2 - y1;
      // A box entirely inside the padding region maps to zero/negative
      // extent once clamped to page bounds -- drop it rather than emit a
      // degenerate region.
      if (w <= 0 || h <= 0) continue;
      regions.add(DetectedTextRegion(x: x1, y: y1, width: w, height: h));
    }
    return regions;
  }
}

/// A YOLO candidate box in xyxy pixel coordinates within the model's
/// 1024x1024 letterboxed input frame, pre-un-letterboxing.
class _Candidate {
  const _Candidate(this.x1, this.y1, this.x2, this.y2, this.confidence);

  final double x1, y1, x2, y2;
  final double confidence;
}

/// Greedy NMS: sort by descending confidence, keep a box only if it doesn't
/// overlap (IoU > [iouThreshold]) any higher-confidence box already kept.
/// Class-agnostic -- see class doc comment for why that's the right
/// simplification here.
List<_Candidate> _nms(List<_Candidate> candidates, double iouThreshold) {
  final sorted = [...candidates]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <_Candidate>[];
  for (final candidate in sorted) {
    final suppressed = kept.any((k) => _iou(candidate, k) > iouThreshold);
    if (!suppressed) kept.add(candidate);
  }
  return kept;
}

double _iou(_Candidate a, _Candidate b) {
  final x1 = math.max(a.x1, b.x1);
  final y1 = math.max(a.y1, b.y1);
  final x2 = math.min(a.x2, b.x2);
  final y2 = math.min(a.y2, b.y2);
  final interW = x2 - x1;
  final interH = y2 - y1;
  if (interW <= 0 || interH <= 0) return 0.0;
  final interArea = interW * interH;
  final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
  final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
  final union = areaA + areaB - interArea;
  return union <= 0 ? 0.0 : interArea / union;
}
