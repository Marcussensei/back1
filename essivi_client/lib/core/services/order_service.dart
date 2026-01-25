import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class OrderService {
  // Note: baseUrl est maintenant fourni par ClientApiService pour cohérence
  static String get baseUrl => ClientApiService.baseUrl;

  Future<List<dynamic>> getOrders() async {
    final token = ClientApiService.getToken();
    if (token == null) throw Exception('Non authentifié');

    final response = await http.get(
      Uri.parse('$baseUrl/commandes'),
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des commandes');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required int quantity,
    required String deliveryDate,
    required String notes,
  }) async {
    final token = ClientApiService.getToken();
    if (token == null) throw Exception('Non authentifié');

    final response = await http.post(
      Uri.parse('$baseUrl/commandes'),
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'quantity': quantity,
        'delivery_date': deliveryDate,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la création de la commande');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final token = ClientApiService.getToken();
    if (token == null) throw Exception('Non authentifié');

    final response = await http.get(
      Uri.parse('$baseUrl/commandes/$orderId'),
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Erreur lors de la récupération des détails de la commande',
      );
    }
  }

  Future<Map<String, dynamic>?> getAgentLocation(int orderId) async {
    debugPrint(
      '🔐 [OrderService] Tentative de récupération du token via ClientApiService...',
    );
    final token = ClientApiService.getToken();
    debugPrint(
      '🔑 [OrderService] Token reçu: ${token != null ? 'OUI (${token.length} chars)' : 'NON (null)'}',
    );

    if (token == null) {
      debugPrint('❌ [OrderService] Token null depuis ClientApiService');
      throw Exception('Non authentifié');
    }

    debugPrint('✅ [OrderService] Token disponible, appel API en cours...');
    final response = await http.get(
      Uri.parse('$baseUrl/commandes/$orderId/agent-location'),
      headers: {'Authorization': token, 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Check if agent has valid location data
      if (data['latitude'] != null && data['longitude'] != null) {
        return {
          'id': data['id'],
          'name': data['name'],
          'phone': data['phone'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'lastLocationUpdate': data['lastLocationUpdate'],
          'client_id': data['client_id'],
        };
      }
      return null;
    } else {
      throw Exception(
        'Erreur lors de la récupération de la position de l\'agent',
      );
    }
  }
}
