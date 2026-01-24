class Delivery {
  final int id;
  final int agentId;
  final int clientId;
  final String clientName;
  final String clientPhone;
  final String clientAddress;
  final double latitude;
  final double longitude;
  final int quantity;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? photo;
  final String? signature;

  Delivery({
    required this.id,
    required this.agentId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientAddress,
    required this.latitude,
    required this.longitude,
    required this.quantity,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.photo,
    this.signature,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? 0,
      agentId: json['agent_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      clientName: json['nom_point_vente'] ?? json['responsable'] ?? '',
      clientPhone: json['client_telephone'] ?? '',
      clientAddress: json['adresse_livraison'] ?? '',
      latitude: (json['latitude_gps'] ?? 0.0).toDouble(),
      longitude: (json['longitude_gps'] ?? 0.0).toDouble(),
      quantity: json['quantite'] ?? 0,
      amount: (json['montant_percu'] ?? 0.0).toDouble(),
      status: json['statut'] ?? 'en_attente',
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      photo: json['photo_lieu'],
      signature: json['signature_client'],
    );
  }
}

class DeliveryStats {
  final int totalDeliveries;
  final int completedDeliveries;
  final double totalAmount;
  final double totalQuantity;
  final String averageDistance;

  DeliveryStats({
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.totalAmount,
    required this.totalQuantity,
    required this.averageDistance,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      totalDeliveries: json['total_deliveries'] ?? 0,
      completedDeliveries: json['completed_deliveries'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      totalQuantity: (json['total_quantity'] ?? 0.0).toDouble(),
      averageDistance: json['average_distance'] ?? '0 km',
    );
  }
}

class Agent {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? photo;
  final String tricycle;
  final double? currentLatitude;
  final double? currentLongitude;
  final String status;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photo,
    required this.tricycle,
    this.currentLatitude,
    this.currentLongitude,
    required this.status,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      tricycle: json['tricycle'] ?? '',
      currentLatitude: json['current_latitude']?.toDouble(),
      currentLongitude: json['current_longitude']?.toDouble(),
      status: json['status'] ?? 'actif',
    );
  }
}
