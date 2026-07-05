import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  static const routeName = '/sync-status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final pending = app.emergencies.where((message) => message.status == 'PENDING').length;
    final delivered = app.emergencies.where((message) => message.status == 'DELIVERED').length;
    final synced = app.emergencies.where((message) => message.status == 'SYNCED').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Row(label: 'Last status', value: app.syncStatus),
            _Row(label: 'Pending', value: '$pending'),
            _Row(label: 'Delivered', value: '$delivered'),
            _Row(label: 'Synced', value: '$synced'),
            _Row(label: 'Firebase collections', value: 'emergencies, devices, sync_logs'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: ref.read(appControllerProvider).syncNow,
              icon: const Icon(Icons.sync_outlined),
              label: const Text('TRY CLOUD SYNC'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
          Flexible(child: SelectableText(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
