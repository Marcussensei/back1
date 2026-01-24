import 'package:flutter/material.dart';

class StartTourDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onTourStarted;

  const StartTourDialog({
    Key? key,
    required this.onTourStarted,
  }) : super(key: key);

  @override
  State<StartTourDialog> createState() => _StartTourDialogState();
}

class _StartTourDialogState extends State<StartTourDialog> {
  final TextEditingController _districtController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _startTour() async {
    if (_districtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un district')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tour = {
        'district': _districtController.text,
        'startTime': DateTime.now().toIso8601String(),
      };

      widget.onTourStarted(tour);
      Navigator.pop(context);
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
    return AlertDialog(
      title: const Text('Démarrer une tournée'),
      content: TextField(
        controller: _districtController,
        decoration: const InputDecoration(
          labelText: 'District',
          hintText: 'Ex: Lomé Centre',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startTour,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Démarrer'),
        ),
      ],
    );
  }
}
