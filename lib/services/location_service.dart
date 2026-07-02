import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Flag to simulate user location at PPKD Jakarta Pusat for testing/debugging
  static const bool useMockLocation = false;

  // Default PPKD office location coordinates (PPKD Jakarta Pusat)
  static const double targetLatitude = -6.210758136346654;
  static const double targetLongitude = 106.81291020885662;

  // Maximum allowed radius in meters
  static const double allowedRadiusMeters = 200.0;

  // Check if location services are enabled and request permission
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current user position with robust timeouts and low-accuracy fallbacks
  Future<Position> getCurrentLocation() async {
    if (useMockLocation) {
      // Mock user location at PPKD Jakarta Pusat
      return Position(
        latitude: targetLatitude,
        longitude: targetLongitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      // Fallback 1: Try to get last known position
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }

      // Fallback 2: Try to request position with lower accuracy
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    }
  }

  // Calculate distance between user location and target in meters
  double calculateDistance(double userLat, double userLng) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLatitude,
      targetLongitude,
    );
  }

  // Check if user is within the allowed geofence radius
  bool isWithinRadius(double userLat, double userLng) {
    final distance = calculateDistance(userLat, userLng);
    return distance <= allowedRadiusMeters;
  }

  // Convert latitude and longitude to physical street address
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    if (useMockLocation && lat == targetLatitude && lng == targetLongitude) {
      return "Jl. Karet Pasar Baru Barat V No. 23, Karet Tengsin, Tanah Abang, Jakarta Pusat";
    }
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}";
      }
    } catch (e) {
      return "Unknown Address ($lat, $lng)";
    }
    return "Unknown Address";
  }
}
