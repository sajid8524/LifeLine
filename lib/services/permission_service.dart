import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class NearbyPermissionResult {
  const NearbyPermissionResult({
    required this.canTryNearby,
    required this.deniedPermissions,
    required this.locationServiceEnabled,
  });

  final bool canTryNearby;
  final List<String> deniedPermissions;
  final bool locationServiceEnabled;
}

class PermissionService {
  static Future<NearbyPermissionResult> requestNearbyPermissions() async {
    if (!Platform.isAndroid) {
      return const NearbyPermissionResult(
        canTryNearby: false,
        deniedPermissions: ['Android device required'],
        locationServiceEnabled: false,
      );
    }

    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();
    final denied = <String>[];

    for (final entry in statuses.entries) {
      if (entry.value.isDenied || entry.value.isPermanentlyDenied || entry.value.isRestricted) {
        denied.add(_labelFor(entry.key));
      }
    }

    final locationServiceEnabled = await Permission.location.serviceStatus.isEnabled;

    return NearbyPermissionResult(
      // Some permissions are OS-version-specific; let Nearby try and surface exact failures.
      canTryNearby: true,
      deniedPermissions: denied,
      locationServiceEnabled: locationServiceEnabled,
    );
  }

  static String _labelFor(Permission permission) {
    if (permission == Permission.bluetooth) {
      return 'BLUETOOTH';
    }
    if (permission == Permission.bluetoothScan) {
      return 'BLUETOOTH_SCAN';
    }
    if (permission == Permission.bluetoothConnect) {
      return 'BLUETOOTH_CONNECT';
    }
    if (permission == Permission.bluetoothAdvertise) {
      return 'BLUETOOTH_ADVERTISE';
    }
    if (permission == Permission.location) {
      return 'ACCESS_FINE_LOCATION';
    }
    if (permission == Permission.nearbyWifiDevices) {
      return 'NEARBY_WIFI_DEVICES';
    }
    return permission.toString();
  }
}
