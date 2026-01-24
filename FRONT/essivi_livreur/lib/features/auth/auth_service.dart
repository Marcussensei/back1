import 'dart:convert';
import 'dart:developer' as developer;
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

          // Fetch and save user role after successful login
          await fetchAndSaveUserRole();

          developer.log(
            'Login successful for user: $identifiant',
            name: 'AuthService',
          );
          return true;
        }
      }

      developer.log(
        'Login failed - Invalid credentials or server error',
        name: 'AuthService',
        error: 'Status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      developer.log(
        'Login error occurred',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }

  /// GET /auth/me → récupère le rôle et les informations utilisateur
  Future<bool> fetchAndSaveUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        developer.log(
          'No token found for user role fetch',
          name: 'AuthService',
        );
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        final userId = data['id'];
        final userName = data['nom'] ?? data['name'];

        if (role != null) {
          await prefs.setString('role', role);
          if (userId != null) {
            await prefs.setString('user_id', userId.toString());
          }
          if (userName != null) {
            await prefs.setString('user_name', userName);
          }

          developer.log(
            'User role fetched successfully: $role',
            name: 'AuthService',
          );
          return true;
        }
      }

      developer.log(
        'Failed to fetch user role',
        name: 'AuthService',
        error: 'Status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      developer.log(
        'Error fetching user role',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }

  /// Récupère le token stocké
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      developer.log(
        'Error getting token',
        name: 'AuthService',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Récupère le rôle de l'utilisateur
  Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      developer.log(
        'Error getting user role',
        name: 'AuthService',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Récupère l'ID de l'utilisateur
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      developer.log(
        'Error getting user ID',
        name: 'AuthService',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Récupère le nom de l'utilisateur
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedName = prefs.getString('user_name');

      // Si pas de nom stocké, essayer de le récupérer via l'API
      if (storedName == null) {
        final token = await getToken();
        if (token != null) {
          try {
            final response = await http.get(
              Uri.parse('$baseUrl/auth/me'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final userName = data['nom'] ?? data['name'] ?? 'Livreur';
              await prefs.setString('user_name', userName);
              return userName;
            }
          } catch (e) {
            developer.log(
              'Error fetching user name from API',
              name: 'AuthService',
              error: e.toString(),
            );
          }
        }
        return 'Livreur'; // Valeur par défaut
      }

      return storedName;
    } catch (e) {
      developer.log(
        'Error getting user name',
        name: 'AuthService',
        error: e.toString(),
      );
      return 'Livreur';
    }
  }

  /// Vérifie si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking login status',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }

  /// Vérifie si l'utilisateur est un livreur
  Future<bool> isDeliveryAgent() async {
    try {
      final role = await getRole();
      return role == 'livreur' || role == 'delivery_agent' || role == 'agent';
    } catch (e) {
      developer.log(
        'Error checking delivery agent status',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }

  /// Déconnexion - efface toutes les données stockées
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('User logged out successfully', name: 'AuthService');
    } catch (e) {
      developer.log(
        'Error during logout',
        name: 'AuthService',
        error: e.toString(),
      );
    }
  }

  /// Rafraîchit les informations utilisateur
  Future<bool> refreshUserInfo() async {
    try {
      return await fetchAndSaveUserRole();
    } catch (e) {
      developer.log(
        'Error refreshing user info',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }

  /// Vérifie la validité du token
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final isValid = response.statusCode == 200;
      if (!isValid) {
        developer.log(
          'Token validation failed',
          name: 'AuthService',
          error: 'Status: ${response.statusCode}',
        );
        // Si le token n'est pas valide, déconnecter l'utilisateur
        await logout();
      }

      return isValid;
    } catch (e) {
      developer.log(
        'Error validating token',
        name: 'AuthService',
        error: e.toString(),
      );
      return false;
    }
  }
}
