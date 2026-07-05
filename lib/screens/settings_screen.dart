import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Device', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(app.deviceName),
            const SizedBox(height: 16),
            Text('Nearby debug', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.startHost,
                  icon: const Icon(Icons.cell_tower_outlined),
                  label: const Text('HOST'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.startDiscover,
                  icon: const Icon(Icons.radar_outlined),
                  label: const Text('DISCOVER'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.sendHelloTransportTest,
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('SEND HELLO TEST'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Firebase setup', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SelectableText(
              '1. Create Firebase project.\n'
              '2. Enable Anonymous Auth, Firestore, and Storage.\n'
              '3. Run: flutterfire configure\n'
              '4. Add google-services.json to android/app.\n'
              '5. Collections used: emergencies, devices, sync_logs.',
            ),
            const SizedBox(height: 20),
            Text('Google Maps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SelectableText(
              'Add your Maps SDK for Android API key in android/app/build.gradle manifestPlaceholders '
              'or directly in AndroidManifest.xml meta-data com.google.android.geo.API_KEY.',
            ),
            const SizedBox(height: 20),
            Text('Gemini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const SelectableText(
              'Build with --dart-define=GEMINI_API_KEY=YOUR_KEY to enable online Gemini classification. '
              'Without a key, the app uses an offline heuristic classifier.',
            ),
          ],
        ),
      ),
    );
  }
}
