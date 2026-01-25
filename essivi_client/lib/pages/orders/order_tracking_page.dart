import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/order_service.dart';
import '../../core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderTrackingPage extends StatefulWidget {
  final int orderId;
  final int agentId;
  final String deliveryAddress;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
    required this.agentId,
    required this.deliveryAddress,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  GoogleMapController? _mapController;
  Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _agentLocation;
  late LocationService _locationService;
  int? _clientId;

  // Default location (Lomé, Togo)
  static const LatLng _defaultLocation = LatLng(6.1725, 1.2314);

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    // Récupérer l'ID du client depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getInt('client_id');

    if (clientId != null) {
      setState(() => _clientId = clientId);
      // Démarrer le suivi de position
      _locationService.startLocationTracking(clientId);
      debugPrint('✅ Suivi de position démarré pour le client $clientId');
    } else {
      debugPrint('⚠️ ID client non trouvé');
    }

    _loadAgentLocation();
  }

  Future<void> _loadAgentLocation() async {
    try {
      debugPrint('=== 🔄 CHARGEMENT DE LA POSITION DE L\'AGENT ===');
      debugPrint('📱 Order ID: ${widget.orderId}');
      debugPrint('👤 Agent ID: ${widget.agentId}');

      if (!mounted) {
        debugPrint('⚠️ Widget non monté, abandon');
        return;
      }

      setState(() => _isLoading = true);
      debugPrint('🔄 État de chargement activé');

      debugPrint('🌐 Appel API: /commandes/${widget.orderId}/agent-location');
      final agentLocation = await OrderService().getAgentLocation(
        widget.orderId,
      );
      debugPrint('✅ Réponse API reçue');

      if (!mounted) {
        debugPrint('⚠️ Widget disposé après l\'appel API, abandon');
        return;
      }

      if (agentLocation != null) {
        debugPrint('📍 Position reçue:');
        debugPrint('   - Latitude: ${agentLocation['latitude']}');
        debugPrint('   - Longitude: ${agentLocation['longitude']}');
        debugPrint('   - Agent: ${agentLocation['name']}');

        setState(() {
          _agentLocation = agentLocation;
          _isLoading = false;
        });
        debugPrint('✅ État mis à jour avec succès');
        _updateMap();
      } else {
        debugPrint('⚠️ Pas de données de position reçues');
        setState(() {
          _errorMessage = 'Position de l\'agent non disponible';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ ERREUR: $e');
      debugPrint('🔍 Type d\'erreur: ${e.runtimeType}');

      if (!mounted) {
        debugPrint('⚠️ Widget disposé après erreur, abandon');
        return;
      }

      setState(() {
        _errorMessage = 'Erreur lors du chargement de la position: $e';
        _isLoading = false;
      });
    }
  }

  void _updateMap() {
    if (_agentLocation == null) return;

    final agentLatLng = LatLng(
      _agentLocation!['latitude'],
      _agentLocation!['longitude'],
    );

    // Add agent marker
    final agentMarkerId = const MarkerId('agent');
    final agentMarker = Marker(
      markerId: agentMarkerId,
      position: agentLatLng,
      infoWindow: InfoWindow(
        title: 'Agent: ${_agentLocation!['name']}',
        snippet: 'Téléphone: ${_agentLocation!['phone']}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    // Add delivery address marker (placeholder - you might want to geocode the address)
    final deliveryMarkerId = const MarkerId('delivery');
    final deliveryMarker = Marker(
      markerId: deliveryMarkerId,
      position: _defaultLocation, // You should geocode the actual address
      infoWindow: InfoWindow(
        title: 'Adresse de livraison',
        snippet: widget.deliveryAddress,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markers = {agentMarkerId: agentMarker, deliveryMarkerId: deliveryMarker};
    });

    // Move camera to show both markers
    if (_mapController != null && mounted) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                agentLatLng.latitude < _defaultLocation.latitude
                    ? agentLatLng.latitude
                    : _defaultLocation.latitude,
                agentLatLng.longitude < _defaultLocation.longitude
                    ? agentLatLng.longitude
                    : _defaultLocation.longitude,
              ),
              northeast: LatLng(
                agentLatLng.latitude > _defaultLocation.latitude
                    ? agentLatLng.latitude
                    : _defaultLocation.latitude,
                agentLatLng.longitude > _defaultLocation.longitude
                    ? agentLatLng.longitude
                    : _defaultLocation.longitude,
              ),
            ),
            100, // padding
          ),
        );
        debugPrint('✅ Caméra animée avec succès');
      } catch (e) {
        debugPrint('⚠️ Erreur lors de l\'animation de la caméra: $e');
      }
    } else {
      debugPrint('⚠️ MapController non initialisé ou widget disposé');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi - Commande #${widget.orderId}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de la position de l\'agent...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadAgentLocation,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Map
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _defaultLocation,
                      zoom: 12,
                    ),
                    markers: Set<Marker>.of(_markers.values),
                    polylines: Set<Polyline>.of(_polylines.values),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updateMap();
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),

                // Agent info and delivery details
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Agent info
                        if (_agentLocation != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agent: ${_agentLocation!['name']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Téléphone: ${_agentLocation!['phone']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Delivery address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Adresse de livraison',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.deliveryAddress,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                        const Spacer(),

                        // Refresh button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loadAgentLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser la position'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Arrêter le suivi de position quand la page est fermée
    _locationService.stopLocationTracking();
    _mapController?.dispose();
    super.dispose();
  }
}
