import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_dark.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/tercen_data.dart';
import '../../implementations/services/csv_parser_service.dart';
import '../../implementations/services/tercen_data_service.dart';
import '../../implementations/services/model_fitting_service.dart';
import '../painters/mean_variance_chart_painter.dart';

/// Main content area with charts and fit results table below
/// Charts always use white background (export-ready)
class MainContent extends StatefulWidget {
  final String chartTitle;
  final String plotType;
  final bool showModelFit;
  final bool combineGroups;
  final bool logXAxis;
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final double lowThreshold;
  final double highThreshold;

  const MainContent({
    super.key,
    required this.chartTitle,
    required this.plotType,
    required this.showModelFit,
    required this.combineGroups,
    this.logXAxis = false,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.lowThreshold = 100.0,
    this.highThreshold = 1000.0,
  });

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  bool _isTableCollapsed = false;
  late Future<TercenDataset> _rawDataFuture;

  // Cache fitted dataset so we only re-fit when thresholds change
  TercenDataset? _fittedDataset;
  double? _fittedLowThreshold;
  double? _fittedHighThreshold;
  bool? _fittedShowModelFit;

  @override
  void initState() {
    super.initState();
    _rawDataFuture = _loadRawData();
  }

  /// Load raw data from Tercen context or fall back to CSV mock.
  /// Model fitting is applied separately so threshold changes don't reload data.
  Future<TercenDataset> _loadRawData() async {
    TercenDataset dataset;

    try {
      // Get taskId from URL parameters
      final taskId = Uri.base.queryParameters['taskId'];

      if (taskId != null && taskId.isNotEmpty) {
        debugPrint('');
        debugPrint('🔵 Loading data from Tercen context (taskId: $taskId)');

        // Try to use Tercen data service
        try {
          final tercenService = TercenDataService.fromGetIt();
          dataset = await tercenService.extractTercenData(taskId: taskId);
        } catch (e) {
          debugPrint('⚠ Error using Tercen service: $e');
          debugPrint('  Falling back to mock CSV data');
          dataset = await CsvParserService.parseExampleData();
        }
      } else {
        debugPrint('');
        debugPrint('🟡 No taskId in URL, using mock CSV data');
        dataset = await CsvParserService.parseExampleData();
      }
    } catch (e) {
      debugPrint('⚠ Error in data loading: $e');
      debugPrint('  Falling back to mock CSV data');
      dataset = await CsvParserService.parseExampleData();
    }

    return dataset;
  }

  /// Apply model fitting to raw dataset, caching result until thresholds change.
  TercenDataset _getOrApplyFitting(TercenDataset rawDataset) {
    // Return cached result if thresholds haven't changed
    if (_fittedDataset != null &&
        _fittedLowThreshold == widget.lowThreshold &&
        _fittedHighThreshold == widget.highThreshold &&
        _fittedShowModelFit == widget.showModelFit) {
      return _fittedDataset!;
    }

    if (!widget.showModelFit) {
      _fittedDataset = rawDataset;
      _fittedLowThreshold = widget.lowThreshold;
      _fittedHighThreshold = widget.highThreshold;
      _fittedShowModelFit = widget.showModelFit;
      return rawDataset;
    }

    debugPrint('');
    debugPrint('🟣 Applying model fitting to dataset');
    debugPrint('   Low threshold: ${widget.lowThreshold}');
    debugPrint('   High threshold: ${widget.highThreshold}');

    final fittingService = ModelFittingService();
    final fittedChartData = <String, ChartData>{};

    for (final entry in rawDataset.chartData.entries) {
      try {
        fittedChartData[entry.key] = fittingService.fitModel(
          chartData: entry.value,
          lowThreshold: widget.lowThreshold,
          highThreshold: widget.highThreshold,
        );
      } catch (e) {
        debugPrint('⚠ Error fitting ${entry.key}: $e');
        fittedChartData[entry.key] = entry.value;
      }
    }

    final dataset = TercenDataset(
      supergroups: rawDataset.supergroups,
      testConditions: rawDataset.testConditions,
      chartData: fittedChartData,
    );

    debugPrint('✅ Model fitting complete');

    _fittedDataset = dataset;
    _fittedLowThreshold = widget.lowThreshold;
    _fittedHighThreshold = widget.highThreshold;
    _fittedShowModelFit = widget.showModelFit;
    return dataset;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;

    return Container(
      color: bgColor,
      child: FutureBuilder<TercenDataset>(
        future: _rawDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data: ${snapshot.error}',
                style: TextStyle(
                  color: isDark ? AppColorsDark.error : AppColors.error,
                ),
              ),
            );
          }

