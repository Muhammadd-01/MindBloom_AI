import 'package:flutter/material.dart';

/// Psychology-based color palette for calm, trust, and growth
class AppColors {
  AppColors._();

  // ── Primary Backgrounds (Dark) ──
  static const Color primaryBg = Color(0xFF06080F);      // Deep dark – focus & calm
  static const Color secondaryBg = Color(0xFF0F172A);     // Dark blue-gray – depth

  // ── Primary Backgrounds (Light) ──
  static const Color primaryBgLight = Color(0xFFF8FAFC);  // Near white
  static const Color secondaryBgLight = Color(0xFFF1F5F9); // Very light gray-blue

  // ── Accents ──
  static const Color primaryAccent = Color(0xFF22C55E);   // Green – growth, positivity
  static const Color secondaryAccent = Color(0xFF3B82F6); // Blue – trust, intelligence
  static const Color highlight = Color(0xFFF59E0B);       // Amber – attention, action (CTA)

  // ── Text (Dark Mode) ──
  static const Color textPrimary = Color(0xFFF8FAFC);     // Near white
  static const Color textSecondary = Color(0xFF94A3B8);   // Muted gray

  // ── Text (Light Mode) ──
  static const Color textPrimaryDark = Color(0xFF0F172A);   // Deep navy/black
  static const Color textSecondaryDark = Color(0xFF64748B); // Muted gray-blue

  // ── Indicators ──
  static const Color negative = Color(0xFFEF4444);        // Soft red
  static const Color positive = Color(0xFF10B981);        // Emerald

  // ── Surface / Card (Dark) ──
  static const Color cardBg = Color(0xFF1E293B);
  static const Color cardBgLight = Color(0xFF334155);
  static const Color surfaceLight = Color(0xFF475569);

  // ── Surface / Card (Light) ──
  static const Color cardBgWhite = Colors.white;
  static const Color cardBgLightGray = Color(0xFFE2E8F0);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryAccent, Color(0xFF059669)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryAccent, Color(0xFF6366F1)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [highlight, Color(0xFFF97316)],
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
}
