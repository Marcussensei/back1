import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service pour gérer l'authentification
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Vérifier si l'utilisateur est authentifié
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Se connecter
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await ApiService.login(email: email, password: password);

      // Sauvegarder le token et les infos utilisateur
      if (result['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, result['access_token'] ?? '');
        await prefs.setString(_userKey, email);

        // Assurer que le token est dans ApiService aussi
        ApiService.setToken(result['access_token']);
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Se déconnecter
  static Future<void> logout() async {
    try {
      await ApiService.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  /// Restaurer la session depuis le stockage local
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        // Restaurer le token dans ApiService
        ApiService.setToken(token);

        // Valider immédiatement que le token fonctionne
        try {
          print('[AuthService] Validation du token restauré...');
          await ApiService.getMe();
          print('[AuthService] ✅ Token restauré et valide');
          return true;
        } catch (e) {
          print('[AuthService] ❌ Token restauré mais invalide: $e');
          // Token invalide, on le supprime
          await logout();
          return false;
        }
      }

      return false;
    } catch (e) {
      print('[AuthService] Erreur restauration session: $e');
      return false;
    }
  }

  /// Obtenir l'email de l'utilisateur actuel
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  /// Obtenir le token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
