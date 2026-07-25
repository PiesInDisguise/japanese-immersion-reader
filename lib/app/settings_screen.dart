import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_importer.dart';

import 'services.dart';

/// Spec §14's real settings surface so far: the BYO Anthropic API key and
/// grammar-explanation (spec §8 layer 3) toggle, spec §9's TTS/
/// pitch-accent-audio toggles, and spec §10's dictionary import/installed
/// list. Reachable from [HomeScreen]'s app bar.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _initialized = false;

  bool _importingDictionary = false;
  double _importProgress = 0;
  late Future<List<Dictionary>> _installedDictionariesFuture;

  @override
  void initState() {
    super.initState();
    _refreshInstalledDictionaries();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _refreshInstalledDictionaries() {
    _installedDictionariesFuture = ref
        .read(dictionaryRepositoryProvider)
        .listInstalled();
  }

  /// Spec §10: "Import both Yomitan/Yomichan ZIP format and raw JMdict."
  /// Only the Yomitan ZIP path is wired here -- `DictionaryImporter` (see
  /// its own doc comment) only understands that format; raw JMdict
  /// XML/JSON would need a separate converter this pass doesn't build.
  /// JMdict itself is commonly redistributed pre-converted to Yomitan
  /// format (e.g. via Yomitan's own dictionary list), which is what this
  /// button expects.
  Future<void> _importDictionary() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() {
      _importingDictionary = true;
      _importProgress = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DictionaryImporter(ref.read(appDatabaseProvider)).import(
        File(path),
        onProgress: (progress) {
          if (mounted) setState(() => _importProgress = progress.fraction);
        },
      );
      if (!mounted) return;
      setState(() {
        _importingDictionary = false;
        _refreshInstalledDictionaries();
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Dictionary imported.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importingDictionary = false);
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (settings) {
          // Only seed the text field from the stored value once -- every
          // later rebuild comes from this same screen's own edits via
          // SettingsRepository.update, and overwriting the controller's
          // text on each of those would fight the user's cursor position.
          if (!_initialized) {
            _apiKeyController.text = settings.llmApiKey ?? '';
            _initialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Grammar explanations (spec §8, layer 3)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bring your own Anthropic API key to get a short '
                'grammar explanation for the sentence you\'re reading. '
                'Your key is stored locally on this device only, and is '
                'sent directly to Anthropic\'s API -- never through any '
                'server this app runs.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'Anthropic API key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                ),
                onSubmitted: (value) => _saveApiKey(value),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _saveApiKey(_apiKeyController.text),
                  child: const Text('Save key'),
                ),
              ),
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable grammar explanations'),
                subtitle: const Text(
                  'Has no effect without an API key configured above.',
                ),
                value: settings.llmExplanationsEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(llmExplanationsEnabled: value),
              ),
              const Divider(height: 32),
              const Text(
                'Audio (spec §9)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Both are optional and off by default. Pitch-accent audio '
                'downloads a real recording for each word the first time '
                'it\'s played, then reuses that local copy afterward.',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Text-to-speech'),
                subtitle: const Text(
                  'On-device speech for words and sentences.',
                ),
                value: settings.ttsEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(ttsEnabled: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pitch-accent audio'),
                subtitle: const Text(
                  'Downloadable real pronunciation recordings.',
                ),
                value: settings.pitchAccentAudioEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(pitchAccentAudioEnabled: value),
              ),
              const Divider(height: 32),
              const Text(
                'Highlighting',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mined words are highlighted everywhere they appear, in '
                'every book.',
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: settings.highlightColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                ),
                title: const Text('Highlight color'),
                trailing: OutlinedButton(
                  onPressed: () => _pickHighlightColor(settings.highlightColor),
                  child: const Text('Change...'),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Dictionaries (spec §10)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Dictionary>>(
                future: _installedDictionariesFuture,
                builder: (context, snapshot) {
                  final dictionaries = snapshot.data ?? const [];
                  if (dictionaries.isEmpty) {
                    return const Text('No dictionaries installed yet.');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final dictionary in dictionaries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(dictionary.title),
                          subtitle: Text(
                            'Priority ${dictionary.priority}'
                            '${dictionary.enabled ? '' : ' (disabled)'}',
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              if (_importingDictionary) ...[
                LinearProgressIndicator(
                  value: _importProgress > 0 ? _importProgress : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Importing dictionary... a large one like JMdict can '
                  'take a minute.',
                ),
              ] else
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Import Dictionary (.zip)...'),
                  onPressed: _importDictionary,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveApiKey(String value) async {
    await ref
        .read(settingsRepositoryProvider)
        .update(llmApiKey: value.trim());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved.')));
    }
  }

  /// The word-highlighting feature's color picker: a local `pickerColor`
  /// tracks live `onColorChanged` edits inside the dialog (an HSV picker has
  /// no natural "confirm" gesture of its own -- dragging the wheel fires
  /// continuously), and only the dialog's own "Save" button commits that
  /// value via `SettingsRepository.update`. Cancelling leaves the stored
  /// color untouched.
  Future<void> _pickHighlightColor(Color current) async {
    var pickerColor = current;
    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Highlight color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(pickerColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(settingsRepositoryProvider).update(highlightColor: picked);
  }
}
