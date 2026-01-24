class Notification {
  final int id;
  final String titre;
  final String message;
  final String typeNotification;
  final bool lue;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.titre,
    required this.message,
    required this.typeNotification,
    required this.lue,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      typeNotification: json['type_notification'] ?? 'info',
      lue: json['lue'] ?? false,
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'message': message,
      'type_notification': typeNotification,
      'lue': lue,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  Notification copyWith({
    int? id,
    String? titre,
    String? message,
    String? typeNotification,
    bool? lue,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      typeNotification: typeNotification ?? this.typeNotification,
      lue: lue ?? this.lue,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
