import 'package:shared_preferences/shared_preferences.dart';

/// Script pour nettoyer les données locales
/// Utilisez ceci si vous avez des problèmes d'authentification
Future<void> clearLocalData() async {
  final prefs = await SharedPreferences.getInstance();

  // Supprimer le token d'authentification
  await prefs.remove('auth_token');

  // Supprimer les données du panier
  await prefs.remove('cart_items');

  print('✅ Données locales nettoyées');
  print('   - Token d\'authentification supprimé');
  print('   - Panier vidé');
  print('\n🔄 Veuillez redémarrer l\'application et vous reconnecter');
}

void main() async {
  await clearLocalData();
}
