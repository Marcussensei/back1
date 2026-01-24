import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/delivery.dart';
import 'deliveries_page_new.dart';
import 'notifications_page.dart';
import 'tours_improved_page.dart';

class ImprovedDeliveryDashboard extends StatefulWidget {
  final Agent? agent;
  final VoidCallback? onLogout;

  const ImprovedDeliveryDashboard({
    Key? key,
    this.agent,
    this.onLogout,
  }) : super(key: key);

  @override
  State<ImprovedDeliveryDashboard> createState() =>
      _ImprovedDeliveryDashboardState();
}

class _ImprovedDeliveryDashboardState extends State<ImprovedDeliveryDashboard> {
  int _selectedIndex = 0;
  late Future<DeliveryStats?> _statsData;
  late Future<List<Delivery>> _deliveriesData;
  late Future<List<Delivery>> _completedDeliveriesData;
  late Future<Map<String, dynamic>> _agentData;
  late Future<int> _unreadNotificationsCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    print('[ImprovedDashboard] _loadData() START');

    // Initialiser immédiatement avec Future.delayed pour éviter LateInitializationError
    _agentData = Future.delayed(const Duration(milliseconds: 300)).then((_) {
      print(
          '[ImprovedDashboard] Après délai - token check: ${ApiService.getTokenSync()}');
      return ApiService.getMe();
    }).then((data) {
      print('[ImprovedDashboard] Agent data: $data');
      return data;
    }).catchError((error) {
      print('[ImprovedDashboard] Erreur getMe: $error');
      // Retourner des données par défaut en cas d'erreur
      return {
        'name': 'Agent de Livraison',
        'email': 'agent@essivi.com',
        'tricycle': 'Non assigné',
        'id': 0,
      } as Map<String, dynamic>;
    });

    // Charger le nombre de notifications non lues
    _unreadNotificationsCount =
        Future.delayed(const Duration(milliseconds: 300)).then((_) {
      return ApiService.getUserNotifications(unreadOnly: true, limit: 100);
    }).then((notifications) {
      return notifications.length;
    }).catchError((error) {
      print('Erreur chargement notifications: $error');
      return 0;
    });

    _statsData = Future.delayed(const Duration(milliseconds: 300)).then((_) {
      return ApiService.getStatistics();
    }).then((data) {
      return DeliveryStats(
        totalDeliveries: data['total_deliveries'] ?? 0,
        completedDeliveries: data['completed_deliveries'] ?? 0,
        totalAmount: (data['total_amount'] ?? 0).toDouble(),
        totalQuantity: (data['total_quantity'] ?? 0).toDouble(),
        averageDistance:
            '${(data['average_distance'] ?? 0).toStringAsFixed(1)} km',
      );
    }).catchError((error) {
      print('Erreur stats: $error');
      return null;
    });

    _deliveriesData = _agentData.then((agentData) {
      final agentId = agentData['agent_id'] ?? agentData['id'] ?? 0;
      print('[Dashboard] Agent ID for deliveries: $agentId');
      if (agentId == 0) return Future.value([]);
      return ApiService.getLivraisonsByAgent(agentId);
    }).then((livraisons) {
      print('[Dashboard] Raw livraisons received: ${livraisons.length} items');
      final filtered = livraisons
          .where((livraison) => livraison['statut'] == 'en_cours')
          .toList();
      print(
          '[Dashboard] Filtered en_cours livraisons: ${filtered.length} items');
      final deliveries = filtered.map((livraison) {
        print(
            '[Dashboard] Processing livraison: ${livraison['id']} - ${livraison['nom_point_vente']}');
        return Delivery.fromJson(livraison);
      }).toList();
      print('[Dashboard] Created deliveries: ${deliveries.length} items');
      if (deliveries.isNotEmpty) {
        print(
            '[Dashboard] First delivery: ${deliveries[0].clientName}, ${deliveries[0].clientAddress}, ${deliveries[0].quantity} sachets');
      }
      return deliveries;
    }).catchError((error) {
      print('Erreur livraisons en cours: $error');
      return [];
    });

