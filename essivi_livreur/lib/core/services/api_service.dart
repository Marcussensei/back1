import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Callback pour gérer les erreurs 401 (token expiré)
typedef OnTokenExpired = void Function();

/// Service pour gérer les appels API
class ApiService {
  // Utiliser l'URL de production déployée
  static String get baseUrl => 'https://essivivi-project.onrender.com';
  static String? _authToken;
  static OnTokenExpired? _onTokenExpired;

  /// Définir le callback pour le token expiré
  static void setOnTokenExpired(OnTokenExpired? callback) {
    _onTokenExpired = callback;
  }

  /// Définir le token d'authentification
  static void setToken(String token) {
    _authToken = token;
  }

  /// Obtenir le token
  static String? getToken() => _authToken;

  /// Obtenir le token de façon synchrone (pour le logging)
  static String? getTokenSync() => _authToken;

  /// Gérer les réponses 401
  static void _handle401() {
    print('[ApiService] Token expiré détecté, appel du callback...');
    _authToken = null;
    _onTokenExpired?.call();
  }

  /// Obtenir les headers communs
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

  /// Login avec email et mot de passe
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
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

  /// Vérifier l'authentification
  static Future<Map<String, dynamic>> checkAuth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: _getHeaders(),
          )
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

  /// Obtenir les données de l'agent connecté
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('[ApiService] getMe() response status: ${response.statusCode}');
      print('[ApiService] getMe() response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ApiService] getMe() decoded data: $data');
        return data;
      } else if (response.statusCode == 401) {
        // Token expiré - on signale et on lance une exception
        _handle401();
        throw Exception('Token expiré - veuillez vous reconnecter');
      } else {
        throw Exception(
            'Erreur getMe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ApiService] getMe() exception: $e');
      rethrow; // Propager l'exception plutôt que de la wrapper
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      _authToken = null;
    } catch (e) {
      _authToken = null;
    }
  }

  // ==================== TOURS ====================

  /// Obtenir tous les tours
  static Future<List<Map<String, dynamic>>> getTours() async {
    try {
      print('[getTours] 🚚 Début');
      print('[getTours] Token défini: ${_authToken != null}');
      print('[getTours] Token: ${_authToken?.substring(0, 50) ?? "NULL"}...');

      if (_authToken == null || _authToken!.isEmpty) {
        print('[getTours] ❌ Token NULL ou vide!');
        throw Exception('Non authentifié - token manquant');
      }

      final headers = _getHeaders();
      print('[getTours] Headers: $headers');

      print('[getTours] URL: $baseUrl/tours');
      final uri = Uri.parse('$baseUrl/tours');
      print('[getTours] URI parsée: $uri');

      print('[getTours] Envoi requête...');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('[getTours] ⏱️ TIMEOUT après 5 secondes');
        throw Exception('Timeout getTours - API ne répond pas');
      });

      print('[getTours] ✅ Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tours = List<Map<String, dynamic>>.from(data['tours'] ?? []);
        print('[getTours] ✅ ${tours.length} tournées reçues');
        return tours;
      } else if (response.statusCode == 401) {
        print('[getTours] 🔑 Authentification échouée (401)');
        _handle401();
        throw Exception('Session expirée');
      } else {
        print('[getTours] ❌ Erreur HTTP ${response.statusCode}');
        print('[getTours] Body: ${response.body}');
        throw Exception('Erreur: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      print('[getTours] 🌐 Erreur réseau: $e');
      throw Exception('Erreur de connexion réseau: $e');
    } catch (e) {
      print('[getTours] ❌ Erreur: $e');
      throw Exception('Erreur getTours: $e');
    }
  }

  /// Obtenir les livraisons d'une tournée spécifique
  static Future<List<Map<String, dynamic>>> getTourDeliveries(
      String date) async {
    try {
      print('[getTourDeliveries] 🚚 Début pour date: $date');

      final uri = Uri.parse('$baseUrl/tours/deliveries')
          .replace(queryParameters: {'date': date});
      print('[getTourDeliveries] URL: $uri');

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(const Duration(seconds: 10));

      print(
          '[getTourDeliveries] ✅ Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deliveries =
            List<Map<String, dynamic>>.from(data['deliveries'] ?? []);
        print('[getTourDeliveries] ✅ ${deliveries.length} livraisons reçues');
        return deliveries;
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        print('[getTourDeliveries] ❌ Erreur HTTP ${response.statusCode}');
        print('[getTourDeliveries] Body: ${response.body}');
        throw Exception('Erreur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[getTourDeliveries] ❌ Erreur: $e');
      throw Exception('Erreur getTourDeliveries: $e');
    }
  }

  /// Créer un nouveau tour
  static Future<Map<String, dynamic>> createTour({
    required double latitude,
    required double longitude,
    required String district,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tours'),
            headers: _getHeaders(),
            body: jsonEncode({
              'start_location': {
                'lat': latitude,
                'lng': longitude,
              },
              'district': district,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur création tour: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur createTour: $e');
    }
  }

  /// Obtenir un tour spécifique
  static Future<Map<String, dynamic>> getTour(String tourId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tours/$tourId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getTour: $e');
    }
  }

  /// Mettre à jour le statut d'un tour
  static Future<Map<String, dynamic>> updateTourStatus({
    required String tourId,
    required String status,
    double? endLatitude,
    double? endLongitude,
  }) async {
    try {
      final body = {'status': status};
      if (endLatitude != null && endLongitude != null) {
        // end_location not set - optional
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/tours/$tourId'),
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
      throw Exception('Erreur updateTourStatus: $e');
    }
  }

  // ==================== DELIVERIES ====================

  /// Ajouter une livraison à un tour
  static Future<Map<String, dynamic>> addDelivery({
    required String tourId,
    required String clientName,
    required String address,
    required double latitude,
    required double longitude,
    required int amount,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tours/$tourId/deliveries'),
            headers: _getHeaders(),
            body: jsonEncode({
              'client_name': clientName,
              'address': address,
              'location': {
                'lat': latitude,
                'lng': longitude,
              },
              'amount': amount,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur ajout livraison: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur addDelivery: $e');
    }
  }

  /// Mettre à jour le statut d'une livraison
  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required String tourId,
    required String deliveryId,
    required String status,
    String? signature,
    String? proofPhoto,
  }) async {
    try {
      final body = {'statut': status};
      if (signature != null) body['signature_client'] = signature;
      if (proofPhoto != null) body['photo_lieu'] = proofPhoto;

      final response = await http
          .put(
            Uri.parse('$baseUrl/livraisons/$deliveryId'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur updateDeliveryStatus: $e');
    }
  }

  // ==================== AGENTS ====================

  /// Obtenir le profil de l'agent
  static Future<Map<String, dynamic>> getAgentProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/agents/me'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getAgentProfile: $e');
    }
  }

  /// Mettre à jour la localisation de l'agent
  static Future<Map<String, dynamic>> updateAgentLocation({
    required double latitude,
    required double longitude,
    int? agentId,
  }) async {
    try {
      // Si agentId n'est pas fourni, récupérer les données de l'agent connecté
      int finalAgentId = agentId ?? 0;
      if (finalAgentId == 0) {
        try {
          final agentData = await getMe();
          finalAgentId = agentData['agent_id'] ?? agentData['id'] ?? 0;
        } catch (e) {
          print('Erreur: impossible de récupérer agent_id: $e');
          throw Exception('Agent ID requis');
        }
      }

      final url = '$baseUrl/agents/$finalAgentId/location';
      print('[ApiService] Updating agent location: PUT $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: _getHeaders(),
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('[ApiService] Location update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[ApiService] Erreur updateAgentLocation: $e');
      throw Exception('Erreur updateAgentLocation: $e');
    }
  }

  // ==================== LIVRAISONS ====================

  /// Obtenir l'ID agent par email (depuis la table agents)
  static Future<int> getAgentIdByEmail(String email) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/agents/?per_page=200'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final agents = List.from(data['agents'] ?? []);
        final agent = agents.firstWhere(
          (a) => a['email'] == email,
          orElse: () => null,
        );
        if (agent == null) {
          throw Exception('Agent non trouvé pour email: $email');
        }
        return agent['id'] as int;
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getAgentIdByEmail: $e');
    }
  }

  /// Obtenir les livraisons d'un agent
  static Future<List<dynamic>> getLivraisonsByAgent(int agentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/livraisons/?agent_id=$agentId&per_page=200'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List.from(data['livraisons'] ?? []);
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getLivraisonsByAgent: $e');
    }
  }

  /// Mettre à jour une livraison
  static Future<Map<String, dynamic>> updateLivraison(
    int livraisonId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/livraisons/$livraisonId'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        return {
          'success': false,
          'error': 'Erreur: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: $e',
      };
    }
  }

  // ==================== STATISTICS ====================

  /// Obtenir les statistiques de l'agent
  static Future<Map<String, dynamic>> getStatistics({
    String? period = 'month',
  }) async {
    try {
      print(
          '[getStatistics] 📊 AVANT getHeaders - token: ${_authToken != null}');
      final headers = _getHeaders();
      print('[getStatistics] Après getHeaders - headers: $headers');
      final response = await http
          .get(
            Uri.parse('$baseUrl/agents/stats?period=$period'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
      print('[getStatistics] Réponse status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getStatistics: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Obtenir les notifications de l'utilisateur
  static Future<List<dynamic>> getUserNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (unreadOnly) queryParams['unread_only'] = 'true';
      queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrl/user-notifications')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List.from(data['notifications'] ?? []);
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur getUserNotifications: $e');
    }
  }

  /// Marquer une notification comme lue
  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user-notifications/$notificationId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur markNotificationAsRead: $e');
    }
  }

  /// Marquer toutes les notifications comme lues
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/user-notifications/mark-all-read'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur markAllNotificationsAsRead: $e');
    }
  }

  /// Supprimer une notification
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/user-notifications/$notificationId'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _handle401();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur deleteNotification: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Vérifier si l'erreur est due à une authentification
  static bool isAuthError(dynamic error) {
    return error.toString().contains('401') ||
        error.toString().contains('Session expirée') ||
        error.toString().contains('Non authentifié');
  }
}
