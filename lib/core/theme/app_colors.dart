import 'package:flutter/material.dart';

class AppColors {
  // Brand - Minimal Professional Palette
  static const Color primary = Color(0xFF0D7A4F); 
  static const Color accent = Color(0xFF0D7A4F); // Using primary as accent for minimalism
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F4F6); // Lighter gray for alt surfaces

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF); // Lighter gray
  static const Color textHint = Color(0xFF9CA3AF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Semantic
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6); // Standard blue for info

  // Booking status
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusAccepted = Color(0xFF3B82F6);
  static const Color statusActive = Color(0xFF0D7A4F);
  static const Color statusCompleted = Color(0xFF16A34A);
  static const Color statusCancelled = Color(0xFFDC2626);

  // Dark theme
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkSurfaceAlt = Color(0xFF374151);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
}
