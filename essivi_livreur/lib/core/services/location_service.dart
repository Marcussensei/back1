import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<bool> requestLocationPermission() async {
    try {
      // Sur web, simuler l'accord de permission
      if (kIsWeb) {
        print(
            '[LocationService] Running on web, simulating location permission');
        return true;
      }

      final status = await Geolocator.requestPermission().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[LocationService] Location permission request timed out');
          return LocationPermission.denied;
        },
      );
      return status == LocationPermission.always ||
          status == LocationPermission.whileInUse;
    } catch (e) {
      print('[LocationService] Error requesting permission: $e');
      return true; // Continuer même si erreur
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkPermission();
      if (!hasPermission) {
        return null;
      }

      // Sur web, retourner une position par défaut pour les tests
      if (kIsWeb) {
        print('[LocationService] Running on web, returning simulated position');
        return Position(
          latitude: 6.1256,
          longitude: 1.2557,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print(
              '[LocationService] getCurrentPosition timed out, returning simulated position');
          return Position(
            latitude: 6.1256,
            longitude: 1.2557,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        },
      );
    } catch (e) {
      print('[LocationService] Erreur de géolocalisation: $e');
      // Sur web, retourner une position par défaut
      if (kIsWeb) {
        print('[LocationService] Returning fallback position for web');
        return Position(
          latitude: 6.1256,
          longitude: 1.2557,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    }
  }

  Future<bool> _checkPermission() async {
    try {
      // Sur web, considérer la permission comme accordée
      if (kIsWeb) {
        return true;
      }

      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        return await requestLocationPermission();
      }
      return status == LocationPermission.always ||
          status == LocationPermission.whileInUse;
    } catch (e) {
      print('[LocationService] Error checking permission: $e');
      return true; // Continuer même si erreur
    }
  }

  /// Calcule la distance entre deux points GPS en mètres
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Vérifie si le livreur est à moins de X mètres du client
  bool isWithinDistance(
    double agentLat,
    double agentLon,
    double clientLat,
    double clientLon,
    double distanceInMeters,
  ) {
    final distance =
        calculateDistance(agentLat, agentLon, clientLat, clientLon);
    return distance <= distanceInMeters;
  }

  /// Lance un stream continu de position
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // met à jour tous les 10m
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }
}
