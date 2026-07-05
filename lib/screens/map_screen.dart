import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/app_providers.dart';
import '../core/utils/emergency_formatters.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  static const routeName = '/map';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final located = app.emergencies.where((message) => message.latitude != 0 || message.longitude != 0).toList();

    if (AppConstants.googleMapsApiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Map')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Icon(Icons.map_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('Google Maps key not configured', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Emergency records are still stored locally. Add a Maps SDK for Android key and rebuild with '
                '--dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY to enable markers.',
              ),
              const SizedBox(height: 18),
              Text('Stored GPS emergencies', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (located.isEmpty)
                const Text('No emergencies with GPS coordinates yet.')
              else
                ...located.map(
                  (message) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.location_on, color: priorityColor(message.priority)),
                    title: Text(readableEmergencyType(message.type)),
                    subtitle: Text('${message.latitude}, ${message.longitude}'),
                    trailing: Text(message.priority),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final first = located.isNotEmpty ? located.first : null;
    final center = LatLng(first?.latitude ?? 20.5937, first?.longitude ?? 78.9629);
    final markers = located.map((message) {
      return Marker(
        markerId: MarkerId(message.messageId),
        position: LatLng(message.latitude, message.longitude),
        infoWindow: InfoWindow(
          title: readableEmergencyType(message.type),
          snippet: '${message.priority} - ${message.victims} victim(s)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(message.priority)),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Map')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: first == null ? 4.5 : 13),
                markers: markers,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  _Legend(color: Color(0xFFD32F2F), label: 'Critical/High'),
                  SizedBox(width: 12),
                  _Legend(color: Color(0xFFF57C00), label: 'Medium'),
                  SizedBox(width: 12),
                  _Legend(color: Color(0xFF388E3C), label: 'Low'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _hueFor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return BitmapDescriptor.hueRed;
      case 'MEDIUM':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
