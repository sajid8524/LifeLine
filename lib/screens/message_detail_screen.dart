import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_providers.dart';
import '../core/utils/emergency_formatters.dart';
import '../models/emergency_message.dart';
import '../widgets/priority_pill.dart';

class MessageDetailScreen extends ConsumerWidget {
  const MessageDetailScreen({required this.message, super.key});

  static const routeName = '/message-detail';

  final EmergencyMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Details')),
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
            _Detail(label: 'Message ID', value: message.messageId),
            _Detail(label: 'Sender device', value: message.senderDevice),
            _Detail(label: 'Victims', value: '${message.victims}'),
            _Detail(label: 'Description', value: message.description),
            _Detail(label: 'GPS', value: '${message.latitude}, ${message.longitude}'),
            _Detail(label: 'Priority', value: message.priority),
            _Detail(label: 'Timestamp', value: DateTime.parse(message.timestamp).toLocal().toString()),
            _Detail(label: 'Delivery status', value: message.status),
            _Detail(label: 'Relay count', value: '${message.relayCount}'),
            _Detail(label: 'TTL remaining', value: '${message.ttl}'),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: shareText(message), title: 'LifeSaver DTN Emergency'),
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(appControllerProvider).deleteEmergency(message.messageId);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
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
