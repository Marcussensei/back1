import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/custom_button.dart';
import 'create_order_page.dart';

class OrderCreationPage extends StatelessWidget {
  const OrderCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commander'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: !authProvider.isAuthenticated
          ? EmptyState(
              icon: Icons.login,
              title: 'Non connecté',
              message: 'Veuillez vous connecter pour créer une commande',
              actionText: 'Aller au profil',
              onAction: () {
                // Navigation vers le profil pour se connecter
              },
            )
          : cartProvider.items.isEmpty
          ? _buildEmptyCartUI(context, authProvider)
          : _buildCreateOrderUI(context, cartProvider, authProvider),
    );
  }

  Widget _buildEmptyCartUI(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des produits avant de commander',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DashboardProvider>().goHome();
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Continuer les achats'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOrderUI(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vous avez ${cartProvider.itemCount} article(s)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Montant total: ${cartProvider.formattedTotal}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Articles dans votre panier:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...cartProvider.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.nom} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    item.formattedSubtotal,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Finaliser la commande',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateOrderPage()),
              );
            },
            width: double.infinity,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              context.read<DashboardProvider>().goHome();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continuer les achats'),
          ),
        ],
      ),
    );
  }
}