    _completedDeliveriesData = _agentData.then((agentData) {
      final agentId = agentData['agent_id'] ?? agentData['id'] ?? 0;
      print('[Dashboard] Agent ID for completed deliveries: $agentId');
      if (agentId == 0) return Future.value([]);
      return ApiService.getLivraisonsByAgent(agentId);
    }).then((livraisons) {
      print(
          '[Dashboard] Raw livraisons for history: ${livraisons.length} items');
      final filtered = livraisons
          .where((livraison) => livraison['statut'] == 'livree')
          .toList();
      print('[Dashboard] Filtered livree livraisons: ${filtered.length} items');
      final deliveries = filtered.map((livraison) {
        print(
            '[Dashboard] Processing completed livraison: ${livraison['id']} - ${livraison['nom_point_vente']}');
        return Delivery.fromJson(livraison);
      }).toList();
      print(
          '[Dashboard] Created completed deliveries: ${deliveries.length} items');
      if (deliveries.isNotEmpty) {
        print(
            '[Dashboard] First completed delivery: ${deliveries[0].clientName}, ${deliveries[0].clientAddress}, ${deliveries[0].quantity} sachets');
      }
      return deliveries;
    }).catchError((error) {
      print('Erreur historique: $error');
      return [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Essivivi'),
        elevation: 0,
        backgroundColor: const Color(0xFF00458A),
        centerTitle: true,
        actions: [
          // Notifications
          FutureBuilder<int>(
            future: _unreadNotificationsCount,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Paramètres
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres en développement')),
              );
            },
            tooltip: 'Paramètres',
          ),
          // Déconnexion
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.logout();
                if (mounted) {
                  widget.onLogout?.call();
                }
              },
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00458A),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Livraisons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tour),
            label: 'Tournées',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () {
          _showSOSDialog();
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.emergency),
        label: const Text('SOS'),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildDeliveriesPage();
      case 2:
        return _buildToursPage();
      case 3:
        return _buildHistoryPage();
      case 4:
        return _buildNotificationsPage();
      case 5:
        return _buildProfilePage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildNotificationsPage() {
    return const NotificationsPage();
  }

  Widget _buildDashboardPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            Text(
              'Statistiques d\'aujourd\'hui',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<DeliveryStats?>(
              future: _statsData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const _StatErrorWidget();
                }
                final stats = snapshot.data!;
                return Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: crossAxisCount == 4 ? 1.2 : 0.9,
                          children: [
                            _buildStatCard(
                              title: 'Livraisons',
                              value: '${stats.totalDeliveries}',
                              subtitle:
                                  '${stats.completedDeliveries} complétées',
                              icon: Icons.local_shipping,
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              title: 'Montant Total',
                              value:
                                  '${stats.totalAmount.toStringAsFixed(0)} CFA',
                              subtitle: 'Jour',
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              title: 'Quantité',
                              value: stats.totalQuantity.toStringAsFixed(0),
                              subtitle: 'sachet/colis',
                              icon: Icons.inventory_2,
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              title: 'Distance',
                              value: stats.averageDistance,
                              subtitle: 'moyenne',
                              icon: Icons.directions,
                              color: Colors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildPerformanceChart(stats),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Livraisons en attente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Delivery>>(
              future: _deliveriesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const _DeliveriesErrorWidget();
                }
                final deliveries = snapshot.data!;
                if (deliveries.isEmpty) {
                  return _buildEmptyDeliveries();
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    return _buildDeliveryCard(context, delivery);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesPage() {
    return const DeliveriesPageNew();
  }

  Widget _buildToursPage() {
    // Créer un agent dummy si null, les données réelles viendront de l'API
    final agent = widget.agent ??
        Agent(
          id: 0,
          name: 'Agent',
          email: 'agent@essivi.com',
          phone: '',
          tricycle: 'Non assigné',
          status: 'actif',
        );
    return ToursPage(agent: agent);
  }

  Widget _buildHistoryPage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<Delivery>>(
        future: _completedDeliveriesData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Erreur lors du chargement'));
          }
          final completed = snapshot.data!;
          if (completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun historique'),
                  const SizedBox(height: 8),
                  Text(
                    'Les livraisons complétées apparaîtront ici',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: completed
                .map((delivery) => _buildDeliveryCard(context, delivery))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildProfilePage() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _agentData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final agentName = snapshot.data?['nom'] ?? 'Agent de Livraison';
        final agentEmail = snapshot.data?['email'] ?? 'agent@essivi.com';
        final tricycleName =
            snapshot.data?['agent_info']?['tricycle'] ?? 'Non assigné';
        final agentId = snapshot.data?['agent_id'] ?? snapshot.data?['id'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte profil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00458A), Color(0xFF0066CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      agentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID Agent: #$agentId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Infos
              _buildProfileInfoCard('Email', agentEmail),
              _buildProfileInfoCard('Tricycle', tricycleName),
              FutureBuilder<DeliveryStats?>(
                future: _statsData,
                builder: (context, snapshot) {
                  final totalDel = snapshot.data?.totalDeliveries ?? 0;
                  return _buildProfileInfoCard(
                    'Livraisons totales',
                    totalDel.toString(),
                  );
                },
              ),
              FutureBuilder<DeliveryStats?>(
                future: _statsData,
                builder: (context, snapshot) {
                  final completedDel = snapshot.data?.completedDeliveries ?? 0;
                  return _buildProfileInfoCard(
                    'Livraisons complétées',
                    completedDel.toString(),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Édition en développement')),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Éditer le profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00458A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    if (mounted) {
                      widget.onLogout?.call();
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appel SOS'),
        content: const Text(
          'Êtes-vous en danger ou avez-vous besoin d\'aide ?',
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
                  content: Text('Appel SOS envoyé - Support en route'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Envoyer SOS'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _agentData,
      builder: (context, snapshot) {
        final agentName = snapshot.data?['nom'] ?? 'Agent de Livraison';
        final tricycleName =
            snapshot.data?['agent_info']?['tricycle'] ?? 'Non assigné';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00458A), Color(0xFF0066CC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, $agentName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tricycle: $tricycleName',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<DeliveryStats?>(
                    future: _statsData,
                    builder: (context, snapshot) {
                      final completedDel =
                          snapshot.data?.completedDeliveries ?? 0;
                      return _buildStatusChip(
                        '$completedDel complétées',
                        Colors.greenAccent,
                      );
                    },
                  ),
                  FutureBuilder<DeliveryStats?>(
                    future: _statsData,
                    builder: (context, snapshot) {
                      final totalDeliveries =
                          snapshot.data?.totalDeliveries ?? 0;
                      return _buildStatusChip(
                        '$totalDeliveries livraisons',
                        Colors.blueAccent,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(DeliveryStats stats) {
    final completion = stats.totalDeliveries > 0
        ? (stats.completedDeliveries / stats.totalDeliveries * 100)
            .toStringAsFixed(0)
        : '0';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive chart size based on available width
        final chartSize = constraints.maxWidth < 400 ? 120.0 : 150.0;
        final radius = chartSize / 3;

        return Container(
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
              const Text(
                'Taux de complétion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  height: chartSize,
                  width: chartSize,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: stats.completedDeliveries.toDouble(),
                          color: Colors.green,
                          title: 'Complétées',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: constraints.maxWidth < 400 ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        PieChartSectionData(
                          value: (stats.totalDeliveries -
                                  stats.completedDeliveries)
                              .toDouble(),
                          color: Colors.red,
                          title: 'En attente',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: constraints.maxWidth < 400 ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: constraints.maxWidth < 400 ? 20 : 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$completion% complétées',
                  style: TextStyle(
                    fontSize: constraints.maxWidth < 400 ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Delivery delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          delivery.clientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              delivery.clientAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${delivery.quantity} sachet(s)',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${delivery.amount.toStringAsFixed(0)} CFA',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailPage(
                delivery: delivery,
                agent: widget.agent,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyDeliveries() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'Toutes les livraisons sont complétées!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excellent travail aujourd\'hui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatErrorWidget extends StatelessWidget {
  const _StatErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Erreur lors du chargement des statistiques',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveriesErrorWidget extends StatelessWidget {
  const _DeliveriesErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Erreur lors du chargement des livraisons',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryDetailPage extends StatefulWidget {
  final Delivery delivery;
  final Agent? agent;

  const DeliveryDetailPage({
    Key? key,
    required this.delivery,
    this.agent,
  }) : super(key: key);

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
        backgroundColor: const Color(0xFF00458A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte du client
            _buildClientInfoCard(),
            const SizedBox(height: 24),

            // Détails de la livraison
            _buildDeliveryDetailsCard(),
            const SizedBox(height: 24),

            // Boutons d'action
            _buildActionButtons(context),
          ],
        ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du client',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.delivery.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.delivery.clientPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.delivery.clientAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildDeliveryDetailsCard() {
    return Container(
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
          const Text(
            'Détails de la livraison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Quantité', '${widget.delivery.quantity} sachet(s)'),
          _buildDetailRow(
            'Montant',
            '${widget.delivery.amount.toStringAsFixed(0)} CFA',
          ),
          _buildDetailRow('Statut', widget.delivery.status),
          _buildDetailRow(
            'Date',
            '${widget.delivery.createdAt.day}/${widget.delivery.createdAt.month}/${widget.delivery.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Ouvrir la carte de localisation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryLocationPage(
                    delivery: widget.delivery,
                    agent: widget.agent,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Localiser le client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Itinéraire en développement'),
                ),
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text('Obtenir l\'itinéraire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompleteDeliveryPage(
                    delivery: widget.delivery,
                    agent: widget.agent,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Valider la livraison'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DeliveryLocationPage extends StatefulWidget {
  final Delivery delivery;
  final Agent? agent;

  const DeliveryLocationPage({
    Key? key,
    required this.delivery,
    this.agent,
  }) : super(key: key);

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addMarker();
  }

  void _addMarker() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
        backgroundColor: const Color(0xFF00458A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Position du client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
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
                      target: LatLng(
                          widget.delivery.latitude, widget.delivery.longitude),
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vous devez être à moins de 2 mètres du client pour valider la livraison',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompleteDeliveryPage extends StatefulWidget {
  final Delivery delivery;
  final Agent? agent;

  const CompleteDeliveryPage({
    Key? key,
    required this.delivery,
    this.agent,
  }) : super(key: key);

  @override
  State<CompleteDeliveryPage> createState() => _CompleteDeliveryPageState();
}

class _CompleteDeliveryPageState extends State<CompleteDeliveryPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valider la livraison'),
        backgroundColor: const Color(0xFF00458A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmation de livraison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.delivery.clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.delivery.clientPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Quantité',
                    '${widget.delivery.quantity} sachet(s)',
                  ),
                  _buildDetailRow(
                    'Montant',
                    '${widget.delivery.amount.toStringAsFixed(0)} CFA',
                  ),
                  _buildDetailRow(
                    'Adresse',
                    widget.delivery.clientAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vérifiez que vous êtes à moins de 2 mètres du client',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmer la livraison',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Future<void> _completeDelivery() async {
    setState(() => _isLoading = true);

    try {
      // Simulation de la validation
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison validée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
