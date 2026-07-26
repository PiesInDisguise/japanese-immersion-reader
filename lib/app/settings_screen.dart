import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_importer.dart';

import 'app_theme.dart';
import 'services.dart';
import 'settings_repository.dart';

/// Spec §14's real settings surface so far: the BYO Anthropic API key and
/// grammar-explanation (spec §8 layer 3) toggle, spec §9's TTS/
/// pitch-accent-audio toggles, the mined-word highlight color, spec §6's
/// auto-add-to-collection toggle, and spec §10's dictionary import/installed
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
                'Appearance',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Applies everywhere in the app, including cards.'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Font size'),
                  Expanded(
                    child: Slider(
                      value: settings.fontScale,
                      min: 0.8,
                      max: 2.0,
                      divisions: 24,
                      label: '${(settings.fontScale * 100).round()}%',
                      onChanged: (value) => ref
                          .read(settingsRepositoryProvider)
                          .update(fontScale: value),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${(settings.fontScale * 100).round()}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use custom theme colors'),
                subtitle: const Text(
                  'Off uses the app\'s normal look; on lets you set your '
                  'own background, text, card, and accent colors together.',
                ),
                value: settings.useCustomTheme,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(useCustomTheme: value),
              ),
              const SizedBox(height: 8),
              const Text('Palette presets'),
              const SizedBox(height: 8),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: themePresets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = themePresets[index];
                    return _ThemePresetSwatch(
                      preset: preset,
                      onTap: () => ref
                          .read(settingsRepositoryProvider)
                          .update(
                            useCustomTheme: true,
                            themeBackgroundColor: preset.background,
                            themeTextColor: preset.text,
                            themeCardColor: preset.card,
                            themeAccentColor: preset.accent,
                          ),
                    );
                  },
                ),
              ),
              if (settings.useCustomTheme) ...[
                _ColorSettingTile(
                  label: 'Background',
                  color: settings.themeBackgroundColor,
                  onPick: (color) => ref
                      .read(settingsRepositoryProvider)
                      .update(themeBackgroundColor: color),
                ),
                _ColorSettingTile(
                  label: 'Text',
                  color: settings.themeTextColor,
                  onPick: (color) => ref
                      .read(settingsRepositoryProvider)
                      .update(themeTextColor: color),
                ),
                _ColorSettingTile(
                  label: 'Card',
                  color: settings.themeCardColor,
                  onPick: (color) => ref
                      .read(settingsRepositoryProvider)
                      .update(themeCardColor: color),
                ),
                _ColorSettingTile(
                  label: 'Accent',
                  color: settings.themeAccentColor,
                  onPick: (color) => ref
                      .read(settingsRepositoryProvider)
                      .update(themeAccentColor: color),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ref
                        .read(settingsRepositoryProvider)
                        .update(
                          themeBackgroundColor: defaultThemeBackgroundColor,
                          themeTextColor: defaultThemeTextColor,
                          themeCardColor: defaultThemeCardColor,
                          themeAccentColor: defaultThemeAccentColor,
                        ),
                    child: const Text('Reset colors to defaults'),
                  ),
                ),
              ],
              const Divider(height: 32),
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
                'Mining (spec §6)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-add to collection'),
                subtitle: const Text(
                  'Tapping a word mines it immediately -- no need to press '
                  '"Add to Collection" in the lookup popup.',
                ),
                value: settings.autoAddToCollection,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(autoAddToCollection: value),
              ),
              const Divider(height: 32),
              const Text(
                'Review (spec §12)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show sentence on front'),
                subtitle: const Text(
                  "Word review cards show the original sentence they were "
                  "mined from, with the word highlighted, instead of just "
                  "the bare word.",
                ),
                value: settings.reviewShowSentenceOnFront,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(reviewShowSentenceOnFront: value),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review swipe gestures',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text(
                'The on-screen rating buttons always work regardless of '
                'these -- swiping is an optional shortcut.',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Swipe up (Easy)'),
                value: settings.reviewSwipeUpEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(reviewSwipeUpEnabled: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Swipe down (Again)'),
                value: settings.reviewSwipeDownEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(reviewSwipeDownEnabled: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Swipe left (Hard)'),
                value: settings.reviewSwipeLeftEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(reviewSwipeLeftEnabled: value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Swipe right (Good)'),
                value: settings.reviewSwipeRightEnabled,
                onChanged: (value) => ref
                    .read(settingsRepositoryProvider)
                    .update(reviewSwipeRightEnabled: value),
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
    await ref.read(settingsRepositoryProvider).update(llmApiKey: value.trim());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved.')));
    }
  }

  /// The word-highlighting feature's color picker.
  Future<void> _pickHighlightColor(Color current) async {
    final picked = await _pickColorDialog(context, 'Highlight color', current);
    if (picked == null) return;
    await ref.read(settingsRepositoryProvider).update(highlightColor: picked);
  }
}

/// Shared by [_SettingsScreenState._pickHighlightColor] and
/// [_ColorSettingTile] (the four custom-theme color slots): a local
/// `pickerColor` tracks live `onColorChanged` edits inside the dialog (an
/// HSV picker has no natural "confirm" gesture of its own -- dragging the
/// wheel fires continuously), and only the dialog's own "Save" button
/// returns that value. Cancelling (or dismissing) returns `null`, leaving
/// whatever setting the caller would have updated untouched. A top-level
/// function (not a method on either widget's state) since both just need a
/// [BuildContext], not any other state.
Future<Color?> _pickColorDialog(
  BuildContext context,
  String title,
  Color current,
) {
  var pickerColor = current;
  return showDialog<Color>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
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
}

/// One row of the custom-theme color picker (Background/Text/Card/Accent):
/// a swatch + label + "Change..." button, mirroring the word-highlight
/// color row's own layout exactly.
class _ColorSettingTile extends StatelessWidget {
  const _ColorSettingTile({
    required this.label,
    required this.color,
    required this.onPick,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
      ),
      title: Text(label),
      trailing: OutlinedButton(
        onPressed: () async {
          final picked = await _pickColorDialog(context, '$label color', color);
          if (picked != null) onPick(picked);
        },
        child: const Text('Change...'),
      ),
    );
  }
}

/// One tappable palette-preset card: a 2x2 swatch of the preset's four
/// colors (background/text/card/accent, same order as [_ColorSettingTile]'s
/// own rows) plus its name -- tapping it applies all four via [onTap]
/// rather than requiring the four individual color pickers.
class _ThemePresetSwatch extends StatelessWidget {
  const _ThemePresetSwatch({required this.preset, required this.onTap});

  final ThemePreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: ColoredBox(color: preset.background)),
                        Expanded(child: ColoredBox(color: preset.text)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: ColoredBox(color: preset.card)),
                        Expanded(child: ColoredBox(color: preset.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preset.name,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
