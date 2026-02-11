import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/theme_provider.dart';
import 'common/labeled_checkbox.dart';
import 'common/compact_number_field.dart';

/// Left panel following Tercen left-panel.md pattern with volcano structure
class LeftPanel extends StatefulWidget {
  // DISPLAY section
  final String chartTitle;
  final ValueChanged<String> onChartTitleChanged;
  final String plotType;
  final ValueChanged<String> onPlotTypeChanged;
  final bool showModelFit;
  final ValueChanged<bool> onShowModelFitChanged;
  final bool combineGroups;
  final ValueChanged<bool> onCombineGroupsChanged;

  // AXES section (nullable = auto)
  final bool logXAxis;
  final ValueChanged<bool> onLogXAxisChanged;
  final bool xMinAuto;
  final ValueChanged<bool> onXMinAutoChanged;
  final double xMin;
  final ValueChanged<double> onXMinChanged;
  final bool xMaxAuto;
  final ValueChanged<bool> onXMaxAutoChanged;
  final double xMax;
  final ValueChanged<double> onXMaxChanged;
  final bool yMinAuto;
  final ValueChanged<bool> onYMinAutoChanged;
  final double yMin;
  final ValueChanged<double> onYMinChanged;
  final bool yMaxAuto;
  final ValueChanged<bool> onYMaxAutoChanged;
  final double yMax;
  final ValueChanged<double> onYMaxChanged;

  // MODEL FITTING section
  final double highSignalThreshold;
  final ValueChanged<double> onHighSignalThresholdChanged;
  final double lowSignalThreshold;
  final ValueChanged<double> onLowSignalThresholdChanged;

  // EXPORT section
  final int exportWidth;
  final ValueChanged<int> onExportWidthChanged;
  final int exportHeight;
  final ValueChanged<int> onExportHeightChanged;
  final VoidCallback? onExportPng;
  final VoidCallback? onExportPdf;

