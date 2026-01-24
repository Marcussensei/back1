/// Modèle utilisateur
class User {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String role;
  final DateTime? dateCreation;
  final bool actif;

  User({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
    required this.role,
    this.dateCreation,
    this.actif = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['user_id'] ?? 0,
      nom: json['nom'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? json['phone'],
      adresse: json['adresse'] ?? json['address'],
      role: json['role'] ?? 'client',
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'])
          : json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      actif: json['actif'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'role': role,
      'date_creation': dateCreation?.toIso8601String(),
      'actif': actif,
    };
  }

  User copyWith({
    int? id,
    String? nom,
    String? email,
    String? telephone,
    String? adresse,
    String? role,
    DateTime? dateCreation,
    bool? actif,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      role: role ?? this.role,
      dateCreation: dateCreation ?? this.dateCreation,
      actif: actif ?? this.actif,
    );
  }

  bool get isClient => role == 'client';
  bool get isAgent => role == 'agent';
  bool get isAdmin => role == 'admin';
}
