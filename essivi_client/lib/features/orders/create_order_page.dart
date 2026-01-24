import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'orders_page.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    // Sur le web, geolocator n'est pas supporté
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La localisation GPS n\'est pas disponible sur la version web. Elle est optionnelle.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isGettingLocation = true);

    try {
      // Demander la permission (mobile uniquement)
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Récupérer la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Position capturée (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final authProvider = context.read<AuthProvider>();

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour commander'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer la commande depuis les items du panier
      await ordersProvider.createOrder(
        items: cartProvider.getOrderItems(),
        deliveryAddress: authProvider.user?.adresse ?? '',
        deliveryDate: _selectedDate?.toIso8601String(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        // Vider le panier après succès
        await cartProvider.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Naviguer vers la page des commandes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrdersPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Commande'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: cartProvider.isLoading
          ? const LoadingIndicator(message: 'Chargement du panier...')
          : cartProvider.items.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: Theme.of(context).primaryColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Finaliser votre commande',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vérifiez les détails et confirmez',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Résumé du panier
                    _buildCartSummary(cartProvider),
                    const SizedBox(height: 24),

                    // Adresse de livraison
                    Text(
                      'Adresse de livraison',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.user?.adresse ??
                                  'Adresse non définie',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date de livraison
                    Text(
                      'Date de livraison',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: _isLoading ? null : () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Sélectionner une date'
                                    : DateFormat(
                                        'EEEE d MMMM yyyy',
                                        'fr_FR',
                                      ).format(_selectedDate!),
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey[500]
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[500],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Livraison estimée: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Instructions spéciales (optionnel)',
                        hintText:
                            'Ex: Livrer à l\'arrière du magasin, sonner 3 fois...',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),

                    // Localisation GPS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Localisation GPS (optionnel)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_latitude != null && _longitude != null)
                                      Text(
                                        'Position: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                        ),
                                      )
                                    else
                                      Text(
                                        'Non capturée',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isGettingLocation || _isLoading
                                  ? null
                                  : _getLocation,
                              icon: _isGettingLocation
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).primaryColor,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.gps_fixed),
                              label: Text(
                                _isGettingLocation
                                    ? 'Capture en cours...'
                                    : 'Capturer ma position',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Résumé final
                    _buildOrderSummary(cartProvider),
                    const SizedBox(height: 32),

                    // Bouton de validation
                    CustomButton(
                      text: 'Confirmer la commande',
                      onPressed: _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des produits avant de commander',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Retour aux produits'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
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
            'Articles commandés',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...cartProvider.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.nom} x${item.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${(item.product.prixUnitaire * item.quantity).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sous-total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${cartProvider.subtotal.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final subtotal = cartProvider.subtotal;
    final shippingFee = 5000.0;
    final tax = subtotal * 0.18;
    final total = subtotal + shippingFee + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de la commande',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Sous-total', subtotal),
          _buildSummaryRow('Frais de livraison', shippingFee),
          _buildSummaryRow('Taxe (18%)', tax),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            total,
            isBold: true,
            color: Theme.of(context).primaryColor,
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Livraison: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
