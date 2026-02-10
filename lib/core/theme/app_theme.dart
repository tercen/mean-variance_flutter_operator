import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_text_styles.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.textOnPrimary,
          onSecondary: AppColors.textOnPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textOnPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.focus,
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.background;
          }),
          checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.textPrimary),
          headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          bodyMedium: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          labelLarge: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          labelMedium: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 20,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColorsDark.primary,
          secondary: AppColorsDark.accent,
          surface: AppColorsDark.surface,
          error: AppColorsDark.error,
          onPrimary: AppColorsDark.textOnPrimary,
          onSecondary: AppColorsDark.textOnPrimary,
          onSurface: AppColorsDark.textPrimary,
          onError: AppColorsDark.textOnPrimary,
        ),
        scaffoldBackgroundColor: AppColorsDark.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColorsDark.surface,
          foregroundColor: AppColorsDark.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColorsDark.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColorsDark.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColorsDark.divider,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColorsDark.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColorsDark.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColorsDark.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
          ),
          labelStyle: AppTextStyles.label.copyWith(color: AppColorsDark.textSecondary),
          hintStyle: AppTextStyles.body.copyWith(color: AppColorsDark.textDisabled),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColorsDark.primary,
          inactiveTrackColor: AppColorsDark.border,
          thumbColor: AppColorsDark.primary,
          overlayColor: AppColorsDark.focus,
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColorsDark.primary;
            }
            return AppColorsDark.background;
          }),
          checkColor: WidgetStateProperty.all(AppColorsDark.textOnPrimary),
          side: const BorderSide(color: AppColorsDark.border, width: 2),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColorsDark.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColorsDark.border),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: AppTextStyles.h1.copyWith(color: AppColorsDark.textPrimary),
          headlineMedium: AppTextStyles.h2.copyWith(color: AppColorsDark.textPrimary),
          headlineSmall: AppTextStyles.h3.copyWith(color: AppColorsDark.textPrimary),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColorsDark.textPrimary),
          bodyMedium: AppTextStyles.body.copyWith(color: AppColorsDark.textPrimary),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColorsDark.textSecondary),
          labelLarge: AppTextStyles.label.copyWith(color: AppColorsDark.textPrimary),
          labelMedium: AppTextStyles.label.copyWith(color: AppColorsDark.textSecondary),
          labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColorsDark.textSecondary),
        ),
        iconTheme: const IconThemeData(
          color: AppColorsDark.textSecondary,
          size: 20,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsDark.primary,
            foregroundColor: AppColorsDark.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColorsDark.primary,
            side: const BorderSide(color: AppColorsDark.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColorsDark.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
}
