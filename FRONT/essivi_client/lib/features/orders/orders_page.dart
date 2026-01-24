import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/empty_state.dart';
import '../../models/order.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<OrdersProvider>().loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Commandes'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const EmptyState(
          icon: Icons.login,
          title: 'Non connecté',
          message: 'Veuillez vous connecter pour voir vos commandes',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'En attente'),
            Tab(text: 'En cours'),
            Tab(text: 'Livrées'),
          ],
        ),
      ),
      body: ordersProvider.isLoading && !ordersProvider.hasOrders
          ? const LoadingIndicator(message: 'Chargement des commandes...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(ordersProvider.orders, ordersProvider),
                _buildOrdersList(ordersProvider.pendingOrders, ordersProvider),
                _buildOrdersList(
                  ordersProvider.inProgressOrders,
                  ordersProvider,
                ),
                _buildOrdersList(
                  ordersProvider.deliveredOrders,
                  ordersProvider,
                ),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, OrdersProvider ordersProvider) {
    if (ordersProvider.error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Erreur de chargement',
        message: ordersProvider.error!,
        actionText: 'Réessayer',
        onAction: () => ordersProvider.refresh(),
      );
    }

    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Aucune commande',
        message: 'Vous n\'avez pas encore de commandes dans cette catégorie',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ordersProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.statut);
    final statusIcon = _getStatusIcon(order.statut);
    final statusText = _getStatusText(order.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          'Commande #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy à HH:mm',
                          ).format(order.dateCommande),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
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
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (order.items.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.adresseLivraison ?? 'Adresse non spécifiée',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Montant total',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.montantTotal.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.statut == 'en_attente' ||
                          order.statut == 'confirmee') ...[
                        TextButton.icon(
                          onPressed: () => _showCancelDialog(order),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Annuler'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // ElevatedButton.icon(
                      //   onPressed: () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       SnackBar(
                      //         content: Text('Détails commande #${order.id}'),
                      //       ),
                      //     );
                      //   },
                      //   icon: const Icon(Icons.visibility, size: 18),
                      //   label: const Text('Détails'),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Theme.of(context).primaryColor,
                      //     foregroundColor: Colors.white,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(8),
                      //     ),
                      //   ),
                      // ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Colors.orange;
      case 'confirmee':
      case 'confirmed':
        return Colors.blue;
      case 'en_cours':
      case 'in_progress':
        return Colors.purple;
      case 'livree':
      case 'delivered':
        return Colors.green;
      case 'annulee':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Icons.pending;
      case 'confirmee':
      case 'confirmed':
        return Icons.check_circle;
      case 'en_cours':
      case 'in_progress':
        return Icons.local_shipping;
      case 'livree':
      case 'delivered':
        return Icons.done_all;
      case 'annulee':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'En attente';
      case 'confirmee':
      case 'confirmed':
        return 'Confirmée';
      case 'en_cours':
      case 'in_progress':
        return 'En cours';
      case 'livree':
      case 'delivered':
        return 'Livrée';
      case 'annulee':
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la commande'),
          content: Text(
            'Êtes-vous sûr de vouloir annuler la commande #${order.id} ?\n\n'
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fermer le dialog

                final ordersProvider = context.read<OrdersProvider>();
                final success = await ordersProvider.cancelOrder(
                  order.id.toString(),
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande annulée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de l\'annulation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }
}
