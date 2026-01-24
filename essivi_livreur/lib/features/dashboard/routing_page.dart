import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/models/delivery.dart';
import '../../core/services/location_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/directions_service.dart';
import 'signature_pad.dart';

class RoutingPage extends StatefulWidget {
  final Delivery delivery;
  final Agent agent;

  const RoutingPage({
    Key? key,
    required this.delivery,
    required this.agent,
  }) : super(key: key);

  @override
  State<RoutingPage> createState() => _RoutingPageState();
}

class _RoutingPageState extends State<RoutingPage> {
  late LocationService _locationService;
  Position? _currentPosition;
  late Stream<Position> _positionStream;
  bool _isLoading = true;
  double _distanceToClient = 0;
  bool _isWithinDistance = false;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  RouteInfo? _routeInfo;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initLocation();
    _addMarkers();
  }

  void _addMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('client_location'),
        position: LatLng(widget.delivery.latitude, widget.delivery.longitude),
        infoWindow: InfoWindow(
          title: widget.delivery.clientName,
          snippet: widget.delivery.clientAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Add agent marker if position is available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('agent_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Votre position',
            snippet: 'Position actuelle',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  Future<void> _addRoutePolyline() async {
    if (_currentPosition == null) return;

    _polylines.clear();

    // Try to get directions from Google Maps API
    final directionsService = DirectionsService();
    try {
      final routePoints = await directionsService.getRoutePoints(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(widget.delivery.latitude, widget.delivery.longitude),
      );

      if (routePoints.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_client'),
            points: routePoints,
            color: Colors.blue,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
        print('[RoutingPage] Route loaded with ${routePoints.length} points');
      } else {
        // Fallback to straight line if no route points
        _addStraightLine();
      }
    } catch (e) {
      print('[RoutingPage] Error getting directions: $e');
      // Fallback to straight line
      _addStraightLine();
    }
  }

  void _addStraightLine() {
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_to_client'),
        points: [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(widget.delivery.latitude, widget.delivery.longitude),
        ],
        color: Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );
  }

  Future<void> _initLocation() async {
    try {
      print('[RoutingPage] Starting location initialization...');
      final hasPermission = await _locationService.requestLocationPermission();
      print('[RoutingPage] Location permission: $hasPermission');

      if (!hasPermission) {
        if (!mounted) return;
        print('[RoutingPage] Location permission denied, stopping');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation refusée'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Obtenir la position actuelle
      print('[RoutingPage] Getting current position...');
      final position = await _locationService.getCurrentPosition();
      print(
          '[RoutingPage] Current position: lat=${position?.latitude}, lon=${position?.longitude}');

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        await _calculateDistance();
      }

      // Démarrer le stream de position
      print('[RoutingPage] Starting position stream...');
      _positionStream = _locationService.getPositionStream();
      _positionStream.listen((position) async {
        print(
            '[RoutingPage] Position stream update: lat=${position.latitude}, lon=${position.longitude}');
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          await _calculateDistance();
          if (mounted) {
            setState(() {}); // Trigger UI update after distance calculation
          }
        }
      });

      // Mettre à jour la localisation du livreur
      print('[RoutingPage] Updating agent location on backend...');
      try {
        await ApiService.updateAgentLocation(
          latitude: position?.latitude ?? 0,
          longitude: position?.longitude ?? 0,
          agentId: widget.agent.id,
        );
        print('[RoutingPage] Agent location updated successfully');
      } catch (e) {
        print('[RoutingPage] Warning: Failed to update agent location: $e');
        // Ne pas bloquer si la MAJ échoue, continuer l'affichage
      }

      if (mounted) {
        setState(() => _isLoading = false);
        print('[RoutingPage] Initialization complete');
      }
    } catch (e) {
      print('[RoutingPage] Erreur initialisation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateDistance() async {
    if (_currentPosition == null) return;

    _distanceToClient = _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.delivery.latitude,
      widget.delivery.longitude,
    );

    // Vérifier si on est à proximité du client (moins de 5 mètres)
    _isWithinDistance = _distanceToClient <= 5.0;

    // Mettre à jour les marqueurs et la polyligne
    _addMarkers();
    await _addRoutePolyline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinéraire vers le client'),
        backgroundColor: const Color(0xFF00458A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Google Maps - Fixed at top, not scrollable
                SizedBox(
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null
                              ? LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude)
                              : LatLng(widget.delivery.latitude,
                                  widget.delivery.longitude),
                          zoom: 15,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapType: MapType.normal,
                        gestureRecognizers: <Factory<
                            OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
                    ),
                  ),
                ),
                // Scrollable content below the map
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info du client
                          _buildClientInfoCard(),
                          const SizedBox(height: 16),

                          // Distance en temps réel
                          _buildDistanceCard(),
                          const SizedBox(height: 16),

                          // Barre de progression distance
                          _buildDistanceProgress(),
                          const SizedBox(height: 16),

                          // Info de destination
                          _buildDestinationCard(),
                          const SizedBox(height: 24),

                          // Bouton pour valider si proche
                          if (_isWithinDistance)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showValidationDialog();
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Valider la livraison'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          if (!_isWithinDistance)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Approchez-vous du client (${_distanceToClient.toStringAsFixed(1)}m)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildClientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  widget.delivery.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isWithinDistance
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isWithinDistance ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_distanceToClient.toStringAsFixed(1)} m',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: _isWithinDistance ? Colors.green : Colors.orange,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isWithinDistance ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isWithinDistance ? 'Proche ✓' : 'Trop loin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceProgress() {
    final progress = (_distanceToClient / 50).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progression vers le client',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: 1 - progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _isWithinDistance ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '5 m',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              '50 m',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destination',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.delivery.clientAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Lat: ${widget.delivery.latitude.toStringAsFixed(4)}, Lon: ${widget.delivery.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showValidationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous prêt à valider cette livraison?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous êtes à la bonne distance (< 5m)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeDelivery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDelivery() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await ApiService.updateDeliveryStatus(
        tourId: widget.delivery.id.toString(),
        deliveryId: widget.delivery.id.toString(),
        status: 'livree',
      );

      if (!mounted) return;

      if (result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison validée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la validation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
