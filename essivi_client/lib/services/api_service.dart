import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service pour les appels API client
class ClientApiService {
  // Utiliser l'URL de production déployée
  static String get baseUrl => 'https://essivivi-project.onrender.com';
  static String? _authToken;

  /// Définir le token
  static void setToken(String token) {
    _authToken = token;
  }

  /// Obtenir le token
  static String? getToken() => _authToken;

  /// Headers communs
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      // Le backend ESSIVI attend juste le token sans "Bearer"
      headers['Authorization'] = _authToken!;
    }

    return headers;
  }

  // ==================== AUTH ====================

  /// Login client
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          setToken(data['access_token']);
        }
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      } else {
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Erreur de connexion réseau');
    } catch (e) {
      throw Exception('Erreur de login: $e');
    }
  }

  /// Register client
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
              'address': address,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          setToken(data['access_token']);
        }
        return data;
      } else {
        throw Exception('Erreur inscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur register: $e');
    }
  }

  /// Vérifier authentification
  static Future<Map<String, dynamic>> checkAuth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/auth/me'), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Non authentifié');
      }
    } catch (e) {
      throw Exception('Erreur auth check: $e');
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/auth/logout'), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      _authToken = null;
    } catch (e) {
      _authToken = null;
    }
  }

  // ==================== PRODUCTS ====================

  /// Obtenir tous les produits
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/produits/'; // Ajout du slash final
      final params = <String, String>{};

      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;

      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders(includeAuth: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Adapter la réponse API
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data['produits'] is List) {
          return List<Map<String, dynamic>>.from(data['produits']);
        }
        return [];
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getProducts: $e');
    }
  }

  /// Obtenir les catégories
  static Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: _getHeaders(includeAuth: false),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categories'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ==================== ORDERS ====================

  /// Obtenir les commandes de l'utilisateur (seulement les siennes)
  static Future<Map<String, dynamic>> getOrders({
    String? statut,
    String? dateDebut,
    String? dateFin,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String url = '$baseUrl/clients/my-orders';
      final params = <String, String>{};

      if (statut != null) params['statut'] = statut;
      if (dateDebut != null) params['date_debut'] = dateDebut;
      if (dateFin != null) params['date_fin'] = dateFin;
      params['page'] = page.toString();
      params['per_page'] = perPage.toString();

      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getOrders: $e');
    }
  }

  /// Créer une commande
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    String? deliveryDate,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/commandes/'),
            headers: _getHeaders(),
            body: jsonEncode({
              'items': items,
              'delivery_address': deliveryAddress,
              'date_livraison_prevue': deliveryDate,
              'notes': notes,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur création commande: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur createOrder: $e');
    }
  }

  /// Obtenir une commande spécifique
  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/commandes/$orderId'), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getOrder: $e');
    }
  }

  /// Annuler une commande
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/commandes/$orderId/cancel'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur cancelOrder: $e');
    }
  }

  // ==================== USER PROFILE ====================

  /// Obtenir le profil utilisateur
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/auth/me'), headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getUserProfile: $e');
    }
  }

  /// Mettre à jour le profil utilisateur
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;

      final response = await http
          .put(
            Uri.parse('$baseUrl/clients/me'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur updateUserProfile: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Vérifier si erreur d'authentification
  static bool isAuthError(dynamic error) {
    return error.toString().contains('401') ||
        error.toString().contains('Session expirée') ||
        error.toString().contains('Non authentifié');
  }
}
