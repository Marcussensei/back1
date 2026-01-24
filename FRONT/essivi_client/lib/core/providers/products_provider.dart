import 'package:flutter/foundation.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

/// Provider pour la gestion des produits
class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  List<Product> get products =>
      _filteredProducts.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedCategory == 'Tous'
      ? _products
      : _filteredProducts;
  List<String> get categories => ['Tous', ..._categories];
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasProducts => _products.isNotEmpty;

  /// Charger tous les produits
  Future<void> loadProducts({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (!forceRefresh && _products.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final productsData = await ClientApiService.getProducts();
      _products = productsData.map((json) => Product.fromJson(json)).toList();

      // Extraire les catégories uniques
      _categories = _products
          .where((p) => p.categorie != null)
          .map((p) => p.categorie!)
          .toSet()
          .toList();

      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rechercher des produits
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filtrer par catégorie
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Appliquer les filtres
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Filtre par catégorie
      final categoryMatch =
          _selectedCategory == 'Tous' || product.categorie == _selectedCategory;

      // Filtre par recherche
      final searchMatch =
          _searchQuery.isEmpty ||
          product.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      return categoryMatch && searchMatch;
    }).toList();
  }

  /// Obtenir un produit par ID
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les produits en stock
  List<Product> get inStockProducts {
    return _products.where((p) => p.isInStock).toList();
  }

  /// Obtenir les produits populaires (simulation)
  List<Product> get popularProducts {
    return _products.take(6).toList();
  }

  /// Rafraîchir les produits
  Future<void> refresh() async {
    await loadProducts(forceRefresh: true);
  }

  /// Effacer les filtres
  void clearFilters() {
    _selectedCategory = 'Tous';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
