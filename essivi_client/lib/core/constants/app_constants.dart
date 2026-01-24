class AppConstants {
  static const String appName = 'ESSIVI Client';
  static const String baseUrl = 'http://10.0.2.2:5000'; // Pour Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // Pour iOS simulator

  // Routes API
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/create-client';
  static const String ordersEndpoint = '/orders';
  static const String profileEndpoint = '/me';

  // Messages
  static const String loginSuccess = 'Connexion réussie';
  static const String loginError = 'Erreur de connexion';
  static const String orderSuccess = 'Commande créée avec succès';
  static const String orderError = 'Erreur lors de la création de la commande';

  // Validation
  static const int minPasswordLength = 6;
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
}
