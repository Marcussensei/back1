import 'product.dart';

/// Modèle commande
class Order {
  final int id;
  final int clientId;
  final String? clientNom;
  final int? agentId;
  final String? agentNom;
  final String? agentTelephone;
  final String statut;
  final DateTime dateCommande;
  final DateTime? dateLivraisonPrevue;
  final DateTime? dateLivraison;
  final String? adresseLivraison;
  final String? notes;
  final double montantTotal;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.clientId,
    this.clientNom,
    this.agentId,
    this.agentNom,
    this.agentTelephone,
    required this.statut,
    required this.dateCommande,
    this.dateLivraisonPrevue,
    this.dateLivraison,
    this.adresseLivraison,
    this.notes,
    required this.montantTotal,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    } else if (json['produits'] != null) {
      orderItems = (json['produits'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'] ?? json['commande_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      clientNom: json['client_nom'] ?? json['client_name'],
      agentId: json['agent_id'],
      agentNom: json['agent_nom'] ?? json['agent_name'],
      agentTelephone: json['agent_telephone'],
      statut: json['statut'] ?? json['status'] ?? 'en_attente',
      dateCommande: json['date_commande'] != null
          ? DateTime.parse(json['date_commande'])
          : DateTime.now(),
      dateLivraisonPrevue: json['date_livraison_prevue'] != null
          ? DateTime.tryParse(json['date_livraison_prevue'])
          : null,
      dateLivraison: json['date_livraison'] != null
          ? DateTime.tryParse(json['date_livraison'])
          : null,
      adresseLivraison: json['adresse_livraison'] ?? json['delivery_address'],
      notes: json['notes'],
      montantTotal: (json['montant_total'] ?? json['total_amount'] ?? 0)
          .toDouble(),
      items: orderItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'agent_id': agentId,
      'statut': statut,
      'date_commande': dateCommande.toIso8601String(),
      'date_livraison_prevue': dateLivraisonPrevue?.toIso8601String(),
      'date_livraison': dateLivraison?.toIso8601String(),
      'adresse_livraison': adresseLivraison,
      'notes': notes,
      'montant_total': montantTotal,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Order copyWith({
    int? id,
    int? clientId,
    String? clientNom,
    int? agentId,
    String? agentNom,
    String? statut,
    DateTime? dateCommande,
    DateTime? dateLivraisonPrevue,
    DateTime? dateLivraison,
    String? adresseLivraison,
    String? notes,
    double? montantTotal,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      agentId: agentId ?? this.agentId,
      agentNom: agentNom ?? this.agentNom,
      statut: statut ?? this.statut,
      dateCommande: dateCommande ?? this.dateCommande,
      dateLivraisonPrevue: dateLivraisonPrevue ?? this.dateLivraisonPrevue,
      dateLivraison: dateLivraison ?? this.dateLivraison,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      notes: notes ?? this.notes,
      montantTotal: montantTotal ?? this.montantTotal,
      items: items ?? this.items,
    );
  }

  // Getters pour les statuts
  bool get isPending => statut == 'en_attente';
  bool get isConfirmed => statut == 'confirmee';
  bool get isInProgress => statut == 'en_cours';
  bool get isDelivered => statut == 'livree';
  bool get isCancelled => statut == 'annulee';

  String get statusLabel {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'en_cours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  String get formattedTotal => '${montantTotal.toStringAsFixed(0)} FCFA';

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantite);
}

/// Modèle article de commande
class OrderItem {
  final int? id;
  final int produitId;
  final String produitNom;
  final int quantite;
  final double prixUnitaire;
  final double montantTotal;
  final Product? produit;

  OrderItem({
    this.id,
    required this.produitId,
    required this.produitNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
    this.produit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      produitId: json['produit_id'] ?? json['product_id'] ?? 0,
      produitNom: json['produit_nom'] ?? json['product_name'] ?? '',
      quantite: json['quantite'] ?? json['quantity'] ?? 0,
      prixUnitaire: (json['prix_unitaire'] ?? json['unit_price'] ?? 0)
          .toDouble(),
      montantTotal:
          (json['montant_total'] ??
                  json['montant_ligne'] ??
                  json['total_amount'] ??
                  0)
              .toDouble(),
      produit: json['produit'] != null
          ? Product.fromJson(json['produit'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit_id': produitId,
      'produit_nom': produitNom,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant_total': montantTotal,
    };
  }

  OrderItem copyWith({
    int? id,
    int? produitId,
    String? produitNom,
    int? quantite,
    double? prixUnitaire,
    double? montantTotal,
    Product? produit,
  }) {
    return OrderItem(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      produitNom: produitNom ?? this.produitNom,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montantTotal: montantTotal ?? this.montantTotal,
      produit: produit ?? this.produit,
    );
  }

  String get formattedPrice => '${prixUnitaire.toStringAsFixed(0)} FCFA';
  String get formattedTotal => '${montantTotal.toStringAsFixed(0)} FCFA';
}
