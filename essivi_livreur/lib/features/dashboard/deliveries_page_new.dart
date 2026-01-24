import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/models/delivery.dart';
import 'routing_page.dart';

class DeliveriesPageNew extends StatefulWidget {
  const DeliveriesPageNew({Key? key}) : super(key: key);

  @override
  State<DeliveriesPageNew> createState() => _DeliveriesPageNewState();
}

class _DeliveriesPageNewState extends State<DeliveriesPageNew> {
  late Future<List<dynamic>> _livraisons;

  @override
  void initState() {
    super.initState();
    _loadLivraisons();
  }

  void _loadLivraisons() {
    // Récupérer l'ID de l'agent depuis getMe() avec fallback
    _livraisons = _getAgentId().then((agentId) {
      print('[DeliveriesPage] Got Agent ID: $agentId');
      return ApiService.getLivraisonsByAgent(agentId);
    }).then((livs) {
      print('[DeliveriesPage] Livraisons received: ${livs.length} items');
      return livs;
    }).catchError((error, stackTrace) {
      print('[DeliveriesPage] Erreur complète: $error');
      print('[DeliveriesPage] Stack trace: $stackTrace');
      // Return empty list on error
      return <dynamic>[];
    });
  }

  /// Récupère l'ID de l'agent - avec fallback en cas d'erreur
  Future<int> _getAgentId() async {
    try {
      final agentData = await ApiService.getMe();
      print('[DeliveriesPage] Agent data from API: $agentData');

      // Utiliser agent_id (de la table agents) au lieu de id (de la table users)
      final agentId = agentData['agent_id'] ?? agentData['id'];
      if (agentId is int) {
        return agentId;
      } else if (agentId is String) {
        return int.parse(agentId);
      } else {
        throw Exception('Invalid agent ID type: ${agentId.runtimeType}');
      }
    } catch (e) {
      print('[DeliveriesPage] Error getting agent ID: $e, using default');
      // Fallback: retourner un ID par défaut (le serveur gérera)
      // ou on peut essayer de récupérer depuis les headers/storage
      return 1; // Default agent ID as fallback
    }
  }

