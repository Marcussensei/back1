import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

/// Provider pour la gestion de l'authentification
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  /// Initialiser le provider (charger les données sauvegardées)
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token != null) {
        ClientApiService.setToken(_token!);
        // Récupérer le profil utilisateur
        await loadUserProfile();
      }
    } catch (e) {
      _error = 'Erreur d\'initialisation: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connexion
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ClientApiService.login(
        email: email,
        password: password,
      );

      _token = response['access_token'];
      if (_token != null) {
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        ClientApiService.setToken(_token!);

        // Charger le profil utilisateur
        await loadUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Token non reçu';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Inscription
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ClientApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );

      _token = response['access_token'];
      if (_token != null) {
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);

        ClientApiService.setToken(_token!);

        // Charger le profil utilisateur
        await loadUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Token non reçu';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger le profil utilisateur
  Future<void> loadUserProfile() async {
    try {
      final profileData = await ClientApiService.getUserProfile();
      _user = User.fromJson(profileData);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de chargement du profil: $e';

      // Si erreur 401, déconnecter l'utilisateur
      if (ClientApiService.isAuthError(e)) {
        await logout();
      }

      notifyListeners();
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ClientApiService.updateUserProfile(
        name: name,
        phone: phone,
        address: address,
      );

      _user = User.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await ClientApiService.logout();
    } catch (e) {
      // Ignorer les erreurs de déconnexion
    }

    // Supprimer les données locales
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _user = null;
    _token = null;
    _error = null;

    ClientApiService.setToken('');

    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
