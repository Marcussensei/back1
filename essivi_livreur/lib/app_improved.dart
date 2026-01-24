import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/improved_dashboard.dart';
import 'core/services/auth_service.dart';

/// Application principale ESSIVI Livreur
/// Améliorations: UI moderne, Dashboard, Routing, Validation livraison
class EssiviApp extends StatelessWidget {
  const EssiviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESSIVI Livreur',
      theme: _buildTheme(),
      home: const AppInitializer(),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: const Color(0xFF00458A),
      scaffoldBackgroundColor: const Color(0xFFF2F8FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00458A),
        secondary: Color(0xFFCCE5FF),
        surface: Colors.white,
        error: Color(0xFFF44336),
        onSurface: Color(0xFF333333),
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00458A),
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00458A),
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00458A),
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF00458A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00458A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00458A),
          side: const BorderSide(color: Color(0xFF00458A)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF00458A),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF44336)),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: const Color(0xFF999999),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔄 AppInitializer._initialize START');
      print('═══════════════════════════════════════════════════════════');
      // Vérifier si l'utilisateur est authentifié
      final isAuthenticated = await AuthService.isAuthenticated();
      print('✓ isAuthenticated: $isAuthenticated');

      if (isAuthenticated) {
        // Restaurer le token depuis SharedPreferences vers ApiService
        print('🔄 Restauration du token...');
        await AuthService.restoreSession();
        print('✅ Token restauré');
      }

      setState(() {
        _isAuthenticated = isAuthenticated;
        _isInitialized = true;
        print('✅ Init terminée');
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      setState(() {
        _isInitialized = true;
        _isAuthenticated = false;
      });
    }
  }

  void _handleLoginSuccess() {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('🎯 _handleLoginSuccess CALLED');
    print('═══════════════════════════════════════════════════════════');
    // S'assurer que le token est restauré dans ApiService
    AuthService.restoreSession().then((restored) {
      print('✅ restoreSession returned: $restored');
      setState(() {
        _isAuthenticated = true;
        print('✅ _isAuthenticated = true, rebuilding...');
      });
    }).catchError((error) {
      print('❌ ERROR in restoreSession: $error');
    });
  }

  void _handleLogout() {
    print('[DEBUG] Logout');
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      return ImprovedDeliveryDashboard(
        onLogout: _handleLogout,
      );
    }

    return LivreurLoginPage(
      onLoginSuccess: _handleLoginSuccess,
    );
  }
}
