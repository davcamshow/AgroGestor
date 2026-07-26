import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Paleta Bovion ---
  static const Color primary = Color(0xFF1B4332);
  static const Color secondary = Color(0xFF52B788);
  static const Color accent = Color(0xFFD4A853);

  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark =
      Color(0xFF1E1E1E); // Gris oscuro elegante para tarjetas

  static const Color success = Color(0xFF10b981);
  static const Color warning = Color(0xFFf59e0b);
  static const Color error = Color(0xFFef4444);
  static const Color info = Color(0xFF3b82f6);

  // --- Gradientes ---
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF40916c)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Tipografía ---
  static TextTheme _buildTextTheme(
      Color mainColor, Color bodyColor, Color mutedColor) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.bold, color: mainColor),
      displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.bold, color: mainColor),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w600, color: mainColor),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600, color: mainColor),
      titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: mainColor),
      titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w500, color: mainColor),
      titleSmall: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: mainColor),
      bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: bodyColor),
      bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor),
      labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600, color: mainColor),
    );
  }

  // --- TEMA CLARO ---
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundLight,
        textTheme: _buildTextTheme(primary, Colors.black87, Colors.black54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          tertiary: accent,
          surface: surfaceLight,
          error: error,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: surfaceLight, // Fondo de tarjeta claro
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: primary,
          textColor: Colors.black87,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade300,
          thickness: 1,
        ),
        inputDecorationTheme: _inputDecoration(
            surfaceLight, const Color(0xFFe0e0e0), secondary, Colors.grey),
        elevatedButtonTheme: _elevatedButton(primary, Colors.white),
        outlinedButtonTheme: _outlinedButton(primary),
        textButtonTheme: _textButton(primary),
        floatingActionButtonTheme: _fabTheme(accent, Colors.white),
        bottomNavigationBarTheme:
            _bottomNavTheme(surfaceLight, primary, Colors.grey),
        chipTheme: _chipTheme(backgroundLight, secondary, Colors.black87),
      );

  // --- TEMA OSCURO ---
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        textTheme: _buildTextTheme(secondary, Colors.white, Colors.white60),
        colorScheme: ColorScheme.fromSeed(
          seedColor: secondary,
          primary: secondary,
          secondary: primary,
          tertiary: accent,
          surface: surfaceDark,
          error: error,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceDark, // Appbar oscura elegante
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color:
              surfaceDark, // Fondo de tarjeta oscuro (Corrige el error de la imagen 1)
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: secondary,
          textColor: Colors.white,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.white12, // Divisores tenues en modo oscuro
          thickness: 1,
        ),
        inputDecorationTheme: _inputDecoration(
            surfaceDark, Colors.white24, secondary, Colors.white60),
        elevatedButtonTheme: _elevatedButton(secondary, backgroundDark),
        outlinedButtonTheme: _outlinedButton(secondary),
        textButtonTheme: _textButton(secondary),
        floatingActionButtonTheme: _fabTheme(accent, Colors.white),
        bottomNavigationBarTheme:
            _bottomNavTheme(surfaceDark, secondary, Colors.white54),
        chipTheme: _chipTheme(surfaceDark, secondary, Colors.white),
      );

  // --- Helpers Internos de UI ---
  static InputDecorationTheme _inputDecoration(
          Color fill, Color border, Color focus, Color hint) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focus, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error)),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: hint),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: hint),
      );

  static ElevatedButtonThemeData _elevatedButton(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 4,
        ),
      );

  static OutlinedButtonThemeData _outlinedButton(Color color) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData _textButton(Color color) => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  static FloatingActionButtonThemeData _fabTheme(Color bg, Color fg) =>
      FloatingActionButtonThemeData(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  static BottomNavigationBarThemeData _bottomNavTheme(
          Color bg, Color selected, Color unselected) =>
      BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: selected,
        unselectedItemColor: unselected,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      );

  static ChipThemeData _chipTheme(Color bg, Color selected, Color text) =>
      ChipThemeData(
        backgroundColor: bg,
        selectedColor: selected,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: text),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: bg)),
      );

  static BoxShadow get softShadow => BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4));
  static BoxShadow get mediumShadow => BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8));
}
