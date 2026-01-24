import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class GeoLocation {
  final double latitude;
  final double longitude;
  final double accuracy;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double? ?? 0.0,
    );
  }
}

class GeolocationService {
  Future<bool> requestPermission() async {
    try {
      debugPrint('Geolocation permission requested (stub)');
      return true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      debugPrint('Checking geolocation permission (stub)');
      return true;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      debugPrint('Checking location service (stub)');
      return true;
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      debugPrint('Opening location settings (stub)');
      return true;
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  Future<GeoLocation?> getCurrentPosition() async {
    try {
      // Retourne une position par défaut (Lomé, Togo)
      return GeoLocation(
        latitude: 6.1256,
        longitude: 1.2324,
        accuracy: 10.0,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  Stream<GeoLocation> getPositionStream({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    try {
      while (true) {
        final position = await getCurrentPosition();
        if (position != null) {
          yield position;
        }
        await Future.delayed(interval);
      }
    } catch (e) {
      debugPrint('Error in position stream: $e');
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Formule haversine simplifiée
    const R = 6371; // Rayon de la Terre en km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = (1 - _cos(dLat)) / 2 +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * (1 - _cos(dLon)) / 2;
    final c = 2 * _asin(_sqrt(a));
    return R * c;
  }

  double _toRad(double degree) => degree * 3.14159265359 / 180;
  double _cos(double x) {
    const twopi = 2 * 3.14159265359;
    const pi = 3.14159265359;
    x = x.abs();
    if (x > twopi) x -= ((x ~/ twopi) * twopi).toDouble();
    final isNegative = x > pi;
    if (isNegative) x = twopi - x;
    final xx = x * x;
    var result = 1.0;
    result -= (xx * xx * xx) / 5040;
    result += (xx * xx) / 24;
    result -= xx / 2;
    return isNegative ? -result : result;
  }

  double _sqrt(double x) {
    if (x < 0) return 0;
    return math.sqrt(x);
  }

  double _asin(double x) {
    if (x < -1 || x > 1) return 0;
    if (x == 0) return 0;
    final sqrtTerm = _sqrt(1 - x * x);
    return 2 * math.atan(x / (1 + sqrtTerm));
  }
}
