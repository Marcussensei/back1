import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/login_page.dart';

class EssiviApp extends StatelessWidget {
  const EssiviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESSIVI Livreur',
      theme: ThemeData(
        primaryColor: const Color(0xFF00458A), // Primary blue
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00458A),
          secondary: Color(0xFFCCE5FF),
          surface: Colors.white,
          onSurface: Color(0xFFF2F8FF),
        ),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      home: const LivreurLoginPage(),
    );
  }
}
