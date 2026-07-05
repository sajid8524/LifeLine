import 'package:geolocator/geolocator.dart';

class GpsLocation {
  const GpsLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class GpsService {
  Future<GpsLocation?> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GpsLocation(latitude: position.latitude, longitude: position.longitude);
  }
}