  void _refreshData() {
    setState(() {
      _loadLivraisons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: FutureBuilder<List<dynamic>>(
        future: _livraisons,
        builder: (context, snapshot) {
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
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final livraisons = snapshot.data ?? [];

          if (livraisons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucune livraison assignée'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Actualiser'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: livraisons.length,
            itemBuilder: (context, index) {
              final livraison = livraisons[index];
              return _buildLivraisonCard(context, livraison);
            },
          );
        },
      ),
    );
  }

  Widget _buildLivraisonCard(BuildContext context, dynamic livraison) {
    final id = livraison['id'] ?? 'N/A';
    final client = livraison['nom_point_vente'] ?? 'Client inconnu';
    final adresse = livraison['adresse_livraison'] ?? 'Adresse inconnue';
    final montant = livraison['montant_percu'] ?? 0;
    final quantite = livraison['quantite'] ?? 0;
    final statut = livraison['statut'] ?? 'en_cours';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LivraisonDetailsPage(livraison: livraison),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec ID et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Livraison #$id',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statut == 'livree' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statut.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Client
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      client,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Adresse
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adresse,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Montant et Quantité
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montant',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$montant FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantité',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$quantite unités',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Détails',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LivraisonDetailsPage extends StatefulWidget {
  final dynamic livraison;

  const LivraisonDetailsPage({
    Key? key,
    required this.livraison,
  }) : super(key: key);

  @override
  State<LivraisonDetailsPage> createState() => _LivraisonDetailsPageState();
}

class _LivraisonDetailsPageState extends State<LivraisonDetailsPage> {
  late final dynamic livraison;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    livraison = widget.livraison;
  }

  Future<void> _openMap() async {
    try {
      // Récupérer les données de l'agent
      final agentData = await ApiService.getMe();

      // Utiliser agent_info si disponible, sinon les données top-level
      final agentInfo = agentData['agent_info'] ?? agentData;

      print('[DeliveriesPage] AgentInfo: $agentInfo');

      // Convertir actif (bool) en status (string)
      String agentStatus = 'actif';
      if (agentInfo['actif'] is bool) {
        agentStatus = agentInfo['actif'] ? 'actif' : 'inactif';
      } else if (agentInfo['status'] is String) {
        agentStatus = agentInfo['status'];
      }

      // Créer l'objet Agent
      final agent = Agent(
        id: agentData['agent_id'] ?? agentData['id'] ?? 0,
        name: agentInfo['nom'] ?? agentInfo['name'] ?? 'Agent',
        email: agentInfo['email'] ?? '',
        phone: agentInfo['telephone'] ?? agentInfo['phone'] ?? '',
        tricycle: agentInfo['tricycle'] ?? 'Non assigné',
        status: agentStatus,
      );

      print(
          '[DeliveriesPage] Created Agent: id=${agent.id}, name=${agent.name}, tricycle=${agent.tricycle}, status=$agentStatus');

      // Créer l'objet Delivery à partir des données de livraison
      final delivery = Delivery(
        id: livraison['id'] ?? 0,
        agentId: agent.id,
        clientId: livraison['client_id'] ?? 0,
        clientName: livraison['nom_point_vente'] ?? 'Client inconnu',
        clientPhone: livraison['client_telephone'] ?? '',
        clientAddress: livraison['adresse_livraison'] ?? 'Adresse inconnue',
        latitude: (livraison['latitude_gps'] ?? 0.0) as double,
        longitude: (livraison['longitude_gps'] ?? 0.0) as double,
        quantity: livraison['quantite'] ?? 0,
        amount: (livraison['montant_percu'] ?? 0.0) as double,
        status: livraison['statut'] ?? 'en_cours',
        createdAt: livraison['created_at'] != null
            ? DateTime.parse(livraison['created_at'])
            : DateTime.now(),
      );

      print(
          '[DeliveriesPage] Created Delivery: id=${delivery.id}, client=${delivery.clientName}, address=${delivery.clientAddress}');

      // Naviguer vers RoutingPage
      if (mounted) {
        print('[DeliveriesPage] Navigating to RoutingPage...');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutingPage(
              delivery: delivery,
              agent: agent,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Erreur lors de l\'ouverture de l\'itinéraire: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _callClient() async {
    String clientPhone = livraison['client_telephone'] ?? '';

    // Si le numéro n'est pas disponible, utiliser un numéro par défaut pour les tests
    if (clientPhone.isEmpty) {
      clientPhone = '+213671234567'; // Numéro par défaut pour les tests
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro par défaut utilisé (+213671234567)'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: clientPhone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de lancer l\'appel téléphonique'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'appel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _validateDelivery() async {
    setState(() {
      _isValidating = true;
    });

    try {
      final livraisonId = livraison['id'];

      // Appeler l'API pour marquer comme livrée
      final response = await ApiService.updateLivraison(
        livraisonId,
        {'statut': 'livree'},
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Livraison validée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );

        // Revenir à la liste
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = livraison['id'] ?? 'N/A';
    final client = livraison['nom_point_vente'] ?? 'Client inconnu';
    final adresse = livraison['adresse_livraison'] ?? 'Adresse inconnue';
    final montant = livraison['montant_percu'] ?? 0;
    final quantite = livraison['quantite'] ?? 0;
    final statut = livraison['statut'] ?? 'en_cours';
    final agentNom = livraison['agent_nom'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Livraison #$id'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            color: statut == 'livree'
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    statut == 'livree' ? Icons.check_circle : Icons.schedule,
                    size: 32,
                    color: statut == 'livree' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statut',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          statut.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: statut == 'livree'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Client Details
          _buildDetailSection(
            title: 'Client',
            children: [
              _buildDetailRow('Nom', client),
              _buildDetailRow('Adresse', adresse),
              _buildDetailRow('Agent assigné', agentNom),
            ],
          ),
          const SizedBox(height: 16),

          // Delivery Details
          _buildDetailSection(
            title: 'Détails de la Livraison',
            children: [
              _buildDetailRow('Montant', '$montant FCFA'),
              _buildDetailRow('Quantité', '$quantite unités'),
              _buildDetailRow('ID Livraison', '#$id'),
            ],
          ),
          const SizedBox(height: 16),

          // Boutons d'action
          if (statut != 'livree') ...[
            // Itineraire Button
            ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.directions_car),
              label: const Text('Voir l\'Itinéraire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Call Button
            ElevatedButton.icon(
              onPressed: _callClient,
              icon: const Icon(Icons.phone),
              label: const Text('Appeler le Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Validate Button
            ElevatedButton.icon(
              onPressed: _isValidating ? null : _validateDelivery,
              icon: _isValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                  _isValidating ? 'Validation...' : 'Valider la Livraison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Text(
                '✅ Cette livraison a déjà été validée',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
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
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
