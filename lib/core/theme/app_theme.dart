import 'package:flutter/material.dart';

// ── Quiero Salud design tokens ─────────────────────────────────────────────
//
// Light palette: warm cream background, jade primary, coral error,
//   warm ink typography. Matches the QS design system.
//
// Dark palette:  deep charcoal surfaces, bright jade, vivid coral,
//   warm off-white text.

class AppColors {
  // ── Invariant brand colors ─────────────────────────────────────────────
  static const Color brandJade = Color(0xFF0E8C6A); // qs-jade
  static const Color brandJade600 = Color(0xFF0A7A5C); // qs-jade-600
  static const Color brandJade900 = Color(0xFF073F2E); // qs-jade-900
  static const Color brandTeal = Color(0xFF1F9DA0); // qs-teal (gradient end)
  static const Color brandGradStart = Color(0xFF2EA85E);
  static const Color brandGradEnd = Color(0xFF1F9DA0);

  static const Color coral = Color(0xFFE04D2C); // qs-coral
  static const Color coral50 = Color(0xFFFBE6DF); // qs-coral-50
  static const Color amber = Color(0xFFC8841B); // qs-amber
  static const Color amber50 = Color(0xFFF7ECD3); // qs-amber-50
  static const Color violet = Color(0xFF5B49C9); // qs-violet (asesora accent)
  static const Color violet50 = Color(0xFFECE8FB); // qs-violet-50
  static const Color sky = Color(0xFF1F66C9); // qs-sky
  static const Color sky50 = Color(0xFFE1ECFB); // qs-sky-50

  // ── Light mode ─────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF6F3EC); // qs-bg
  static const Color lightBg2 = Color(0xFFEFEBE0); // qs-bg-warm
  static const Color lightSurface = Color(0xFFFFFFFF); // qs-surface
  static const Color lightSurface2 = Color(0xFFFAF7F0); // qs-surface-2
  static const Color lightInk900 = Color(0xFF14130F); // qs-ink-900
  static const Color lightInk700 = Color(0xFF3A382F); // qs-ink-700
  static const Color lightInk500 = Color(0xFF6D6A5F); // qs-ink-500
  static const Color lightInk400 = Color(0xFF8F8B7E); // qs-ink-400
  static const Color lightInk300 = Color(0xFFC9C5B7); // qs-ink-300
  static const Color lightInk200 = Color(0xFFE5E1D4); // qs-ink-200
  static const Color lightInk100 = Color(0xFFEFECE2); // qs-ink-100
  static const Color lightJade50 = Color(0xFFE6F4EE); // qs-jade-50

  // ── Dark mode ──────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D0E0C);
  static const Color darkBg2 = Color(0xFF16181A);
  static const Color darkSurface = Color(0xFF1B1D1A);
  static const Color darkSurface2 = Color(0xFF22251F);
  static const Color darkInk900 = Color(0xFFF3EFE3);
  static const Color darkInk700 = Color(0xFFC9C5B5);
  static const Color darkInk500 = Color(0xFF8B8678);
  static const Color darkInk400 = Color(0xFF6F6B5E);
  static const Color darkInk300 = Color(0xFF4A4742);
  static const Color darkInk200 = Color(0xFF2E2D27);
  static const Color darkInk100 = Color(0xFF23241F);
  static const Color darkJade = Color(0xFF2EDDA6);
  static const Color darkJade600 = Color(0xFF18C28C);
  static const Color darkJade900 = Color(0xFF0E5040);
  static const Color darkJade50 = Color(0x212EDDA6);
  static const Color darkCoral = Color(0xFFFF8164);
  static const Color darkCoral50 = Color(0x29FF8164);
  static const Color darkAmber = Color(0xFFF0B342);
  static const Color darkAmber50 = Color(0x29F0B342);
  static const Color darkViolet = Color(0xFFA797FF);
  static const Color darkViolet50 = Color(0x2EA797FF);
  static const Color darkSky = Color(0xFF67A8F6);
  static const Color darkSky50 = Color(0x2E67A8F6);

