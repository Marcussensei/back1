import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classe pour les couleurs personnalisées de l'app ESSIVIVI
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF2E7D32); // Vert ESSIVIVI
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);

  // Couleurs secondaires
  static const Color accent = Color(0xFFFF6F00);
  static const Color accentLight = Color(0xFFFFB74D);

  // Couleurs neutres
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);

  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFf44336);
  static const Color info = Color(0xFF2196F3);

  // Couleurs de statut livraisom
  static const Color statusPending = Color(0xFFFFA500); // Orange
  static const Color statusInProgress = Color(0xFF2196F3); // Bleu
  static const Color statusCompleted = Color(0xFF4CAF50); // Vert
  static const Color statusCancelled = Color(0xFFf44336); // Rouge
  static const Color statusOnLeave = Color(0xFF9C27B0); // Pourpre
}

/// Classe pour les espacements personnalisés
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Classe pour les rayons de border
class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 100.0;
}

/// Classe pour les ombres
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Colors.black12,
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Colors.black12,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow lg = BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow xl = BoxShadow(
    color: Colors.black12,
    blurRadius: 12,
    offset: Offset(0, 6),
  );
}

/// Thème clair pour l'app
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.black,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.grey600,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.grey600,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.grey600,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      shadowColor: AppColors.black.withOpacity(0.1),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.grey500,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.grey700,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey500,
      elevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.grey200,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.white),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return AppColors.grey300;
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
    ),
  );
}

/// Extensions pour les styles communs
extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  bool get isMobile => mediaQuery.size.width < 600;
  bool get isTablet =>
      mediaQuery.size.width >= 600 && mediaQuery.size.width < 1200;
  bool get isDesktop => mediaQuery.size.width >= 1200;
}
