import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Top bar for fullscreen mode (when not embedded in Tercen)
/// Following app-frame.md specification
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final badgeBg = isDark ? AppColorsDark.primarySurface : AppColors.primarySurface;
    final badgeText = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Context Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'FULL SCREEN MODE',
              style: AppTextStyles.labelSmall.copyWith(
                color: badgeText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          // Close Button
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () {
              // In a real app, this would call window.close()
              // For the mock, we'll just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Close button pressed (window.close() in production)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}
