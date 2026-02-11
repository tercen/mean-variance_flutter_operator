import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/left_panel.dart';
import '../widgets/main_content.dart';
import '../widgets/top_bar.dart';
import '../../core/utils/context_detector.dart';
import '../../implementations/services/export_service.dart';

/// Main screen for Mean-Variance operator
/// Following Tercen app-frame.md pattern
class MeanAndCvScreen extends StatefulWidget {
  const MeanAndCvScreen({super.key});

  @override
  State<MeanAndCvScreen> createState() => _MeanAndCvScreenState();
}

class _MeanAndCvScreenState extends State<MeanAndCvScreen> {
  bool _isPanelCollapsed = false;

  // RepaintBoundary key for export capture
  final _repaintBoundaryKey = GlobalKey();

  // Grid dimensions reported by MainContent (for per-pane export sizing)
  int _nSupergroups = 1;
  int _nGroups = 1;

  // Control state
  String _chartTitle = '';
  String _plotType = 'CV';
  bool _showModelFit = true;
  bool _combineGroups = false;
  bool _logXAxis = false;
  bool _xMinAuto = true;
  bool _xMaxAuto = true;
  bool _yMinAuto = true;
  bool _yMaxAuto = true;
  double _xMin = 0;
  double _xMax = 1000;
  double _yMin = 0;
  double _yMax = 0.5;
  double _highSignalThreshold = 0.95;
  double _lowSignalThreshold = 0.05;
  int _exportWidth = 600;
  int _exportHeight = 400;

  void _togglePanelCollapse() {
    setState(() {
      _isPanelCollapsed = !_isPanelCollapsed;
    });
  }

  /// Number of chart columns in the current view
  int get _exportColumns => _combineGroups ? 1 : _nGroups;

  Future<void> _exportPng() async {
    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    await ExportService.exportPng(
      boundary,
      perPaneWidth: _exportWidth,
      nColumns: _exportColumns,
    );
  }

  Future<void> _exportPdf() async {
    final boundary = _repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    await ExportService.exportPdf(
      boundary,
      perPaneWidth: _exportWidth,
      nColumns: _exportColumns,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowTopBar = AppContextDetector.shouldShowTopBar;

    return Scaffold(
      body: Row(
        children: [
          // Left Panel
          LeftPanel(
            chartTitle: _chartTitle,
            onChartTitleChanged: (value) => setState(() => _chartTitle = value),
            plotType: _plotType,
            onPlotTypeChanged: (value) => setState(() => _plotType = value),
            showModelFit: _showModelFit,
            onShowModelFitChanged: (value) => setState(() => _showModelFit = value),
            combineGroups: _combineGroups,
            onCombineGroupsChanged: (value) => setState(() => _combineGroups = value),
            logXAxis: _logXAxis,
            onLogXAxisChanged: (value) => setState(() => _logXAxis = value),
            xMinAuto: _xMinAuto,
            onXMinAutoChanged: (value) => setState(() => _xMinAuto = value),
            xMin: _xMin,
            onXMinChanged: (value) => setState(() => _xMin = value),
            xMaxAuto: _xMaxAuto,
            onXMaxAutoChanged: (value) => setState(() => _xMaxAuto = value),
            xMax: _xMax,
            onXMaxChanged: (value) => setState(() => _xMax = value),
            yMinAuto: _yMinAuto,
            onYMinAutoChanged: (value) => setState(() => _yMinAuto = value),
            yMin: _yMin,
            onYMinChanged: (value) => setState(() => _yMin = value),
            yMaxAuto: _yMaxAuto,
            onYMaxAutoChanged: (value) => setState(() => _yMaxAuto = value),
            yMax: _yMax,
            onYMaxChanged: (value) => setState(() => _yMax = value),
            highSignalThreshold: _highSignalThreshold,
            onHighSignalThresholdChanged: (value) => setState(() => _highSignalThreshold = value),
            lowSignalThreshold: _lowSignalThreshold,
            onLowSignalThresholdChanged: (value) => setState(() => _lowSignalThreshold = value),
            exportWidth: _exportWidth,
            onExportWidthChanged: (value) => setState(() => _exportWidth = value),
            exportHeight: _exportHeight,
            onExportHeightChanged: (value) => setState(() => _exportHeight = value),
            onExportPng: _exportPng,
            onExportPdf: _exportPdf,
            isCollapsed: _isPanelCollapsed,
            onToggleCollapse: _togglePanelCollapse,
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar (conditional)
                if (shouldShowTopBar) const TopBar(),

                // Main Content
                Expanded(
                  child: MainContent(
                    chartTitle: _chartTitle,
                    plotType: _plotType,
                    showModelFit: _showModelFit,
                    combineGroups: _combineGroups,
                    logXAxis: _logXAxis,
                    xMin: _xMinAuto ? null : _xMin,
                    xMax: _xMaxAuto ? null : _xMax,
                    yMin: _yMinAuto ? null : _yMin,
                    yMax: _yMaxAuto ? null : _yMax,
                    lowThreshold: _lowSignalThreshold,
                    highThreshold: _highSignalThreshold,
                    repaintBoundaryKey: _repaintBoundaryKey,
                    onGridDimensions: (nSupergroups, nGroups) {
                      _nSupergroups = nSupergroups;
                      _nGroups = nGroups;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
