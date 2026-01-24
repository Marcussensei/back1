import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration centralisée de l'API
class ApiConfig {
  // URL de base de l'API
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    // Pour Android Emulator, utiliser 10.0.2.2
    // Pour iOS Simulator et devices réels, utiliser l'IP locale
    return 'http://localhost:5000';
  }

  // Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';

  static const String products = '/produits';
  static String productDetail(int id) => '/produits/$id';
  static String productStock(int id) => '/produits/stocks/$id';

  static const String orders = '/commandes';
  static String orderDetail(int id) => '/commandes/$id';
  static const String orderStats = '/commandes/statistiques/resume';

  static const String deliveries = '/livraisons';
  static String deliveryDetail(int id) => '/livraisons/$id';
  static const String deliveryStatsDay = '/livraisons/statistiques/jour';

  static const String clients = '/clients';
  static String clientDetail(int id) => '/clients/$id';
  static const String clientMe = '/clients/me';

  static const String agents = '/agents';
  static String agentDetail(int id) => '/agents/$id';
  static const String agentMe = '/agents/me';

  static const String statistics = '/statistiques/dashboard/kpi';
  static const String statisticsPerformance =
      '/statistiques/performance/agents';
  static const String statisticsRevenue =
      '/statistiques/chiffre-affaires/evolution';

  static const String cartography = '/cartographie/agents/temps-reel';
  static String cartographyAgent(int id) =>
      '/cartographie/agents/$id/localiser';
  static const String cartographyClients = '/cartographie/clients/geo';
  static const String cartographyProximity = '/cartographie/proximite';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheExpiration = Duration(minutes: 5);

  // Retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
