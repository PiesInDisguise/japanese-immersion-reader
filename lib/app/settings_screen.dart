import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services.dart';

/// Spec §14's real settings surface so far: the BYO Anthropic API key and
/// grammar-explanation (spec §8 layer 3) toggle, plus spec §9's TTS/
/// pitch-accent-audio toggles. Reachable from [HomeScreen]'s app bar.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _initialized = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
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
}
