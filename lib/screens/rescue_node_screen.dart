import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import 'sync_status_screen.dart';

class RescueNodeScreen extends ConsumerWidget {
  const RescueNodeScreen({super.key});

  static const routeName = '/rescue-node';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rescue Node')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(Icons.health_and_safety_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('I AM A RESCUE NODE', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('When this phone gets internet, it uploads stored emergency messages to Firebase Firestore.'),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable rescue node mode'),
              subtitle: Text(app.isRescueNode ? 'Auto sync is listening for network return.' : 'Offline relay only.'),
              value: app.isRescueNode,
              onChanged: controller.toggleRescueNode,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: controller.syncNow,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('SYNC NOW'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(SyncStatusScreen.routeName),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('SYNC STATUS'),
            ),
            const SizedBox(height: 16),
            Text(app.syncStatus),
          ],
        ),
      ),
    );
  }
}
