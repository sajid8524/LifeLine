import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../widgets/stat_tile.dart';
import 'create_sos_screen.dart';
import 'inbox_screen.dart';
import 'map_screen.dart';
import 'rescue_node_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed(SettingsScreen.routeName),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(AppConstants.tagline, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              SelectableText(app.deviceName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(app.connectionStatus),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 560 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.9,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  StatTile(label: 'Nearby devices', value: '${app.connectedDevicesCount}', icon: Icons.bluetooth_connected),
                  StatTile(label: 'Pending SOS', value: '${app.pendingCount}', icon: Icons.warning_amber_outlined),
                  StatTile(label: 'Stored emergencies', value: '${app.emergencies.length}', icon: Icons.storage_outlined),
                  StatTile(label: 'Rescue node', value: app.isRescueNode ? 'ON' : 'OFF', icon: Icons.cloud_upload_outlined),
                ],
              ),
              const SizedBox(height: 16),
              Text('Nearby transport', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: app.isBusy ? null : controller.startHost,
                    icon: const Icon(Icons.cell_tower_outlined),
                    label: const Text('HOST'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: app.isBusy ? null : controller.startDiscover,
                    icon: const Icon(Icons.radar_outlined),
                    label: const Text('DISCOVER'),
                  ),
                  OutlinedButton.icon(
                    onPressed: app.isBusy ? null : controller.forwardStoredMessages,
                    icon: const Icon(Icons.sync_alt_outlined),
                    label: const Text('RELAY STORED'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MainAction(
                icon: Icons.sos_outlined,
                title: 'SEND SOS',
                subtitle: 'Create, store, and relay an emergency packet.',
                color: AppConstants.criticalColor,
                onTap: () => Navigator.of(context).pushNamed(CreateSosScreen.routeName),
              ),
              const SizedBox(height: 10),
              _MainAction(
                icon: Icons.inbox_outlined,
                title: 'INBOX',
                subtitle: 'Review pending, delivered, and synced emergencies.',
                onTap: () => Navigator.of(context).pushNamed(InboxScreen.routeName),
              ),
              const SizedBox(height: 10),
              _MainAction(
                icon: Icons.map_outlined,
                title: 'MAP',
                subtitle: 'View local emergency markers by priority.',
                onTap: () => Navigator.of(context).pushNamed(MapScreen.routeName),
              ),
              const SizedBox(height: 10),
              _MainAction(
                icon: Icons.health_and_safety_outlined,
                title: 'I AM A RESCUE NODE',
                subtitle: 'Upload stored emergencies when internet returns.',
                onTap: () => Navigator.of(context).pushNamed(RescueNodeScreen.routeName),
              ),
              const SizedBox(height: 20),
              Text('Message log', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (app.logs.isEmpty)
                const Text('No transport events yet.')
              else
                ...app.logs.take(6).map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainAction extends StatelessWidget {
  const _MainAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = color ?? scheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
