import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/theme_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/products_provider.dart';
import 'core/providers/orders_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

class EssiviClientApp extends StatelessWidget {
  const EssiviClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ESSIVI Client',
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: ThemeMode.light,
            // Configuration de la localisation
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'), // Français
              Locale('en', 'US'), // Anglais
            ],
            locale: const Locale('fr', 'FR'), // Locale par défaut
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

/// Widget pour initialiser l'application
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    // Initialiser l'authentification
    await authProvider.initialize();

    // Initialiser le panier
    await cartProvider.initialize();

    // Si authentifié, charger les données
    if (authProvider.isAuthenticated) {
      final productsProvider = context.read<ProductsProvider>();
      final ordersProvider = context.read<OrdersProvider>();

      await Future.wait([
        productsProvider.loadProducts(),
        ordersProvider.loadOrders(),
      ]);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const DashboardPage();
    }

    return const LoginPage();
  }
}
