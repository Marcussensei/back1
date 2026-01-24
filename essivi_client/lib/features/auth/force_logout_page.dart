import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import 'login_page.dart';

/// Page pour forcer la déconnexion et nettoyer toutes les données
class ForceLogoutPage extends StatelessWidget {
  const ForceLogoutPage({super.key});

  Future<void> _forceLogout(BuildContext context) async {
    try {
      // 1. Déconnexion via AuthProvider
      await context.read<AuthProvider>().logout();

      // 2. Vider le panier
      context.read<CartProvider>().clear();

      // 3. Nettoyer SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;

      // 4. Retour à la page de login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie. Veuillez vous reconnecter.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déconnexion Forcée'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Problème d\'authentification ?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Si vous voyez des erreurs 401 ou si vous ne pouvez pas commander, '
                'utilisez cette option pour nettoyer complètement vos données locales.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _forceLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion Forcée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
