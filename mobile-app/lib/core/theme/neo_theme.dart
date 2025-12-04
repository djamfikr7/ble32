import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme mode provider for dark/light mode switching
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Premium Neomorphism color palette
class NeoColors {
  // Light mode colors (soft blue-gray)
  static const lightBackground = Color(0xFFE4EBF5);
  static const lightSurface = Color(0xFFE4EBF5);
  static const lightShadowDark = Color(0xFFA3B1C6);
  static const lightShadowLight = Color(0xFFFFFFFF);

  // Dark mode colors - PREMIUM DARK with deeper contrasts
  static const darkBackground = Color(0xFF1E1E2E);
  static const darkSurface = Color(0xFF252536);
  static const darkShadowDark = Color(0xFF13131D);
  static const darkShadowLight = Color(0xFF32324A);

  // Primary gradient (Pink/Coral)
  static const primaryGradient = [Color(0xFFEC407A), Color(0xFFD81B60)];

  // Accent gradients
  static const successGradient = [Color(0xFF4CAF50), Color(0xFF2E7D32)];
  static const warningGradient = [Color(0xFFFFB74D), Color(0xFFF57C00)];
  static const errorGradient = [Color(0xFFEF5350), Color(0xFFD32F2F)];
  static const tealGradient = [Color(0xFF26C6DA), Color(0xFF00ACC1)];
  static const blueGradient = [Color(0xFF42A5F5), Color(0xFF1E88E5)];
  static const purpleGradient = [Color(0xFF7E57C2), Color(0xFF5E35B1)];
  static const goldGradient = [Color(0xFFFFD54F), Color(0xFFFFB300)];
  static const cyanGradient = [Color(0xFF00E5FF), Color(0xFF00B8D4)];

  // State colors
  static const stable = Color(0xFF4CAF50);
  static const unstable = Color(0xFFFFB74D);
  static const error = Color(0xFFEF5350);
  static const connected = Color(0xFF4CAF50);
  static const disconnected = Color(0xFF757575);

  // Text colors
  static const textPrimary = Color(0xFF2D3142);
  static const textSecondary = Color(0xFF8E99A4);
  static const textDark = Color(0xFFFFFFFF);
  static const textDarkSecondary = Color(0xFF9BA4B4);

  // Badge colors
  static const badgeGold = Color(0xFFFFB300);
  static const badgeSilver = Color(0xFF90A4AE);
  static const badgePlatinum = Color(0xFF7E57C2);
  static const badgeBronze = Color(0xFF8D6E63);
  static const badgeSuccess = Color(0xFF4CAF50);
}

/// Neomorphism decoration helpers
class NeoDecoration {
  /// Raised/convex surface
  static BoxDecoration raised({
    required bool isDark,
    double borderRadius = 20,
    Color? color,
    double intensity = 1.0,
  }) {
    final bgColor =
        color ?? (isDark ? const Color(0xFF252536) : NeoColors.lightSurface);
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: (isDark ? 0.7 : 0.5) * intensity),
          offset: Offset(6 * intensity, 6 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 1,
        ),
        BoxShadow(
          color:
              shadowLight.withValues(alpha: (isDark ? 0.06 : 0.85) * intensity),
          offset: Offset(-6 * intensity, -6 * intensity),
          blurRadius: 16 * intensity,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Inset/concave surface
  static BoxDecoration inset({
    required bool isDark,
    double borderRadius = 15,
    Color? color,
  }) {
    final bgColor =
        color ?? (isDark ? const Color(0xFF1E1E2E) : NeoColors.lightSurface);
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.5 : 0.35),
          offset: const Offset(4, 4),
          blurRadius: 8,
        ),
      ],
      border: Border.all(
        color: shadowDark.withValues(alpha: isDark ? 0.3 : 0.15),
        width: 1,
      ),
    );
  }

  /// Gradient button
  static BoxDecoration gradientButton({
    List<Color>? colors,
    double borderRadius = 16,
  }) {
    final gradientColors = colors ?? NeoColors.primaryGradient;

    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: gradientColors.last.withValues(alpha: 0.45),
          offset: const Offset(0, 5),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// LCD Display style
  static BoxDecoration lcdDisplay({
    required bool isDark,
    double borderRadius = 12,
  }) {
    final lcdBg = isDark ? const Color(0xFF161622) : const Color(0xFFD4E8D4);
    final lcdBorder =
        isDark ? const Color(0xFF2A2A3A) : const Color(0xFFB0C8B0);

    return BoxDecoration(
      color: lcdBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: lcdBorder, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// Circular gauge container
  static BoxDecoration circularGauge({required bool isDark}) {
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final shadowLight =
        isDark ? const Color(0xFF32324A) : NeoColors.lightShadowLight;
    final bgColor = isDark ? const Color(0xFF252536) : NeoColors.lightSurface;

    return BoxDecoration(
      shape: BoxShape.circle,
      color: bgColor,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: isDark ? 0.75 : 0.5),
          offset: const Offset(10, 10),
          blurRadius: 25,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: isDark ? 0.08 : 0.9),
          offset: const Offset(-10, -10),
          blurRadius: 25,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Inner circle for gauges
  static BoxDecoration circularInset({required bool isDark}) {
    final shadowDark =
        isDark ? const Color(0xFF13131D) : NeoColors.lightShadowDark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : NeoColors.lightSurface;

    return BoxDecoration(
      shape: BoxShape.circle,
      color: bgColor,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: 0.4),
          offset: const Offset(5, 5),
          blurRadius: 12,
          spreadRadius: -3,
        ),
      ],
    );
  }
}

/// Main theme class
class NeoTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NeoColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: NeoColors.primaryGradient[0],
        secondary: NeoColors.tealGradient[0],
        surface: NeoColors.lightSurface,
        onSurface: NeoColors.textPrimary,
        error: NeoColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
            color: NeoColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(
            color: NeoColors.textPrimary, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.poppins(
            color: NeoColors.textPrimary, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.poppins(
            color: NeoColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(
            color: NeoColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: NeoColors.textPrimary),
        bodyMedium: GoogleFonts.poppins(color: NeoColors.textSecondary),
        labelLarge: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NeoColors.lightBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: NeoColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: NeoColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: NeoColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoColors.lightSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoColors.primaryGradient[0],
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeoColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: NeoColors.primaryGradient[0],
        secondary: NeoColors.tealGradient[0],
        surface: NeoColors.darkSurface,
        onSurface: NeoColors.textDark,
        error: NeoColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
            color: NeoColors.textDark, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(
            color: NeoColors.textDark, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.poppins(
            color: NeoColors.textDark, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.poppins(
            color: NeoColors.textDark, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(
            color: NeoColors.textDark, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: NeoColors.textDark),
        bodyMedium: GoogleFonts.poppins(color: NeoColors.textDarkSecondary),
        labelLarge: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NeoColors.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: NeoColors.textDark),
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: NeoColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: NeoColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoColors.darkSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeoColors.primaryGradient[0],
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
