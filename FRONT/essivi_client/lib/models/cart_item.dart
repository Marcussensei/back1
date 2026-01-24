import 'product.dart';

/// Modèle article du panier
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.prixUnitaire * quantity;

  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)} FCFA';

  Map<String, dynamic> toJson() {
    return {
      'produit_id': product.id,
      'quantite': quantity,
      'prix_unitaire': product.prixUnitaire,
    };
  }

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
