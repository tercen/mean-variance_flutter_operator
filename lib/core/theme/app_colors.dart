import 'package:flutter/material.dart';

/// Light theme colors following Tercen style guide
/// Reference: visual-style-light.md
class AppColors {
  AppColors._();

  // Brand colors - Tercen design tokens
  static const Color primary = Color(0xFF1E40AF);  // primary-base (blue-800)
  static const Color primaryDarker = Color(0xFF1E3A8A);  // primary-darker (blue-900)
  static const Color primaryLighter = Color(0xFF2563EB);  // primary-lighter (blue-700)
  static const Color primarySurface = Color(0xFFDBEAFE);  // primary-surface (blue-50)
  static const Color primaryBg = Color(0xFFEFF6FF);  // primary-bg (blue-50 lighter)
  static const Color accent = Color(0xFF1E40AF);
  static const Color link = Color(0xFF1E40AF);  // link-base (same as primary in light mode)
  static const Color textMuted = Color(0xFF6B7280);  // neutral-500

  // Background colors (using neutral palette)
  static const Color background = Color(0xFFFFFFFF);  // white
  static const Color surface = Color(0xFFFFFFFF);  // white
  static const Color surfaceElevated = Color(0xFFF9FAFB);  // neutral-50
  static const Color panelBackground = Color(0xFFF9FAFB);  // neutral-50

  // Text colors (using neutral palette)
  static const Color textPrimary = Color(0xFF111827);  // neutral-900
  static const Color textSecondary = Color(0xFF374151);  // neutral-700
  static const Color textTertiary = Color(0xFF4B5563);  // neutral-600
  static const Color textDisabled = Color(0xFF9CA3AF);  // neutral-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // white

  // Border colors (using neutral palette)
  static const Color border = Color(0xFFD1D5DB);  // neutral-300
  static const Color divider = Color(0xFFE5E7EB);  // neutral-200

  // Mean-Variance specific colors - Error model fit visualization
  static const Color fitLine = Color(0xFFDC2626);  // red-600 for fit line
  static const Color highSignalPoint = Color(0xFF059669);  // green-600
  static const Color lowSignalPoint = Color(0xFF7C3AED);  // violet-600

  // Pane colors for faceted charts (all contrast well with red fit line)
  static const List<Color> paneColors = [
    Color(0xFF377EB8),  // steel blue (ColorBrewer Set1)
    Color(0xFF4DAF4A),  // green (ColorBrewer Set1)
    Color(0xFF984EA3),  // purple (ColorBrewer Set1)
    Color(0xFF1B9E77),  // teal (ColorBrewer Dark2)
    Color(0xFFA65628),  // brown (ColorBrewer Set1)
    Color(0xFF666666),  // grey
    Color(0xFF1F78B4),  // dark blue (ColorBrewer Paired)
    Color(0xFF33A02C),  // forest green (ColorBrewer Paired)
  ];

  // Interactive states
  static const Color hover = Color(0x0A000000);  // 4% black
  static const Color focus = Color(0x33DBEAFE);  // primarySurface with opacity

  // Semantic colors (from Tercen style guide)
  static const Color success = Color(0xFF047857);  // green
  static const Color successLight = Color(0xFFD1FAE5);  // green-light

  static const Color error = Color(0xFFB91C1C);  // red
  static const Color errorLight = Color(0xFFFEE2E2);  // red-light

  static const Color warning = Color(0xFFB45309);  // amber
  static const Color warningLight = Color(0xFFFEF3C7);  // amber-light

  static const Color info = Color(0xFF0E7490);  // teal
  static const Color infoLight = Color(0xFFCFFAFE);  // teal-light
}
