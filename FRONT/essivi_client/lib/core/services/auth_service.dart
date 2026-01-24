import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Android Emulator
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// LOGIN → récupère uniquement le token
  Future<bool> login({
    required String identifiant,
    required String motDePasse,
  }) async {
    try {
      debugPrint(
        '🔐 [AuthService] Tentative de connexion avec email: $identifiant',
      );
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': identifiant, 'password': motDePasse}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          debugPrint(
            '✅ [AuthService] Token sauvegardé avec succès (${token.length} chars)',
          );
          return true;
        } else {
          debugPrint('❌ [AuthService] Pas de token reçu du backend');
        }
      } else {
        debugPrint(
          '❌ [AuthService] Erreur login - Status: ${response.statusCode}',
        );
      }
      return false;
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur login: $e');
      return false;
    }
  }

  /// GET /auth/me → récupère le rôle
  Future<bool> fetchAndSaveUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        if (role != null) {
          await prefs.setString('role', role);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur /auth/me: $e');
      return false;
    }
  }

  /// Utils
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    debugPrint(
      '🔑 [AuthService.getToken()] Token trouvé: ${token != null ? 'OUI (${token.length} chars)' : 'NON'}',
    );
    return token;
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    debugPrint('👤 [AuthService.getRole()] Rôle trouvé: $role');
    return role;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> registerClient({
    required String nom,
    required String email,
    required String password,
    required String nomPointVente,
    String? responsable,
    String? telephone,
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/create-client'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'email': email,
          'password': password,
          'nom_point_vente': nomPointVente,
          'responsable': responsable,
          'telephone': telephone,
          'adresse': adresse,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming the API returns user info including name
        // Adjust based on your actual API response structure
        return data['nom'] ?? data['name'] ?? 'Utilisateur';
      }
      return 'Utilisateur';
    } catch (e) {
      print('Erreur récupération nom utilisateur: $e');
      return 'Utilisateur';
    }
  }
}
