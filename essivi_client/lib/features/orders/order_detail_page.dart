import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/orders_provider.dart';
import '../../models/order.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../pages/orders/order_tracking_page.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadOrderDetails(
        widget.orderId.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final order = ordersProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ordersProvider.isLoading
          ? const LoadingIndicator(message: 'Chargement des détails...')
          : ordersProvider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      ordersProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Add logging here
                      debugPrint('🔄 Retry button pressed');
                      debugPrint('📱 Current error: ${ordersProvider.error}');
                      debugPrint('👤 Checking authentication...');
                      debugPrint('🔍 Order ID: ${widget.orderId}');
                      debugPrint('🔄 Tentative de rechargement des détails...');

                      // Show a snackbar to confirm button press
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tentative de rechargement...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      // Try to reload order details
                      context.read<OrdersProvider>().loadOrderDetails(
                        widget.orderId.toString(),
                      );
                      debugPrint('✅ loadOrderDetails() appelée avec succès');
                    },
                    child: const Text('Réessayer'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            )
          : order == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Commande non trouvée'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec numéro de commande et statut
                  _buildOrderHeader(context, order),
                  const SizedBox(height: 24),

                  // Informations de livraison
                  _buildDeliveryInfo(context, order),
                  const SizedBox(height: 24),

                  // Informations du livreur si assigné
                  if (order.agentId != null) ...[
                    _buildDelivererInfo(context, order),
                    const SizedBox(height: 24),
                  ],

                  // Bouton de suivi si commande assignée à un agent
                  if (order.agentId != null &&
                      (order.statut == 'en_cours' ||
                          order.statut == 'confirmee')) ...[
                    _buildTrackingButton(context, order),
                    const SizedBox(height: 24),
                  ],

                  // Articles commandés
                  _buildOrderItems(context, order),
                  const SizedBox(height: 24),

                  // Résumé financier
                  _buildOrderSummary(context, order),
                  const SizedBox(height: 24),

                  // Notes si présentes
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildNotesSection(context, order),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commande #${order.id}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de commande',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                      'fr_FR',
                    ).format(order.dateCommande),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Statut',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.statut).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(order.statut),
                      style: TextStyle(
                        color: _getStatusColor(order.statut),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Text(
                'Informations de livraison',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Adresse de livraison',
            order.adresseLivraison ?? 'Non définie',
          ),
          const SizedBox(height: 12),
          if (order.dateLivraisonPrevue != null)
            _buildDetailRow(
              'Date prévue',
              DateFormat(
                'EEEE d MMMM yyyy',
                'fr_FR',
              ).format(order.dateLivraisonPrevue!),
            ),
          if (order.dateLivraison != null)
            _buildDetailRow(
              'Date de livraison',
              DateFormat(
                'EEEE d MMMM yyyy',
                'fr_FR',
              ).format(order.dateLivraison!),
            ),
        ],
      ),
    );
  }

  Widget _buildDelivererInfo(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green[700]),
              const SizedBox(width: 12),
              Text(
                'Informations du livreur',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nom du livreur', order.agentNom ?? 'Non assigné'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Contacter le livreur',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _callDeliverer(order),
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Appeler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context, Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Articles commandés',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: order.items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Aucun article',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.produitNom ??
                                      'Produit #${item.produitId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantité: ${item.quantite}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.montantTotal.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Montant total', order.montantTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.notes!, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return Colors.blue;
      case 'en_cours':
        return Colors.indigo;
      case 'livree':
        return Colors.green;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statut) {
    switch (statut.toLowerCase()) {
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

  Widget _buildTrackingButton(BuildContext context, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[500]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green[200]!.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToTracking(context, order),
        icon: const Icon(Icons.location_on, color: Colors.white),
        label: const Text(
          'Suivre la livraison',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _navigateToTracking(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingPage(
          orderId: order.id,
          agentId: order.agentId!,
          deliveryAddress: order.adresseLivraison ?? '',
        ),
      ),
    );
  }

  void _callDeliverer(Order order) async {
    if (order.agentTelephone == null || order.agentTelephone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone du livreur non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: order.agentTelephone);
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
}
