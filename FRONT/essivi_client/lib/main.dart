import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  // Assurer que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de localisation pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);

  runApp(const EssiviClientApp());
}
