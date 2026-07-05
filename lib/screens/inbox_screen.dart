import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../widgets/emergency_card.dart';
import 'message_detail_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  static const routeName = '/inbox';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Inbox')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(label: 'All', value: 'ALL', selected: app.inboxFilter == 'ALL', onSelected: controller.setFilter),
                  _FilterChip(
                    label: 'Pending',
                    value: AppConstants.statusPending,
                    selected: app.inboxFilter == AppConstants.statusPending,
                    onSelected: controller.setFilter,
                  ),
                  _FilterChip(
                    label: 'Delivered',
                    value: AppConstants.statusDelivered,
                    selected: app.inboxFilter == AppConstants.statusDelivered,
                    onSelected: controller.setFilter,
                  ),
                  _FilterChip(
                    label: 'Synced',
                    value: AppConstants.statusSynced,
                    selected: app.inboxFilter == AppConstants.statusSynced,
                    onSelected: controller.setFilter,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (app.filteredEmergencies.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('No emergency messages stored yet.')),
                )
              else
                ...app.filteredEmergencies.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EmergencyCard(
                      message: message,
                      onTap: () => Navigator.of(context).pushNamed(MessageDetailScreen.routeName, arguments: message),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final void Function(String value) onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
    );
  }
}
