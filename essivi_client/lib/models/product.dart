/// Modèle produit
class Product {
  final int id;
  final String nom;
  final String? description;
  final double prixUnitaire;
  final String? unite;
  final int? quantiteParUnite;
  final String? imageUrl;
  final String? categorie;
  final bool actif;
  final int? stockDisponible;
  final DateTime? dateCreation;

  Product({
    required this.id,
    required this.nom,
    this.description,
    required this.prixUnitaire,
    this.unite,
    this.quantiteParUnite,
    this.imageUrl,
    this.categorie,
    this.actif = true,
    this.stockDisponible,
    this.dateCreation,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['produit_id'] ?? 0,
      nom: json['nom'] ?? json['name'] ?? '',
      description: json['description'],
      prixUnitaire: (json['prix_unitaire'] ?? json['price'] ?? 0).toDouble(),
      unite: json['unite'] ?? json['unit'],
      quantiteParUnite: json['quantite_par_unite'] ?? json['quantity_per_unit'],
      imageUrl: json['image_url'] ?? json['image'],
      categorie: json['categorie'] ?? json['category'],
      actif: json['actif'] ?? json['active'] ?? true,
      stockDisponible: json['stock_disponible'] ?? json['stock'],
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix_unitaire': prixUnitaire,
      'unite': unite,
      'quantite_par_unite': quantiteParUnite,
      'image_url': imageUrl,
      'categorie': categorie,
      'actif': actif,
      'stock_disponible': stockDisponible,
      'date_creation': dateCreation?.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? nom,
    String? description,
    double? prixUnitaire,
    String? unite,
    int? quantiteParUnite,
    String? imageUrl,
    String? categorie,
    bool? actif,
    int? stockDisponible,
    DateTime? dateCreation,
  }) {
    return Product(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      unite: unite ?? this.unite,
      quantiteParUnite: quantiteParUnite ?? this.quantiteParUnite,
      imageUrl: imageUrl ?? this.imageUrl,
      categorie: categorie ?? this.categorie,
      actif: actif ?? this.actif,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  bool get isInStock => stockDisponible != null && stockDisponible! > 0;
  bool get isLowStock => stockDisponible != null && stockDisponible! < 10;

  String get formattedPrice => '${prixUnitaire.toStringAsFixed(0)} FCFA';

  String get displayName {
    if (unite != null && quantiteParUnite != null) {
      return '$nom ($quantiteParUnite $unite)';
    }
    return nom;
  }
}
