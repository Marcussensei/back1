enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get display {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.shipped:
        return 'Expédiée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.createdAt,
    this.deliveredAt,
    this.trackingNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      status: _parseOrderStatus(json['status']),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      deliveryAddress: json['delivery_address'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      trackingNumber: json['tracking_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.value,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'tracking_number': trackingNumber,
    };
  }

  static OrderStatus _parseOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String image;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'image': image,
    };
  }

  double get subtotal => quantity * price;
}