          // Apply model fitting with current thresholds (cached until they change)
          final dataset = _getOrApplyFitting(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chart Title (if provided)
                if (widget.chartTitle.isNotEmpty) ...[
                  Center(
                    child: Text(
                      widget.chartTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColorsDark.textPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Chart Grid (always white background)
                if (widget.combineGroups)
                  _buildCombinedChart(context, dataset)
                else
                  _buildSupergroupGrid(context, dataset),

                const SizedBox(height: AppSpacing.md),

                // Legend
                if (widget.showModelFit) _buildLegend(context, dataset),

                // Fit Results Table (below charts, not in right panel)
                if (widget.showModelFit && !_isTableCollapsed) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildTableBelow(context, dataset),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build grid layout organized by supergroups (rows)
  /// Each supergroup gets its own row with test conditions as columns
  Widget _buildSupergroupGrid(BuildContext context, TercenDataset dataset) {
    final supergroups = dataset.getSupergroupsOrdered();
    final testConditions = dataset.getTestConditionsOrdered();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: supergroups.asMap().entries.map((sgEntry) {
        final supergroupIndex = sgEntry.key;
        final supergroup = sgEntry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: testConditions.asMap().entries.map((tcEntry) {
              final groupIndex = tcEntry.key;
              final condition = tcEntry.value;

              final chartData = dataset.getChartData(supergroup, condition);
              if (chartData == null) {
                return const SizedBox.shrink();
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSingleChart(
                    context,
                    chartData,
                    supergroupIndex: supergroupIndex,
                    groupIndex: groupIndex,
                    totalSupergroups: supergroups.length,
                    totalGroups: testConditions.length,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Build combined chart data: merge all pane points with per-pane colorIndex,
  /// then re-fit the model on the combined dataset (matching Shiny's Collapse Panes).
  ChartData _getCombinedChartData(TercenDataset dataset) {
    // Assign color indices by pane key (sorted for consistency)
    final paneKeys = dataset.chartData.keys.toList()..sort();
    final paneColorMap = <String, int>{};
    for (int i = 0; i < paneKeys.length; i++) {
      paneColorMap[paneKeys[i]] = i;
    }

    // Merge all points with per-pane colorIndex
    final allPoints = <TercenDataPoint>[];
    for (final entry in dataset.chartData.entries) {
      final colorIdx = paneColorMap[entry.key]! % 8;
      for (final point in entry.value.points) {
        allPoints.add(TercenDataPoint(
          x: point.x,
          y: point.y,
          rowIndex: point.rowIndex,
          colorIndex: colorIdx,
          testCondition: point.testCondition,
          supergroup: point.supergroup,
          rowId: point.rowId,
          sd: point.sd,
          n: point.n,
          lvar: point.lvar,
          bLow: point.bLow,
          bHigh: point.bHigh,
        ));
      }
    }

    if (allPoints.isEmpty) {
      return ChartData(
        supergroup: 'Combined',
        testCondition: 'All',
        points: [],
        minX: 0, maxX: 1, minY: 0, maxY: 1,
      );
    }

    final xValues = allPoints.map((p) => p.x).toList();
    final yValues = allPoints.map((p) => p.y).toList();

    ChartData combinedData = ChartData(
      supergroup: 'Combined',
      testCondition: 'All',
      points: allPoints,
      minX: xValues.reduce((a, b) => a < b ? a : b),
      maxX: xValues.reduce((a, b) => a > b ? a : b),
      minY: yValues.reduce((a, b) => a < b ? a : b),
      maxY: yValues.reduce((a, b) => a > b ? a : b),
    );

    // Re-fit the model on combined data
    if (widget.showModelFit) {
      final fittingService = ModelFittingService();
      try {
        combinedData = fittingService.fitModel(
          chartData: combinedData,
          lowThreshold: widget.lowThreshold,
          highThreshold: widget.highThreshold,
        );
      } catch (e) {
        debugPrint('⚠ Error fitting combined data: $e');
      }
    }

    return combinedData;
  }

  Widget _buildCombinedChart(BuildContext context, TercenDataset dataset) {
    final combinedData = _getCombinedChartData(dataset);

    if (combinedData.points.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return _buildSingleChart(context, combinedData,
        isFullWidth: true, isCombined: true);
  }

  Widget _buildSingleChart(
    BuildContext context,
    ChartData chartData, {
    bool isFullWidth = false,
    int supergroupIndex = 0,
    int groupIndex = 0,
    int totalSupergroups = 1,
    int totalGroups = 1,
    bool isCombined = false,
  }) {
    // ALWAYS WHITE BACKGROUND (export-ready, not theme-dependent)
    const chartBgColor = Colors.white;
    const borderColor = Color(0xFFD1D5DB);
    const textColor = Color(0xFF111827);

    // Determine axis labels based on transforms
    final xAxisLabel = widget.logXAxis ? 'log₁₀(Mean)' : 'Mean';
    final yAxisLabel = widget.plotType == 'CV'
        ? 'Coefficient of Variation'
        : widget.plotType == 'SNR'
            ? 'SNR (dB)'
            : 'Standard Deviation';

    return Container(
      height: isFullWidth ? 550 : 450,
      decoration: BoxDecoration(
        color: chartBgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pane title
          Text(
            isCombined ? 'All panes combined' : chartData.paneKey,
            style: AppTextStyles.plotTitle.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Chart visualization with axes
          Expanded(
            child: Row(
              children: [
                // Y-axis labels (left)
                SizedBox(
                  width: 40,
                  child: _buildYAxisLabels(chartData, textColor),
                ),

                // Main chart area
                Expanded(
                  child: Column(
                    children: [
                      // Chart plot area
                      Expanded(
                        child: CustomPaint(
                          painter: MeanVarianceChartPainter(
                            chartData: chartData,
                            plotType: widget.plotType,
                            showFit: widget.showModelFit,
                            logXAxis: widget.logXAxis,
                            xMin: widget.xMin,
                            xMax: widget.xMax,
                            yMin: widget.yMin,
                            yMax: widget.yMax,
                            supergroupIndex: supergroupIndex,
                            groupIndex: groupIndex,
                            totalSupergroups: totalSupergroups,
                            totalGroups: totalGroups,
                            isCombined: isCombined,
                          ),
                          size: Size.infinite,
                        ),
                      ),

                      // X-axis labels (bottom)
                      SizedBox(
                        height: 20,
                        child: _buildXAxisLabels(chartData, textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Axis titles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                xAxisLabel,
                style: AppTextStyles.axisLabel.copyWith(color: textColor),
              ),
              Text(
                yAxisLabel,
                style: AppTextStyles.axisLabel.copyWith(color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compute transformed Y-axis range using Shiny's default limits:
  /// CV: yMax=0.5, SNR: yMax=20, SD: yMax=0.25*max(mean)
  ({double minY, double maxY}) _computeTransformedYRange(ChartData chartData) {
    double defaultMaxY;
    if (widget.plotType == 'CV') {
      defaultMaxY = 0.5;
    } else if (widget.plotType == 'SNR') {
      defaultMaxY = 20;
    } else {
      // SD: 0.25 * max(mean)
      final maxMean = chartData.points.isEmpty
          ? 1.0
          : chartData.points.map((p) => p.mean).reduce((a, b) => a > b ? a : b);
      defaultMaxY = 0.25 * maxMean;
    }
    return (minY: 0.0, maxY: defaultMaxY);
  }

  /// Compute transformed X-axis range
  ({double minX, double maxX}) _computeTransformedXRange(ChartData chartData) {
    final transformedXs = <double>[];
    for (final p in chartData.points) {
      double x = p.mean;
      if (widget.logXAxis) {
        if (x > 0) {
          x = log(x) / ln10;
        } else {
          continue;
        }
      }
      if (x.isFinite) transformedXs.add(x);
    }
    if (transformedXs.isEmpty) return (minX: 0.0, maxX: 1.0);
    final minX = transformedXs.reduce((a, b) => a < b ? a : b);
    final maxX = transformedXs.reduce((a, b) => a > b ? a : b);
    final pad = (maxX - minX) * 0.05;
    return (minX: minX - pad, maxX: maxX + pad);
  }

  Widget _buildYAxisLabels(ChartData chartData, Color textColor) {
    final range = _computeTransformedYRange(chartData);
    final effMinY = widget.yMin ?? range.minY;
    final effMaxY = widget.yMax ?? range.maxY;
    final ySpan = effMaxY - effMinY;
    final labels = <String>[];

    for (var i = 4; i >= 0; i--) {
      final value = effMinY + (ySpan * i / 4);
      labels.add(value.toStringAsFixed(ySpan < 1 ? 3 : ySpan < 10 ? 1 : 0));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: labels.map((label) {
          return Text(
            label,
            style: TextStyle(fontSize: 9, color: textColor),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildXAxisLabels(ChartData chartData, Color textColor) {
    final range = _computeTransformedXRange(chartData);
    final effMinX = widget.xMin ?? range.minX;
    final effMaxX = widget.xMax ?? range.maxX;
    final xSpan = effMaxX - effMinX;
    final labels = <String>[];

    for (var i = 0; i <= 4; i++) {
      final value = effMinX + (xSpan * i / 4);
      labels.add(value.toStringAsFixed(xSpan < 1 ? 3 : xSpan < 10 ? 1 : 0));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) {
        return Text(
          label,
          style: TextStyle(fontSize: 9, color: textColor),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(BuildContext context, TercenDataset dataset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final children = <Widget>[];

    // Per-pane color legend (always when showModelFit, for combined shows each pane)
    if (widget.combineGroups) {
      final paneKeys = dataset.chartData.keys.toList()..sort();
      for (int i = 0; i < paneKeys.length; i++) {
        final color = AppColors.paneColors[i % 8];
        children.add(_buildColorLegendItem(paneKeys[i], color, textColor));
      }
    }

    // bHigh marker
    if (widget.showModelFit) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(10, 10),
            painter: _TriangleIconPainter(color: textColor),
          ),
          const SizedBox(width: 4),
          Text('High signal (bHigh)',
              style: AppTextStyles.label.copyWith(color: textColor)),
        ],
      ));
    }

    // Fit line (red)
    if (widget.showModelFit) {
      children.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 2, color: const Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text('Fit line',
              style: AppTextStyles.label.copyWith(color: textColor)),
        ],
      ));
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: children,
    );
  }

  Widget _buildColorLegendItem(String label, Color dotColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: textColor)),
      ],
    );
  }

  Widget _buildTableBelow(BuildContext context, TercenDataset dataset) {
    return _buildFitResultsTable(context, dataset);
  }

  /// Build fit results table with real data
  Widget _buildFitResultsTable(BuildContext context, TercenDataset dataset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textColor =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;

    // Extract fit results from dataset
    final fitResults = <Map<String, dynamic>>[];

    if (widget.combineGroups) {
      // Re-fit model on combined data (matching Shiny's Collapse Panes)
      final combinedData = _getCombinedChartData(dataset);
      fitResults.add({
        'pane': 'All panes combined',
        'sigma0': combinedData.sigma0,
        'cv1': combinedData.cv1,
        'snr': combinedData.snr,
        'converged': combinedData.converged,
      });
    } else {
      final supergroups = dataset.getSupergroupsOrdered();
      final testConditions = dataset.getTestConditionsOrdered();

      for (final sg in supergroups) {
        for (final tc in testConditions) {
          final chartData = dataset.getChartData(sg, tc);
          if (chartData != null) {
            fitResults.add({
              'pane': chartData.paneKey,
              'sigma0': chartData.sigma0,
              'cv1': chartData.cv1,
              'snr': chartData.snr,
              'converged': chartData.converged,
            });
          }
        }
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 700, // Wider to accommodate Converged column
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'FIT RESULTS',
                      style: AppTextStyles.label.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _isTableCollapsed = true;
                      });
                    },
                    tooltip: 'Hide table',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Compact Table Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('Pane',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('σ₀',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('CV₁',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('SNR',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('Converged',
                            style: AppTextStyles.labelSmall
                                .copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                  // Data rows
                  ...fitResults.map((row) {
                    final sigma0 = row['sigma0'] as double?;
                    final cv1 = row['cv1'] as double?;
                    final snr = row['snr'] as double?;
                    final converged = row['converged'] as bool?;

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(row['pane'] as String,
                              style: AppTextStyles.bodySmall),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                              sigma0 != null
                                  ? sigma0.toStringAsFixed(2)
                                  : 'N/A',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                              cv1 != null ? cv1.toStringAsFixed(4) : 'N/A',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                              snr != null ? snr.toStringAsFixed(2) : 'N/A',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                              converged != null
                                  ? (converged ? '✓' : '✗')
                                  : 'N/A',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: converged == true
                                    ? Colors.green
                                    : converged == false
                                        ? Colors.orange
                                        : textColor,
                              ),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small triangle icon painter for legend
class _TriangleIconPainter extends CustomPainter {
  final Color color;
  _TriangleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TriangleIconPainter oldDelegate) =>
      color != oldDelegate.color;
}

