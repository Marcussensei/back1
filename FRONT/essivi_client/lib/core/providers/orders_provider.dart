import 'package:flutter/foundation.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';

/// Provider pour la gestion des commandes
class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrders => _orders.isNotEmpty;

  /// Charger toutes les commandes
  Future<void> loadOrders({
    bool forceRefresh = false,
    String? statut,
    String? dateDebut,
    String? dateFin,
    int page = 1,
  }) async {
    if (_isLoading) return;

    if (!forceRefresh && _orders.isNotEmpty && page == 1) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ClientApiService.getOrders(
        statut: statut,
        dateDebut: dateDebut,
        dateFin: dateFin,
        page: page,
      );

      final ordersData = response['commandes'] as List;
      final newOrders = ordersData.map((json) => Order.fromJson(json)).toList();

      if (page == 1) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      // Trier par date (plus récent en premier)
      _orders.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer une nouvelle commande
  Future<bool> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    String? deliveryDate,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ClientApiService.createOrder(
        items: items,
        deliveryAddress: deliveryAddress,
        deliveryDate: deliveryDate,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
      );

      final newOrder = Order.fromJson(response);
      _orders.insert(0, newOrder);
      _currentOrder = newOrder;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les détails d'une commande
  Future<void> loadOrderDetails(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = await ClientApiService.getOrder(orderId);
      _currentOrder = Order.fromJson(orderData);

      // Mettre à jour dans la liste si elle existe
      final index = _orders.indexWhere((o) => o.id.toString() == orderId);
      if (index >= 0) {
        _orders[index] = _currentOrder!;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Annuler une commande
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ClientApiService.cancelOrder(orderId);

      // Mettre à jour le statut localement
      final index = _orders.indexWhere((o) => o.id.toString() == orderId);
      if (index >= 0) {
        _orders[index] = _orders[index].copyWith(statut: 'annulee');
      }

      if (_currentOrder?.id.toString() == orderId) {
        _currentOrder = _currentOrder!.copyWith(statut: 'annulee');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtenir une commande par ID
  Order? getOrderById(int id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les commandes en attente
  List<Order> get pendingOrders {
    return _orders.where((o) => o.isPending).toList();
  }

  /// Obtenir les commandes en cours
  List<Order> get inProgressOrders {
    return _orders.where((o) => o.isInProgress || o.isConfirmed).toList();
  }

  /// Obtenir les commandes livrées
  List<Order> get deliveredOrders {
    return _orders.where((o) => o.isDelivered).toList();
  }

  /// Obtenir les commandes annulées
  List<Order> get cancelledOrders {
    return _orders.where((o) => o.isCancelled).toList();
  }

  /// Rafraîchir les commandes
  Future<void> refresh() async {
    await loadOrders(forceRefresh: true);
  }

  /// Effacer la commande courante
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  /// Effacer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Statistiques
  int get totalOrders => _orders.length;
  double get totalSpent => _orders
      .where((o) => o.isDelivered)
      .fold(0.0, (sum, order) => sum + order.montantTotal);

  String get formattedTotalSpent => '${totalSpent.toStringAsFixed(0)} FCFA';
}
