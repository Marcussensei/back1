import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _baseUrl = 'https://essivivi-project.onrender.com';
  Timer? _locationTimer;
  bool _isTracking = false;
  Function(double latitude, double longitude)? _onPositionUpdate;

  /// Vérifie et demande les permissions de localisation
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      _debugPrint('❌ Erreur lors de la demande de permission: $e');
      return false;
    }
  }

  /// Récupère la position actuelle du client
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();

      if (!hasPermission) {
        _debugPrint('⚠️ Permission de localisation refusée');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _debugPrint(
        '✅ Position actuelle: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      _debugPrint('❌ Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  /// Met à jour la position du client sur le serveur
  Future<bool> updateClientLocation(
    int orderId,
    double latitude,
    double longitude,
  ) async {
    try {
      final token = ClientApiService.getToken();

      if (token == null) {
        _debugPrint('⚠️ Token non disponible');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/commandes/update-client-position'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({
          'commande_id': orderId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        _debugPrint('✅ Position mise à jour avec succès');
        return true;
      } else {
        _debugPrint('❌ Erreur lors de la mise à jour: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _debugPrint('❌ Exception lors de la mise à jour de la position: $e');
      return false;
    }
  }

  /// Démarre le suivi de position (mise à jour toutes les 30 secondes)
  void startLocationTracking(
    int orderId, {
    Function(double latitude, double longitude)? onPositionUpdate,
  }) {
    if (_isTracking) {
      _debugPrint('⚠️ Le suivi de position est déjà actif');
      return;
    }

    _onPositionUpdate = onPositionUpdate;
    _isTracking = true;
    _debugPrint('🚀 Démarrage du suivi de position du client...');

    // Mise à jour immédiate
    _updateAndSendLocation(orderId);

    // Mise à jour toutes les 30 secondes
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateAndSendLocation(orderId),
    );
  }

  /// Arrête le suivi de position
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _isTracking = false;
    _debugPrint('⏸️ Suivi de position arrêté');
  }

  /// Récupère et envoie la position
  Future<void> _updateAndSendLocation(int orderId) async {
    try {
      final position = await getCurrentLocation();

      if (position != null) {
        await updateClientLocation(
          orderId,
          position.latitude,
          position.longitude,
        );

        // Notify callback about position update
        _onPositionUpdate?.call(position.latitude, position.longitude);
      }
    } catch (e) {
      _debugPrint('❌ Erreur lors de la mise à jour de la position: $e');
    }
  }

  /// Vérifie si le suivi est actif
  bool get isTracking => _isTracking;

  /// Dispose du service
  void dispose() {
    stopLocationTracking();
  }

  /// Fonction de débogage
  void _debugPrint(String message) {
    if (kDebugMode) {
      print('📍 LocationService: $message');
    }
  }
}
