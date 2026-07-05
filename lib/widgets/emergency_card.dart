import 'package:flutter/material.dart';

import '../core/utils/emergency_formatters.dart';
import '../models/emergency_message.dart';
import 'priority_pill.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({
    required this.message,
    required this.onTap,
    super.key,
  });

  final EmergencyMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      readableEmergencyType(message.type),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  PriorityPill(priority: message.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.description.isEmpty ? 'No description provided' : message.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Meta(icon: Icons.people_alt_outlined, label: '${message.victims} victim(s)'),
                  _Meta(icon: Icons.schedule_outlined, label: shortTime(message.timestamp)),
                  _Meta(icon: Icons.route_outlined, label: 'TTL ${message.ttl}'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(message.status, style: Theme.of(context).textTheme.labelSmall),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
