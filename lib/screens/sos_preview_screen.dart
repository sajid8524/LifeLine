import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../core/utils/emergency_formatters.dart';
import '../models/emergency_message.dart';
import '../widgets/priority_pill.dart';
import 'home_screen.dart';

class SosPreviewScreen extends ConsumerWidget {
  const SosPreviewScreen({required this.message, super.key});

  static const routeName = '/sos-preview';

  final EmergencyMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Preview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    readableEmergencyType(message.type),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                PriorityPill(priority: message.priority),
              ],
            ),
            const SizedBox(height: 16),
            _Detail(label: 'Victim count', value: '${message.victims}'),
            _Detail(label: 'Description', value: message.description),
            _Detail(label: 'Location', value: '${message.latitude}, ${message.longitude}'),
            _Detail(label: 'Medical emergency', value: message.medicalEmergency ? 'Yes' : 'No'),
            _Detail(label: 'Timestamp', value: DateTime.parse(message.timestamp).toLocal().toString()),
            _Detail(label: 'TTL', value: '${message.ttl} hop(s)'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(appControllerProvider).sendEmergency(message);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).popUntil(ModalRoute.withName(HomeScreen.routeName));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS stored and queued for relay.')));
              },
              icon: const Icon(Icons.emergency_share_outlined),
              label: const Text('SEND'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('EDIT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
