class Tour {
  final String id;
  final String agentId;
  final DateTime startTime;
  DateTime? endTime;
  final List<Delivery> deliveries;
  final double totalDistance;
  final double totalAmount;
  final TourStatus status;

  Tour({
    required this.id,
    required this.agentId,
    required this.startTime,
    this.endTime,
    required this.deliveries,
    this.totalDistance = 0,
    this.totalAmount = 0,
    this.status = TourStatus.inProgress,
  });

  int get deliveryCount => deliveries.length;

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  // Copier le modèle avec modifications
  Tour copyWith({
    String? id,
    String? agentId,
    DateTime? startTime,
    DateTime? endTime,
    List<Delivery>? deliveries,
    double? totalDistance,
    double? totalAmount,
    TourStatus? status,
  }) {
    return Tour(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deliveries: deliveries ?? this.deliveries,
      totalDistance: totalDistance ?? this.totalDistance,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'deliveries': deliveries.map((d) => d.toJson()).toList(),
      'total_distance': totalDistance,
      'total_amount': totalAmount,
      'status': status.name,
    };
  }

  // Créer depuis JSON
  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'],
      agentId: json['agent_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      deliveries: (json['deliveries'] as List)
          .map((d) => Delivery.fromJson(d))
          .toList(),
      totalDistance: (json['total_distance'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: TourStatus.values.byName(json['status'] ?? 'inProgress'),
    );
  }
}

class Delivery {
  final String id;
  final String tourId;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String address;
  final double latitude;
  final double longitude;
  final Map<String, int> quantities; // Produit -> quantité
  final double amount;
  final DateTime? completedAt;
  final String? signature; // Base64
  final String? photo; // Base64
  final DeliveryStatus status;
  final String? notes;
  final double distanceMeters; // Distance du client GPS

  Delivery({
    required this.id,
    required this.tourId,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.quantities,
    required this.amount,
    this.completedAt,
    this.signature,
    this.photo,
    this.status = DeliveryStatus.pending,
    this.notes,
    this.distanceMeters = 0,
  });

  bool get isAtLocation => distanceMeters <= 2; // 2 mètres

  Delivery copyWith({
    String? id,
    String? tourId,
    String? clientId,
    String? clientName,
    String? clientPhone,
    String? address,
    double? latitude,
    double? longitude,
    Map<String, int>? quantities,
    double? amount,
    DateTime? completedAt,
    String? signature,
    String? photo,
    DeliveryStatus? status,
    String? notes,
    double? distanceMeters,
  }) {
    return Delivery(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      quantities: quantities ?? this.quantities,
      amount: amount ?? this.amount,
      completedAt: completedAt ?? this.completedAt,
      signature: signature ?? this.signature,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tour_id': tourId,
      'client_id': clientId,
      'client_name': clientName,
      'client_phone': clientPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'quantities': quantities,
      'amount': amount,
      'completed_at': completedAt?.toIso8601String(),
      'signature': signature,
      'photo': photo,
      'status': status.name,
      'notes': notes,
      'distance_meters': distanceMeters,
    };
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'],
      tourId: json['tour_id'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      quantities: Map<String, int>.from(json['quantities'] ?? {}),
      amount: (json['amount'] as num).toDouble(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      signature: json['signature'],
      photo: json['photo'],
      status: DeliveryStatus.values.byName(json['status'] ?? 'pending'),
      notes: json['notes'],
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum TourStatus { pending, inProgress, completed, cancelled }

enum DeliveryStatus { pending, inProgress, completed, failed, cancelled }
