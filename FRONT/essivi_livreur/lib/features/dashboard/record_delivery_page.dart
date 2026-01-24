import 'package:flutter/material.dart';

class RecordDeliveryPage extends StatefulWidget {
  final String tourId;

  const RecordDeliveryPage({
    Key? key,
    required this.tourId,
  }) : super(key: key);

  @override
  State<RecordDeliveryPage> createState() => _RecordDeliveryPageState();
}

class _RecordDeliveryPageState extends State<RecordDeliveryPage> {
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _recordDelivery() async {
    if (_clientNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // API call would go here
      final delivery = {
        'tourId': widget.tourId,
        'clientName': _clientNameController.text,
        'address': _addressController.text,
        'amount': double.parse(_amountController.text),
        'timestamp': DateTime.now().toIso8601String(),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison enregistrée!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, delivery);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer une livraison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du client',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _recordDelivery,
              icon: _isLoading ? const SizedBox() : const Icon(Icons.check),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
