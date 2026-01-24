import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Provider pour la gestion du panier
class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get deliveryFee =>
      subtotal > 0 ? 1000.0 : 0.0; // Frais de livraison fixe
  double get total => subtotal + deliveryFee;

  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)} FCFA';
  String get formattedDeliveryFee => '${deliveryFee.toStringAsFixed(0)} FCFA';
  String get formattedTotal => '${total.toStringAsFixed(0)} FCFA';

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Initialiser le panier (charger depuis le cache)
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');

      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items = decoded.map((item) {
          final product = Product.fromJson(item['product']);
          return CartItem(product: product, quantity: item['quantity'] ?? 1);
        }).toList();
      }
    } catch (e) {
      debugPrint('Erreur de chargement du panier: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarder le panier
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items
          .map(
            (item) => {
              'product': item.product.toJson(),
              'quantity': item.quantity,
            },
          )
          .toList();
      await prefs.setString('cart_items', jsonEncode(cartData));
    } catch (e) {
      debugPrint('Erreur de sauvegarde du panier: $e');
    }
  }

  /// Ajouter un produit au panier
  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Le produit existe déjà, augmenter la quantité
      _items[existingIndex].quantity += quantity;
    } else {
      // Nouveau produit
      _items.add(CartItem(product: product, quantity: quantity));
    }

    _saveCart();
    notifyListeners();
  }

  /// Retirer un produit du panier
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  /// Mettre à jour la quantité d'un produit
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  /// Augmenter la quantité
  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  /// Diminuer la quantité
  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        _saveCart();
        notifyListeners();
      } else {
        removeItem(productId);
      }
    }
  }

  /// Vider le panier
  Future<void> clear() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    notifyListeners();
  }

  /// Vérifier si un produit est dans le panier
  bool containsProduct(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  /// Obtenir la quantité d'un produit dans le panier
  int getProductQuantity(int productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        product: Product(id: 0, nom: '', prixUnitaire: 0),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  /// Obtenir les items pour la commande (format API)
  List<Map<String, dynamic>> getOrderItems() {
    return _items.map((item) => item.toJson()).toList();
  }
}
