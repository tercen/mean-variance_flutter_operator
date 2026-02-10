import 'package:flutter/material.dart';

/// Dark theme colors following Tercen style guide v2.0
/// Reference: Tercen-Dark-Theme.html - February 2026
/// Primary changed from violet to teal for friendlier, more approachable feel
class AppColorsDark {
  AppColorsDark._();

  // Brand colors - Tercen design tokens (teal for dark mode)
  static const Color primary = Color(0xFF14B8A6);  // primary-dark-base (teal-500)
  static const Color primaryHover = Color(0xFF0D9488);  // primary-dark-hover (teal-600)
  static const Color primarySurface = Color(0xFF153D47);  // primary-dark-surface (teal tinted surface)
  static const Color primaryBg = Color(0xFF122E35);  // primary-dark-bg (teal tinted bg)
  static const Color accent = Color(0xFF14B8A6);
  static const Color link = Color(0xFF60A5FA);  // link-dark-base (blue-400, distinct from actions)
  static const Color textMuted = Color(0xFF94A3B8);  // neutral-400 (slate-400)

  // Background colors (slate palette for depth and reduced eye strain)
  static const Color background = Color(0xFF0F172A);  // slate-900
  static const Color surface = Color(0xFF1E293B);  // slate-800
  static const Color surfaceElevated = Color(0xFF334155);  // slate-700
  static const Color panelBackground = Color(0xFF1E293B);  // slate-800

  // Text colors (slate palette)
  static const Color textPrimary = Color(0xFFF8FAFC);  // slate-50
  static const Color textSecondary = Color(0xFFCBD5E1);  // slate-300
  static const Color textDisabled = Color(0xFF64748B);  // slate-500
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // white text on primary colors

  // Border colors (slate palette)
  static const Color border = Color(0xFF334155);  // slate-700
  static const Color divider = Color(0xFF475569);  // slate-600

  // Mean-Variance specific colors - Error model fit visualization (dark optimized)
  static const Color fitLine = Color(0xFFEF4444);  // red-500 (brighter for dark)
  static const Color highSignalPoint = Color(0xFF10B981);  // green-500
  static const Color lowSignalPoint = Color(0xFFA78BFA);  // violet-400

  // Pane colors for faceted charts (dark optimized)
  static const List<Color> paneColors = [
    Color(0xFF60A5FA),  // blue-400
    Color(0xFF10B981),  // green-500
    Color(0xFFFBBF24),  // amber-400
    Color(0xFFA78BFA),  // violet-400
    Color(0xFF06B6D4),  // cyan-500
    Color(0xFFEF4444),  // red-500
    Color(0xFFEC4899),  // pink-500
    Color(0xFF14B8A6),  // teal-500
  ];

  // Interactive states
  static const Color hover = Color(0x0AFFFFFF);
  static const Color focus = Color(0x33122E35);  // primaryBg with opacity

  // Semantic colors (from Tercen Dark Theme v2.0)
  static const Color success = Color(0xFF22C55E);  // green-500
  static const Color successLight = Color(0xFF10B981);  // green-light for dark
  static const Color successBg = Color(0xFF14532D);  // green-900

  static const Color error = Color(0xFFEF4444);  // red-500
  static const Color errorLight = Color(0xFFF87171);  // red-light for dark
  static const Color errorBg = Color(0xFF450A0A);  // custom dark red

  static const Color warning = Color(0xFFF59E0B);  // amber-500
  static const Color warningLight = Color(0xFFFBBF24);  // amber-light for dark
  static const Color warningBg = Color(0xFF451A03);  // amber-950

  static const Color info = Color(0xFF06B6D4);  // cyan-500
  static const Color infoBg = Color(0xFF083344);  // cyan-950
}
