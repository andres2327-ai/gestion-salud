import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (invariantes)
  static const Color brandPrimary = Color(0xFF057661);
  static const Color brandPrimaryDark = Color(0xFF033F3F);
  static const Color brandAccent = Color(0xFF0ABFA3);

  // Status colors (invariantes)
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Colores modo oscuro ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0ABFA3);
  static const Color primaryDark = Color(0xFF057661);
  static const Color accent = Color(0xFF10B981);
  static const Color accentDark = Color(0xFF059669);
  static const Color accentGlow = Color(0x2610B981);

  static const Color textPrimary = Color(0xFFEFF6FF);
  static const Color textSecondary = Color(0xFFADB8D1);
  static const Color textHint = Color(0xFF7C8FA3);

  static const Color background = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color cardElevated = Color(0xFF334155);
  static const Color divider = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color outline = Color(0xFF475569);
  static const Color inputBorder = Color(0xFF475569);
  static const Color inputFill = Color(0xFF1E293B);

  // ── ColorScheme oscuro ─────────────────────────────────────────────────────
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF0ABFA3),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF057661),
    onPrimaryContainer: Color(0xFFEFF6FF),
    secondary: Color(0xFF10B981),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF059669),
    onSecondaryContainer: Color(0xFFEFF6FF),
    tertiary: Color(0xFF3B82F6),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF1E40AF),
    onTertiaryContainer: Color(0xFFEFF6FF),
    error: Color(0xFFEF4444),
    onError: Colors.white,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF1E293B),
    onSurface: Color(0xFFEFF6FF),
    surfaceContainerHighest: Color(0xFF334155),
    onSurfaceVariant: Color(0xFFADB8D1),
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFEFF6FF),
    onInverseSurface: Color(0xFF0F172A),
    inversePrimary: Color(0xFF057661),
  );

  // ── ColorScheme claro ──────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF057661),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFB2DFDB),
    onPrimaryContainer: Color(0xFF033F3F),
    secondary: Color(0xFF059669),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFC8E6C9),
    onSecondaryContainer: Color(0xFF1B5E20),
    tertiary: Color(0xFF1976D2),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFBBDEFB),
    onTertiaryContainer: Color(0xFF0D47A1),
    error: Color(0xFFB00020),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFF8FFFE),
    onSurface: Color(0xFF1A1A1A),
    surfaceContainerHighest: Color(0xFFE0F2F1),
    onSurfaceVariant: Color(0xFF4A5568),
    outline: Color(0xFF9CB3B0),
    outlineVariant: Color(0xFFCCE0DE),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFEFF6FF),
    inversePrimary: Color(0xFF0ABFA3),
  );

  // ── Tema oscuro ────────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textPrimary),
      titleSmall: TextStyle(color: textSecondary),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textHint),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textSecondary),
      labelSmall: TextStyle(color: textHint),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      hintStyle: const TextStyle(color: textHint),
      labelStyle: const TextStyle(color: textSecondary),
      errorStyle: const TextStyle(color: error),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Color(0xFF0ABFA3).withAlpha(153),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: Color(0xFF0ABFA3),
      unselectedItemColor: textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(color: surfaceVariant),
    dialogTheme: const DialogThemeData(
      backgroundColor: card,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: cardElevated,
      contentTextStyle: TextStyle(color: textPrimary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariant,
      labelStyle: const TextStyle(color: textPrimary),
      side: const BorderSide(color: outline),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    iconTheme: const IconThemeData(color: textSecondary),
  );

  // ── Tema claro ─────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: const Color(0xFFF0FAFA),
    primaryColor: brandPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF057661),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Color(0x1A057661),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF2D2D2D)),
      titleSmall: TextStyle(color: Color(0xFF4A5568)),
      bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF4A5568)),
      bodySmall: TextStyle(color: Color(0xFF718096)),
      labelLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Color(0xFF4A5568)),
      labelSmall: TextStyle(color: Color(0xFF718096)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9CB3B0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9CB3B0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF057661), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB00020)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB00020), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CB3B0)),
      labelStyle: const TextStyle(color: Color(0xFF4A5568)),
      errorStyle: const TextStyle(color: Color(0xFFB00020)),
      prefixIconColor: Color(0xFF4A5568),
      suffixIconColor: Color(0xFF4A5568),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF057661),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Color(0xFF057661).withAlpha(153),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF057661),
        side: const BorderSide(color: Color(0xFF057661)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF057661)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF057661),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF057661),
      unselectedItemColor: Color(0xFF9CB3B0),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE0F2F1)),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: Color(0xFF4A5568), fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE0F2F1),
      labelStyle: const TextStyle(color: Color(0xFF033F3F)),
      side: const BorderSide(color: Color(0xFF9CB3B0)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF057661),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF4A5568)),
  );
}
