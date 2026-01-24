import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';

/// Widget pour afficher un état vide
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: ThemeConfig.primaryColor),
            ),
            const SizedBox(height: ThemeConfig.spacingLarge),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ThemeConfig.spacingSmall),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeConfig.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ThemeConfig.spacingLarge),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConfig.spacingLarge,
                    vertical: ThemeConfig.spacingMedium,
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État vide pour le panier
class EmptyCartState extends StatelessWidget {
  final VoidCallback? onShopNow;

  const EmptyCartState({super.key, this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Panier vide',
      message: 'Votre panier est vide.\nCommencez vos achats maintenant !',
      actionText: 'Voir les produits',
      onAction: onShopNow,
    );
  }
}

/// État vide pour les commandes
class EmptyOrdersState extends StatelessWidget {
  final VoidCallback? onShopNow;

  const EmptyOrdersState({super.key, this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Aucune commande',
      message:
          'Vous n\'avez pas encore passé de commande.\nCommencez vos achats maintenant !',
      actionText: 'Commander maintenant',
      onAction: onShopNow,
    );
  }
}

/// État vide pour les produits
class EmptyProductsState extends StatelessWidget {
  final VoidCallback? onRetry;

  const EmptyProductsState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Aucun produit',
      message: 'Aucun produit disponible pour le moment.',
      actionText: onRetry != null ? 'Réessayer' : null,
      onAction: onRetry,
    );
  }
}

/// État d'erreur
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Erreur',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeConfig.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: ThemeConfig.errorColor,
              ),
            ),
            const SizedBox(height: ThemeConfig.spacingLarge),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ThemeConfig.spacingSmall),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeConfig.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: ThemeConfig.spacingLarge),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConfig.spacingLarge,
                    vertical: ThemeConfig.spacingMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
