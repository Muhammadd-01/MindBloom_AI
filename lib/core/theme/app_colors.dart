import 'package:flutter/material.dart';

/// Psychology-based color palette for calm, trust, and growth (Nature & Bloom Theme)
class AppColors {
  AppColors._();

  // ── Primary Backgrounds (Dark) ──
  static const Color primaryBg = Color(0xFF041810);      // Very deep forest green
  static const Color secondaryBg = Color(0xFF082B1D);     // Deep nature green

  // ── Primary Backgrounds (Light) ──
  static const Color primaryBgLight = Color(0xFFF0FDF4);  // Very light, airy mint/green
  static const Color secondaryBgLight = Color(0xFFDCFCE7); // Soft light green (Green 100)

  // ── Accents ──
  static const Color primaryAccent = Color(0xFF34D399);   // Soft but vibrant green – growth, bloom
  static const Color secondaryAccent = Color(0xFF2DD4BF); // Soft Teal – clarity, mind
  static const Color highlight = Color(0xFFF472B6);       // Pink (Bloom) – warmth, creativity

  // ── Text (Dark Mode) ──
  static const Color textPrimary = Color(0xFFF0FDF4);     // Light mint
  static const Color textSecondary = Color(0xFFA7F3D0);   // Muted bright green

  // ── Text (Light Mode) ──
  static const Color textPrimaryDark = Color(0xFF022C22);   // Darkest forest green
  static const Color textSecondaryDark = Color(0xFF065F46); // Medium forest green

  // ── Indicators ──
  static const Color negative = Color(0xFFF43F5E);        // Soft rose
  static const Color positive = Color(0xFF10B981);        // Emerald

  // ── Surface / Card (Dark) ──
  static const Color cardBg = Color(0xFF064E3B);
  static const Color cardBgLight = Color(0xFF047857);
  static const Color surfaceLight = Color(0xFF059669);

  // ── Surface / Card (Light) ──
  static const Color cardBgWhite = Colors.white;
  static const Color cardBgLightGray = Color(0xFFD1FAE5);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryAccent, Color(0xFF059669)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryAccent, Color(0xFF0D9488)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [highlight, Color(0xFFEC4899)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondaryBg, primaryBg],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondaryBgLight, primaryBgLight],
  );

  // ── Glassmorphism ──
  static Color glassWhite = Colors.white.withValues(alpha: 0.08);
  static Color glassBlack = Colors.black.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.12);
  static Color glassBorderDark = Colors.black.withValues(alpha: 0.08);

  // ── More Gradients ──
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  );

  static const LinearGradient roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12241A), Color(0xFF1B3023), Color(0xFF2C4A36)],
  );

  // ── Glass Decorations ──
  static BoxDecoration glassDecoration({required bool isDarkMode, double blur = 10, double opacity = 0.08}) {
    return BoxDecoration(
      color: isDarkMode ? Colors.white.withValues(alpha: opacity) : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDarkMode ? glassBorder : glassBorderDark),
    );
  }
}
