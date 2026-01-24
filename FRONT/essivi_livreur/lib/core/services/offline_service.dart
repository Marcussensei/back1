import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tour_model.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  late SharedPreferences _prefs;

  factory OfflineService() {
    return _instance;
  }

  OfflineService._internal();

  /// Initialise le service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============= Tours =============

  /// Sauvegarde une tournée en local
  Future<bool> saveTour(Tour tour) async {
    try {
      final json = jsonEncode(tour.toJson());
      return await _prefs.setString('tour_${tour.id}', json);
    } catch (e) {
      return false;
    }
  }

  /// Récupère une tournée en local
  Tour? getTour(String tourId) {
    try {
      final json = _prefs.getString('tour_$tourId');
      if (json == null) return null;
      return Tour.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Récupère toutes les tournées locales
  List<Tour> getAllTours() {
    try {
      final keys =
          _prefs.getKeys().where((key) => key.startsWith('tour_')).toList();

      return keys
          .map((key) {
            final json = _prefs.getString(key);
            if (json == null) return null;
            return Tour.fromJson(jsonDecode(json));
          })
          .whereType<Tour>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Supprime une tournée locale
  Future<bool> deleteTour(String tourId) async {
    return await _prefs.remove('tour_$tourId');
  }

  // ============= Livraisons =============

  /// Sauvegarde une livraison en local
  Future<bool> saveDelivery(Delivery delivery) async {
    try {
      final json = jsonEncode(delivery.toJson());
      return await _prefs.setString('delivery_${delivery.id}', json);
    } catch (e) {
      return false;
    }
  }

  /// Récupère une livraison en local
  Delivery? getDelivery(String deliveryId) {
    try {
      final json = _prefs.getString('delivery_$deliveryId');
      if (json == null) return null;
      return Delivery.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Récupère les livraisons d'une tournée
  List<Delivery> getDeliveriesForTour(String tourId) {
    try {
      final keys =
          _prefs.getKeys().where((key) => key.startsWith('delivery_')).toList();

      return keys
          .map((key) {
            final json = _prefs.getString(key);
            if (json == null) return null;
            final delivery = Delivery.fromJson(jsonDecode(json));
            return delivery.tourId == tourId ? delivery : null;
          })
          .whereType<Delivery>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Supprime une livraison locale
  Future<bool> deleteDelivery(String deliveryId) async {
    return await _prefs.remove('delivery_$deliveryId');
  }

  // ============= File d'attente de synchronisation =============

  /// Ajoute une action à la file d'attente de sync
  Future<bool> addSyncAction(SyncAction action) async {
    try {
      final list = getSyncQueue();
      list.add(action);
      final json = jsonEncode(list.map((a) => a.toJson()).toList());
      return await _prefs.setString('sync_queue', json);
    } catch (e) {
      return false;
    }
  }

  /// Récupère la file d'attente de sync
  List<SyncAction> getSyncQueue() {
    try {
      final json = _prefs.getString('sync_queue');
      if (json == null) return [];
      final list = (jsonDecode(json) as List)
          .map((item) => SyncAction.fromJson(item))
          .toList();
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Vide la file d'attente de sync
  Future<bool> clearSyncQueue() async {
    return await _prefs.remove('sync_queue');
  }

  /// Supprime une action de la file d'attente
  Future<bool> removeSyncAction(String actionId) async {
    try {
      final list = getSyncQueue();
      list.removeWhere((a) => a.id == actionId);
      final json = jsonEncode(list.map((a) => a.toJson()).toList());
      return await _prefs.setString('sync_queue', json);
    } catch (e) {
      return false;
    }
  }

  // ============= Utilitaires =============

  /// Efface toutes les données locales
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Récupère la taille de stockage utilisée (estimée)
  int getStorageSize() {
    try {
      final keys = _prefs.getKeys();
      int size = 0;
      for (var key in keys) {
        final value = _prefs.get(key);
        size += jsonEncode(value).length;
      }
      return size;
    } catch (e) {
      return 0;
    }
  }
}

class SyncAction {
  final String id;
  final String type; // 'create', 'update', 'delete'
  final String entity; // 'tour', 'delivery'
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool isSynced;

  SyncAction({
    required this.id,
    required this.type,
    required this.entity,
    required this.entityId,
    required this.data,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'entity': entity,
      'entity_id': entityId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'],
      type: json['type'],
      entity: json['entity'],
      entityId: json['entity_id'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['created_at']),
      isSynced: json['is_synced'] ?? false,
    );
  }
}
