import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Check if we have permission to access location
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Get the current position with high accuracy
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if the user is within the allowed radius of the office location
  bool isWithinOfficeRadius(Position currentPosition, 
      double officeLatitude, double officeLongitude, double allowedRadius) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      officeLatitude,
      officeLongitude,
    );
    
    return distance <= allowedRadius;
  }
}