  // ── ColorScheme — light ────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: brandJade, // jade
    onPrimary: Colors.white,
    primaryContainer: lightJade50,
    onPrimaryContainer: brandJade900,
    secondary: brandTeal,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD4F4EC),
    onSecondaryContainer: Color(0xFF073F2E),
    tertiary: violet, // asesora accent
    onTertiary: Colors.white,
    tertiaryContainer: violet50,
    onTertiaryContainer: Color(0xFF2A1D8F),
    error: coral,
    onError: Colors.white,
    errorContainer: coral50,
    onErrorContainer: Color(0xFF7A1A08),
    surface: lightSurface,
    onSurface: lightInk900,
    surfaceContainerHighest: lightSurface2,
    onSurfaceVariant: lightInk500,
    outline: lightInk200,
    outlineVariant: lightInk100,
    shadow: Color(0xFF14130F),
    scrim: Color(0xFF14130F),
    inverseSurface: darkSurface,
    onInverseSurface: darkInk900,
    inversePrimary: darkJade,
  );

  // ── ColorScheme — dark ─────────────────────────────────────────────────
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkJade,
    onPrimary: darkBg,
    primaryContainer: darkJade900,
    onPrimaryContainer: darkInk900,
    secondary: Color(0xFF27D0D4),
    onSecondary: darkBg,
    secondaryContainer: Color(0xFF0E4040),
    onSecondaryContainer: darkInk900,
    tertiary: darkViolet,
    onTertiary: darkBg,
    tertiaryContainer: Color(0xFF2E2060),
    onTertiaryContainer: darkInk900,
    error: darkCoral,
    onError: darkBg,
    errorContainer: Color(0xFF5C1A08),
    onErrorContainer: Color(0xFFFFCDBF),
    surface: darkSurface,
    onSurface: darkInk900,
    surfaceContainerHighest: darkSurface2,
    onSurfaceVariant: darkInk500,
    outline: darkInk300,
    outlineVariant: darkInk200,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: lightSurface,
    onInverseSurface: lightInk900,
    inversePrimary: brandJade,
  );

  // ── Backward-compat aliases (used by legacy screens) ──────────────────
  static const Color background = darkBg;
  static const Color card = darkSurface;
  static const Color cardElevated = darkSurface2;
  static const Color surface = darkSurface;
  static const Color surfaceVariant = darkSurface2;
  static const Color outline = darkInk300;
  static const Color inputFill = darkSurface;
  static const Color inputBorder = darkInk300;
  static const Color primary = darkJade;
  static const Color primaryDark = brandJade;
  static const Color accent = darkJade;
  static const Color accentDark = darkJade600;
  static const Color accentGlow = darkJade50;
  static const Color error = coral;
  static const Color success = brandJade;
  static const Color warning = amber;
  static const Color info = sky;
  static const Color textPrimary = darkInk900;
  static const Color textSecondary = darkInk700;
  static const Color textHint = darkInk500;
  static const Color divider = darkInk200;
  static const Color brandPrimary = brandJade;
  static const Color brandPrimaryDark = brandJade900;
  static const Color brandAccent = brandTeal;

  // ── Light theme ────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackgroundColor: lightBg,
    primaryColor: brandJade,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightInk900,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x0A14130F),
      titleTextStyle: TextStyle(
        color: lightInk900,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.005,
      ),
      iconTheme: IconThemeData(color: lightInk700),
    ),
    cardTheme: const CardThemeData(
      color: lightSurface,
      elevation: 0,
      shadowColor: Color(0x0514130F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: lightInk200),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displaySmall: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.015,
      ),
      headlineLarge: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015,
      ),
      headlineMedium: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      headlineSmall: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
      ),
      titleMedium: TextStyle(color: lightInk900, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: lightInk700),
      bodyLarge: TextStyle(color: lightInk900),
      bodyMedium: TextStyle(color: lightInk700),
      bodySmall: TextStyle(color: lightInk500),
      labelLarge: TextStyle(
        color: lightInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
      ),
      labelMedium: TextStyle(color: lightInk500),
      labelSmall: TextStyle(
        color: lightInk500,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightInk200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightInk200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brandJade, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
      hintStyle: const TextStyle(color: lightInk400),
      labelStyle: const TextStyle(color: lightInk500),
      floatingLabelStyle: const TextStyle(
        color: brandJade,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
      ),
      errorStyle: const TextStyle(color: coral),
      prefixIconColor: lightInk500,
      suffixIconColor: lightInk500,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightInk900,
        foregroundColor: Colors.white,
        disabledBackgroundColor: lightInk900.withAlpha(102),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.005,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightInk900,
        side: const BorderSide(color: lightInk200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: brandJade),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightInk900,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      indicatorColor: lightInk900,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return const IconThemeData(color: lightInk500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: lightInk900,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.005,
          );
        }
        return const TextStyle(color: lightInk500, fontSize: 12.5);
      }),
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x0F14130F),
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: brandJade,
      unselectedItemColor: lightInk400,
      type: BottomNavigationBarType.fixed,
      elevation: 2,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.005,
      ),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    dividerTheme: const DividerThemeData(color: lightInk200, space: 0),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        color: lightInk900,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      contentTextStyle: const TextStyle(color: lightInk500, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: lightInk900,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightJade50,
      labelStyle: const TextStyle(
        color: brandJade,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: const BorderSide(color: Color(0x22073F2E)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: brandJade,
      linearTrackColor: lightInk200,
    ),
    iconTheme: const IconThemeData(color: lightInk500),
    listTileTheme: const ListTileThemeData(
      tileColor: lightSurface,
      textColor: lightInk900,
      iconColor: lightInk500,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  // ── Dark theme ─────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: darkBg,
    primaryColor: darkJade,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkInk900,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x40000000),
      titleTextStyle: TextStyle(
        color: darkInk900,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.005,
      ),
      iconTheme: IconThemeData(color: darkInk700),
    ),
    cardTheme: const CardThemeData(
      color: darkSurface,
      elevation: 0,
      shadowColor: Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: darkInk200),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displayMedium: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.02,
      ),
      displaySmall: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.015,
      ),
      headlineLarge: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015,
      ),
      headlineMedium: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      headlineSmall: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
      ),
      titleMedium: TextStyle(color: darkInk900, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: darkInk700),
      bodyLarge: TextStyle(color: darkInk900),
      bodyMedium: TextStyle(color: darkInk700),
      bodySmall: TextStyle(color: darkInk500),
      labelLarge: TextStyle(
        color: darkInk900,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
      ),
      labelMedium: TextStyle(color: darkInk500),
      labelSmall: TextStyle(
        color: darkInk500,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkInk200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkInk200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkJade, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkCoral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkCoral, width: 1.5),
      ),
      hintStyle: const TextStyle(color: darkInk400),
      labelStyle: const TextStyle(color: darkInk500),
      floatingLabelStyle: const TextStyle(
        color: darkJade,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.08,
      ),
      errorStyle: const TextStyle(color: darkCoral),
      prefixIconColor: darkInk500,
      suffixIconColor: darkInk500,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkJade,
        foregroundColor: darkBg,
        disabledBackgroundColor: darkJade.withAlpha(102),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.005,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkInk900,
        side: const BorderSide(color: darkInk200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkJade),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkJade,
      foregroundColor: darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: darkJade,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF0D0E0C));
        }
        return const IconThemeData(color: darkInk500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: darkJade,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          );
        }
        return const TextStyle(color: darkInk500, fontSize: 12.5);
      }),
      surfaceTintColor: Colors.transparent,
      elevation: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkJade,
      unselectedItemColor: darkInk400,
      type: BottomNavigationBarType.fixed,
      elevation: 2,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.005,
      ),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    dividerTheme: const DividerThemeData(color: darkInk200, space: 0),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        color: darkInk900,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
      ),
      contentTextStyle: const TextStyle(color: darkInk500, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: darkSurface2,
      contentTextStyle: TextStyle(color: darkInk900),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkJade50,
      labelStyle: const TextStyle(
        color: darkJade,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: const BorderSide(color: Color(0x222EDDA6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkJade,
      linearTrackColor: darkInk200,
    ),
    iconTheme: const IconThemeData(color: darkInk500),
    listTileTheme: const ListTileThemeData(
      tileColor: darkSurface,
      textColor: darkInk900,
      iconColor: darkInk500,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
