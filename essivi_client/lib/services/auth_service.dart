import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service d'authentification client
class ClientAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _userKey = 'auth_user';
  static const String _clientIdKey = 'client_id';

  /// Vérifier si authentifié
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await ClientApiService.login(
        email: email,
        password: password,
      );

      // Sauvegarder token, email et client_id
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result['access_token'] ?? '');
      await prefs.setString(_emailKey, email);

      // Sauvegarder le client_id s'il est fourni
      if (result['client_id'] != null) {
        await prefs.setInt(_clientIdKey, result['client_id'] as int);
        print(
          '✅ [ClientAuthService] client_id sauvegardé: ${result['client_id']}',
        );
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final result = await ClientApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );

      // Sauvegarder token, email et client_id
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, result['access_token'] ?? '');
      await prefs.setString(_emailKey, email);

      // Sauvegarder le client_id s'il est fourni
      if (result['client_id'] != null) {
        await prefs.setInt(_clientIdKey, result['client_id'] as int);
        print(
          '✅ [ClientAuthService] client_id sauvegardé lors du register: ${result['client_id']}',
        );
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await ClientApiService.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_userKey);
      await prefs.remove(_clientIdKey);
    }
  }

  /// Restaurer session
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        ClientApiService.setToken(token);

        try {
          await ClientApiService.checkAuth();
          return true;
        } catch (e) {
          await logout();
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir l'email courant
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Obtenir le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