  // Panel state
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const LeftPanel({
    super.key,
    required this.chartTitle,
    required this.onChartTitleChanged,
    required this.plotType,
    required this.onPlotTypeChanged,
    required this.showModelFit,
    required this.onShowModelFitChanged,
    required this.combineGroups,
    required this.onCombineGroupsChanged,
    required this.logXAxis,
    required this.onLogXAxisChanged,
    required this.xMinAuto,
    required this.onXMinAutoChanged,
    required this.xMin,
    required this.onXMinChanged,
    required this.xMaxAuto,
    required this.onXMaxAutoChanged,
    required this.xMax,
    required this.onXMaxChanged,
    required this.yMinAuto,
    required this.onYMinAutoChanged,
    required this.yMin,
    required this.onYMinChanged,
    required this.yMaxAuto,
    required this.onYMaxAutoChanged,
    required this.yMax,
    required this.onYMaxChanged,
    required this.highSignalThreshold,
    required this.onHighSignalThresholdChanged,
    required this.lowSignalThreshold,
    required this.onLowSignalThresholdChanged,
    required this.exportWidth,
    required this.onExportWidthChanged,
    required this.exportHeight,
    required this.onExportHeightChanged,
    this.onExportPng,
    this.onExportPdf,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  double _panelWidth = AppSpacing.panelWidth; // Local state - only rebuilds LeftPanel
  bool _isHoveringResizeHandle = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColorsDark.panelBackground : AppColors.panelBackground;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main panel container - instant width updates for drag, animate only for collapse
        Container(
          width: widget.isCollapsed ? AppSpacing.panelCollapsedWidth : _panelWidth,
          decoration: BoxDecoration(
            color: panelColor,
            border: Border(
              right: BorderSide(color: borderColor),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark),

              // Content area - use LayoutBuilder to detect actual width during animation
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Show collapsed view if actual width is less than minimum needed for expanded content
                    final showCollapsedView = constraints.maxWidth < 200;

                    if (showCollapsedView) {
                      return _buildCollapsedIconStrip(context);
                    }
                    return _buildExpandedContent(context);
                  },
                ),
              ),

              // Footer with chevron (only when collapsed)
              if (widget.isCollapsed) _buildCollapsedFooter(context, isDark),
            ],
          ),
        ),

        // Resize handle (only when expanded)
        if (!widget.isCollapsed) _buildResizeHandle(isDark),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final themeProvider = context.watch<ThemeProvider>();
    final headerColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      color: headerColor,
      // Collapsed: no padding, centered. Expanded: horizontal padding
      padding: widget.isCollapsed
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        // Collapsed: center the icon. Expanded: default start alignment
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          // App Icon (always visible)
          const Icon(Icons.show_chart, color: Colors.white, size: 20),

          // Everything else hidden when collapsed
          if (!widget.isCollapsed) ...[
            const SizedBox(width: AppSpacing.sm),
            // App Title
            const Expanded(
              child: Text(
                'Mean-Variance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Theme Toggle
            IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: Colors.white,
                size: 20,
              ),
              onPressed: themeProvider.toggleTheme,
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // Collapse Chevron
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
              onPressed: widget.onToggleCollapse,
              tooltip: 'Collapse panel',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedIconStrip(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 8), // Small top padding
          IconButton(
            icon: const Icon(Icons.visibility, size: 20),
            onPressed: widget.onToggleCollapse,
            tooltip: 'DISPLAY',
          ),
          IconButton(
            icon: const Icon(Icons.straighten, size: 20),
            onPressed: widget.onToggleCollapse,
            tooltip: 'AXES',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart, size: 20),
            onPressed: widget.onToggleCollapse,
            tooltip: 'MODEL FITTING',
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: widget.onToggleCollapse,
            tooltip: 'EXPORT',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: widget.onToggleCollapse,
            tooltip: 'INFO',
          ),
        ],
    );
  }

  Widget _buildCollapsedFooter(BuildContext context, bool isDark) {
    final headerColor = isDark ? AppColorsDark.primary : AppColors.primary;

    return Container(
      height: AppSpacing.headerHeight,
      color: headerColor,
      child: Center(
        child: IconButton(
          icon: const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 24,
          ),
          onPressed: widget.onToggleCollapse,
          tooltip: 'Expand panel',
        ),
      ),
    );
  }

  Widget _buildResizeHandle(bool isDark) {
    final accentColor = isDark ? AppColorsDark.accent : AppColors.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHoveringResizeHandle = true),
      onExit: (_) => setState(() => _isHoveringResizeHandle = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final newWidth = _panelWidth + details.delta.dx;
            _panelWidth = newWidth.clamp(
              AppSpacing.panelMinWidth,
              AppSpacing.panelMaxWidth,
            );
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 4,
          color: _isHoveringResizeHandle
              ? accentColor.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildDisplaySection(context),
        _buildAxesSection(context),
        _buildModelFittingSection(context),
        _buildExportSection(context),
        _buildInfoSection(context),
      ],
    );
  }

  Widget _buildDisplaySection(BuildContext context) {
    return _buildSection(
      context,
      icon: Icons.visibility,
      label: 'DISPLAY',
      children: [
        // Chart title input
        _buildLabel(context, 'Chart title'),
        const SizedBox(height: 4),
        SizedBox(
          height: 28,
          child: TextField(
            controller: TextEditingController(text: widget.chartTitle)
              ..selection = TextSelection.collapsed(offset: widget.chartTitle.length),
            decoration: const InputDecoration(
              hintText: 'Enter title (optional)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: widget.onChartTitleChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Plot type selector
        _buildLabel(context, 'Plot type'),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'CV', label: Text('CV', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 'SNR', label: Text('SNR', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 'SD', label: Text('SD', style: TextStyle(fontSize: 12))),
          ],
          selected: {widget.plotType},
          onSelectionChanged: (Set<String> newSelection) {
            widget.onPlotTypeChanged(newSelection.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Checkboxes
        LabeledCheckbox(
          label: 'Show model fit',
          value: widget.showModelFit,
          onChanged: widget.onShowModelFitChanged,
        ),
        LabeledCheckbox(
          label: 'Combine all groups',
          value: widget.combineGroups,
          onChanged: widget.onCombineGroupsChanged,
        ),
      ],
    );
  }

  Widget _buildAxesSection(BuildContext context) {
    return _buildSection(
      context,
      icon: Icons.straighten,
      label: 'AXES',
      children: [
        // Log x-axis checkbox
        LabeledCheckbox(
          label: 'Log x-axis',
          value: widget.logXAxis,
          onChanged: widget.onLogXAxisChanged,
        ),
        const SizedBox(height: AppSpacing.sm),

        // X-axis limits
        _buildSubLabel(context, 'X-AXIS LIMITS'),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(width: 36, child: _buildLabel(context, 'Min')),
            const SizedBox(width: 4),
            Expanded(
              child: CompactNumberField(
                value: widget.xMinAuto ? null : widget.xMin,
                hint: 'auto',
                onChanged: (val) {
                  if (val == null) {
                    widget.onXMinAutoChanged(true);
                  } else {
                    widget.onXMinAutoChanged(false);
                    widget.onXMinChanged(val);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 36, child: _buildLabel(context, 'Max')),
            const SizedBox(width: 4),
            Expanded(
              child: CompactNumberField(
                value: widget.xMaxAuto ? null : widget.xMax,
                hint: 'auto',
                onChanged: (val) {
                  if (val == null) {
                    widget.onXMaxAutoChanged(true);
                  } else {
                    widget.onXMaxAutoChanged(false);
                    widget.onXMaxChanged(val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Y-axis limits
        _buildSubLabel(context, 'Y-AXIS LIMITS'),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(width: 36, child: _buildLabel(context, 'Min')),
            const SizedBox(width: 4),
            Expanded(
              child: CompactNumberField(
                value: widget.yMinAuto ? null : widget.yMin,
                hint: 'auto',
                onChanged: (val) {
                  if (val == null) {
                    widget.onYMinAutoChanged(true);
                  } else {
                    widget.onYMinAutoChanged(false);
                    widget.onYMinChanged(val);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 36, child: _buildLabel(context, 'Max')),
            const SizedBox(width: 4),
            Expanded(
              child: CompactNumberField(
                value: widget.yMaxAuto ? null : widget.yMax,
                hint: 'auto',
                onChanged: (val) {
                  if (val == null) {
                    widget.onYMaxAutoChanged(true);
                  } else {
                    widget.onYMaxAutoChanged(false);
                    widget.onYMaxChanged(val);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelFittingSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return _buildSection(
      context,
      icon: Icons.show_chart,
      label: 'MODEL FITTING',
      children: [
        // High signal threshold
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(context, 'High signal'),
            Text(
              '${(widget.highSignalThreshold * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.label.copyWith(color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: widget.highSignalThreshold,
            min: 0.80,
            max: 1.00,
            divisions: 20,
            onChanged: widget.onHighSignalThresholdChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Low signal threshold
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel(context, 'Low signal'),
            Text(
              '${(widget.lowSignalThreshold * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.label.copyWith(color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: widget.lowSignalThreshold,
            min: 0.00,
            max: 0.20,
            divisions: 20,
            onChanged: widget.onLowSignalThresholdChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return _buildSection(
      context,
      icon: Icons.download,
      label: 'EXPORT',
      children: [
        _buildExportButton(context, 'Export as PDF', Icons.picture_as_pdf, widget.onExportPdf ?? () {}),
        const SizedBox(height: AppSpacing.sm),
        _buildExportButton(context, 'Export as PNG', Icons.image, widget.onExportPng ?? () {}),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Image size (px)',
          style: AppTextStyles.labelSmall.copyWith(color: textColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                context,
                label: 'W',
                value: widget.exportWidth,
                onChanged: (v) {
                  if (v != null && v > 0) {
                    widget.onExportWidthChanged(v);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildDimensionField(
                context,
                label: 'H',
                value: widget.exportHeight,
                onChanged: (v) {
                  if (v != null && v > 0) {
                    widget.onExportHeightChanged(v);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensionField(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: TextEditingController(text: value.toString()),
        keyboardType: TextInputType.number,
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          prefixText: '$label ',
          prefixStyle: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        onChanged: (v) {
          final parsed = int.tryParse(v);
          onChanged(parsed);
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? AppColorsDark.link : AppColors.link;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    const String repoUrl = 'https://github.com/tercen/mean_variance_flutter';
    const String version = 'dev'; // Tag or commit hash, updated by build script

    return _buildSection(
      context,
      icon: Icons.info_outline,
      label: 'INFO',
      children: [
        Row(
          children: [
            Text(
              'GitHub: ',
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
            InkWell(
              onTap: () {
                // Open repo/tag URL in new tab (web)
                // ignore: avoid_web_libraries_in_flutter
                // html.window.open('$repoUrl/commit/$version', '_blank');
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Text(
                  version,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: linkColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final labelColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: labelColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    return Text(text, style: AppTextStyles.label.copyWith(color: textColor));
  }

  Widget _buildSubLabel(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
