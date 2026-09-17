import 'package:flutter/material.dart';

class AppTheme {
  // ── Warm Cream Palette (reference design) ──────────────────────────────────
  static const Color warmCream = Color(0xFFF0E8D8);      // Main background
  static const Color parchment = Color(0xFFE8DCC4);      // Cards, shimmer, input bg
  static const Color dividerBeige = Color(0xFFE0D8C8);   // Subtle list dividers
  static const Color searchFill = Color(0xFFFFFFFF);     // Search / input fill

  // ── Brand / Accent ─────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF8DA399);   // Sage Green
  static const Color sageLight = Color(0xFFB5C9BF);      // Lighter sage tint
  static const Color onlineGreen = Color(0xFF4CAF50);    // Online status dot

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C3E35);    // Bold names
  static const Color textSecondary = Color(0xFF8A9080);  // Preview / timestamps
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Legacy aliases (kept for compatibility) ─────────────────────────────────
  static const Color secondaryColor = parchment;
  static const Color backgroundColor = warmCream;
  static const Color senderBubbleColor = primaryColor;
  static const Color receiverBubbleColor = parchment;
  static const Color errorColor = Color(0xFFE57373);
  static const Color dividerColor = dividerBeige;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: warmCream,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: parchment,
        surface: warmCream,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmCream,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: dividerBeige),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: dividerBeige),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: searchFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : Colors.transparent,
        ),
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : dividerBeige,
        ),
        thumbColor: WidgetStateProperty.all(Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerBeige,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
