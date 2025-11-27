import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightModeColors {
  static const lightPrimary = Color(0xFF8B5CF6);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFF3E8FF);
  static const lightOnPrimaryContainer = Color(0xFF3B0764);
  static const lightSecondary = Color(0xFF06B6D4);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFFFBBF24);
  static const lightOnTertiary = Color(0xFF1F1F1F);
  static const lightError = Color(0xFFEF4444);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFE4E6);
  static const lightOnErrorContainer = Color(0xFF7F1D1D);
  static const lightInversePrimary = Color(0xFFA78BFA);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightOnSurface = Color(0xFF1F1F1F);
  static const lightAppBarBackground = Color(0xFF8B5CF6);
  static const lightOnAppBar = Color(0xFFFFFFFF);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFFA78BFA);
  static const darkOnPrimary = Color(0xFF3B0764);
  static const darkPrimaryContainer = Color(0xFF6D28D9);
  static const darkOnPrimaryContainer = Color(0xFFF3E8FF);
  static const darkSecondary = Color(0xFF22D3EE);
  static const darkOnSecondary = Color(0xFF083344);
  static const darkTertiary = Color(0xFFFCD34D);
  static const darkOnTertiary = Color(0xFF78350F);
  static const darkError = Color(0xFFF87171);
  static const darkOnError = Color(0xFF7F1D1D);
  static const darkErrorContainer = Color(0xFFDC2626);
  static const darkOnErrorContainer = Color(0xFFFFE4E6);
  static const darkInversePrimary = Color(0xFF8B5CF6);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF0F172A);
  static const darkOnSurface = Color(0xFFF1F5F9);
  static const darkAppBarBackground = Color(0xFF1E293B);
  static const darkOnAppBar = Color(0xFFF1F5F9);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnAppBar,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: LightModeColors.lightOnAppBar),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightModeColors.lightPrimary,
      foregroundColor: LightModeColors.lightOnPrimary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LightModeColors.lightPrimary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: LightModeColors.lightPrimary, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LightModeColors.lightPrimaryContainer,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: LightModeColors.lightSecondary,
    foregroundColor: LightModeColors.lightOnSecondary,
    elevation: 4,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnAppBar,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: DarkModeColors.darkOnAppBar),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkModeColors.darkPrimary,
      foregroundColor: DarkModeColors.darkOnPrimary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DarkModeColors.darkPrimary,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: DarkModeColors.darkPrimary, width: 2),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkPrimaryContainer,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: DarkModeColors.darkSecondary,
    foregroundColor: DarkModeColors.darkOnSecondary,
    elevation: 4,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
