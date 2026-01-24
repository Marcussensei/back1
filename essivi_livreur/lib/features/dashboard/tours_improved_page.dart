import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/models/delivery.dart';
import 'improved_dashboard.dart';
import 'deliveries_page_new.dart';

class ToursPage extends StatefulWidget {
  final Agent agent;

  const ToursPage({Key? key, required this.agent}) : super(key: key);

  @override
  State<ToursPage> createState() => _ToursPageState();
}

class _ToursPageState extends State<ToursPage> {
  late Future<List<Map<String, dynamic>>> _toursData;
  String _selectedStatus = 'all'; // all, en_cours, completee, annulee

  @override
  void initState() {
    super.initState();
    debugPrint('🚗 [ToursPage] initState START');

    _toursData = ApiService.getTours();

    debugPrint('🚗 [ToursPage] initState END - Future lancée');
  }

  List<Map<String, dynamic>> _filterTours(List<Map<String, dynamic>> tours) {
    if (_selectedStatus == 'all') {
      return tours;
    }

    // Map frontend filter values to backend status values
    String backendStatus;
    switch (_selectedStatus) {
      case 'en_cours':
        backendStatus = 'in_progress';
        break;
      case 'completee':
        backendStatus = 'completed';
        break;
      case 'annulee':
        backendStatus = 'pending';
        break;
      default:
        return tours;
    }

    return tours.where((tour) => tour['status'] == backendStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tournées'),
        backgroundColor: const Color(0xFF00458A),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _toursData = ApiService.getTours();
          });
        },
        child: Column(
          children: [
            // Filtres
            _buildFilterChips(),

            // Liste des tournées
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _toursData,
                builder: (context, snapshot) {
                  print('🔄 [FutureBuilder] État: ${snapshot.connectionState}');
                  if (snapshot.hasData) {
                    print(
                        '📊 [FutureBuilder] Données: ${snapshot.data?.length} tournées');
                  }
                  if (snapshot.hasError) {
                    print('❌ [FutureBuilder] Erreur: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Erreur lors du chargement',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _toursData = ApiService.getTours();
                              });
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.tour,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune tournée',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez une nouvelle tournée',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startNewTour,
                            icon: const Icon(Icons.add),
                            label: const Text('Démarrer une tournée'),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredTours = _filterTours(snapshot.data!);

                  if (filteredTours.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune tournée avec ce filtre',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredTours.length,
                    itemBuilder: (context, index) {
                      final tour = filteredTours[index];
                      return _buildTourCard(context, tour);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   heroTag: 'tours_fab',
      //   onPressed: _startNewTour,
      //   label: const Text('Nouvelle tournée'),
      //   icon: const Icon(Icons.add),
      //   backgroundColor: const Color(0xFF00458A),
      // ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Tous', 'value': 'all'},
      {'label': 'En cours', 'value': 'en_cours'},
      {'label': 'Complétée', 'value': 'completee'},
      {'label': 'Annulée', 'value': 'annulee'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedStatus == filter['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = filter['value'] as String;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF00458A).withOpacity(0.2),
                side: BorderSide(
                  color:
                      isSelected ? const Color(0xFF00458A) : Colors.grey[300]!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTourCard(BuildContext context, Map<String, dynamic> tour) {
    final status = tour['status'] ?? 'pending';
    final deliveriesCount = tour['deliveries'] ?? 0;
    final completedCount = tour['completed'] ?? 0;

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.schedule;

    if (status == 'completed' || status == 'completee') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'annulee' || status == 'pending') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (status == 'in_progress' || status == 'en_cours') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TourDetailsPage(
                tour: tour,
                agent: widget.agent,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tournée #${tour['id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tour['district'] ?? 'Zone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          status == 'in_progress' || status == 'en_cours'
                              ? 'En cours'
                              : status == 'completed' || status == 'completee'
                                  ? 'Complétée'
                                  : 'Annulée',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Livraisons',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount/$deliveriesCount complétées',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Montant',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tour['total_amount'] ?? 0} CFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deliveriesCount > 0
                      ? completedCount / deliveriesCount
                      : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewTour() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer une nouvelle tournée'),
        content: const Text(
          'Êtes-vous prêt à commencer une nouvelle tournée? Assurez-vous que le GPS est activé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tournée démarrée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00458A),
            ),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }
}

class TourDetailsPage extends StatefulWidget {
  final Map<String, dynamic> tour;
  final Agent agent;

  const TourDetailsPage({
    Key? key,
    required this.tour,
    required this.agent,
  }) : super(key: key);

  @override
  State<TourDetailsPage> createState() => _TourDetailsPageState();
}

class _TourDetailsPageState extends State<TourDetailsPage> {
  late Future<List<Map<String, dynamic>>> _deliveriesFuture;

  @override
  void initState() {
    super.initState();
    _deliveriesFuture = ApiService.getTourDeliveries(widget.tour['date']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la tournée'),
        backgroundColor: const Color(0xFF00458A),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _deliveriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Erreur lors du chargement'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _deliveriesFuture =
                            ApiService.getTourDeliveries(widget.tour['date']);
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final deliveries = snapshot.data ?? [];
          final completedCount =
              deliveries.where((d) => d['statut'] == 'livree').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info générale
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tournée #${widget.tour['id']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.tour['status'] == 'completed' ||
                                      widget.tour['status'] == 'completee'
                                  ? Colors.green.withOpacity(0.1)
                                  : widget.tour['status'] == 'in_progress' ||
                                          widget.tour['status'] == 'en_cours'
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.tour['status'] == 'completed' ||
                                      widget.tour['status'] == 'completee'
                                  ? 'Complétée'
                                  : widget.tour['status'] == 'in_progress' ||
                                          widget.tour['status'] == 'en_cours'
                                      ? 'En cours'
                                      : 'Annulée',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.tour['status'] == 'completed' ||
                                        widget.tour['status'] == 'completee'
                                    ? Colors.green
                                    : widget.tour['status'] == 'in_progress' ||
                                            widget.tour['status'] == 'en_cours'
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Livraisons',
                            deliveries.length.toString(),
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Complétées',
                            completedCount.toString(),
                            Colors.green,
                          ),
                          _buildStatItem(
                            'Montant',
                            '${widget.tour['total_amount'] ?? 0} CFA',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Livraisons
                Text(
                  'Livraisons (${deliveries.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (deliveries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune livraison',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      final delivery = deliveries[index];
                      final isDone = delivery['statut'] == 'livree';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LivraisonDetailsPage(livraison: delivery),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.pending_actions,
                              color: isDone ? Colors.green : Colors.blue,
                            ),
                          ),
                          title: Text(
                            delivery['nom_point_vente'] ?? 'Client',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                delivery['adresse_livraison'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${delivery['montant_percu'] ?? 0} CFA',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
