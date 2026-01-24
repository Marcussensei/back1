import 'package:flutter/material.dart';
import '../../core/models/tour_model.dart';
import '../../core/services/offline_service.dart';
import 'record_delivery_page.dart';

class ActiveTourPage extends StatefulWidget {
  final Tour tour;

  const ActiveTourPage({super.key, required this.tour});

  @override
  State<ActiveTourPage> createState() => _ActiveTourPageState();
}

class _ActiveTourPageState extends State<ActiveTourPage> {
  late OfflineService _offlineService;
  late Tour _currentTour;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _offlineService = OfflineService();
    _currentTour = widget.tour;
  }

  Future<void> _recordDelivery(Delivery delivery) async {
    try {
      setState(() => _isLoading = true);

      // Sauvegarder la livraison
      await _offlineService.saveDelivery(delivery);

      // Mettre à jour la tournée
      _currentTour = Tour(
        id: _currentTour.id,
        agentId: _currentTour.agentId,
        startTime: _currentTour.startTime,
        endTime: _currentTour.endTime,
        deliveries: [..._currentTour.deliveries, delivery],
        totalDistance: _currentTour.totalDistance + delivery.distanceMeters,
        totalAmount: _currentTour.totalAmount + delivery.amount,
        status: _currentTour.status,
      );

      await _offlineService.saveTour(_currentTour);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livraison enregistrée')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endTour() async {
    try {
      setState(() => _isLoading = true);

      final endedTour = Tour(
        id: _currentTour.id,
        agentId: _currentTour.agentId,
        startTime: _currentTour.startTime,
        endTime: DateTime.now(),
        deliveries: _currentTour.deliveries,
        totalDistance: _currentTour.totalDistance,
        totalAmount: _currentTour.totalAmount,
        status: TourStatus.completed,
      );

      await _offlineService.saveTour(endedTour);

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournée terminée')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedDeliveries = _currentTour.deliveries
        .where((d) => d.status == DeliveryStatus.completed)
        .length;
    final remainingDeliveries =
        _currentTour.deliveries.length - completedDeliveries;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tournée #${_currentTour.id}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                _buildStatsRow(
                    context, completedDeliveries, remainingDeliveries),
                const SizedBox(height: 24),

                // Livraisons
                Text(
                  'Livraisons (${_currentTour.deliveries.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (_currentTour.deliveries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucune livraison pour cette tournée',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentTour.deliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = _currentTour.deliveries[index];
                      return _buildDeliveryCard(context, delivery);
                    },
                  ),

                const SizedBox(height: 24),

                // Ajouter livraison
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordDeliveryPage(
                                  tourId: _currentTour.id,
                                ),
                              ),
                            );
                            if (result is Delivery) {
                              _recordDelivery(result);
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une livraison'),
                  ),
                ),

                const SizedBox(height: 16),

                // Terminer tournée
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _endTour,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Terminer la tournée'),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int completed, int remaining) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.check_circle,
            label: 'Complétées',
            value: completed.toString(),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.schedule,
            label: 'En attente',
            value: remaining.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.directions,
            label: 'Distance',
            value:
                '${(_currentTour.totalDistance / 1000).toStringAsFixed(1)} km',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Delivery delivery) {
    final statusColor = _getDeliveryStatusColor(delivery.status);
    final statusIcon = _getDeliveryStatusIcon(delivery.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(delivery.clientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              delivery.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${delivery.quantities.values.fold(0, (a, b) => a + b)} article(s) - ${delivery.amount} XOF',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(_getDeliveryStatusLabel(delivery.status)),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }

  Color _getDeliveryStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inProgress:
        return Colors.blue;
      case DeliveryStatus.completed:
        return Colors.green;
      case DeliveryStatus.failed:
        return Colors.red;
      case DeliveryStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getDeliveryStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Icons.schedule;
      case DeliveryStatus.inProgress:
        return Icons.local_shipping;
      case DeliveryStatus.completed:
        return Icons.check_circle;
      case DeliveryStatus.failed:
        return Icons.error;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getDeliveryStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En attente';
      case DeliveryStatus.inProgress:
        return 'En cours';
      case DeliveryStatus.completed:
        return 'Complétée';
      case DeliveryStatus.failed:
        return 'Échouée';
      case DeliveryStatus.cancelled:
        return 'Annulée';
    }
  }
}
