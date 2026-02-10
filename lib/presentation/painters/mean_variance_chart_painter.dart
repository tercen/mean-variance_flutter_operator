import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/tercen_data.dart';

/// Custom painter for Mean-Variance charts
///
/// Features:
/// - Plot type transforms: CV, SNR, SD
/// - Log axis transforms
/// - Color rules from Shiny (supergroup×group colors OR blue)
/// - Shape rules (triangles, squares, circles)
/// - Fit curve rendering
class MeanVarianceChartPainter extends CustomPainter {
  final ChartData chartData;
  final String plotType; // 'CV', 'SNR', 'SD'
  final bool showFit;
  final bool logXAxis;
  final double? xMin;
  final double? xMax;
  final double? yMin;
  final double? yMax;
  final int supergroupIndex;
  final int groupIndex;
  final int totalSupergroups;
  final int totalGroups;

  MeanVarianceChartPainter({
    required this.chartData,
    required this.plotType,
    required this.showFit,
    required this.logXAxis,
    this.xMin,
    this.xMax,
    this.yMin,
    this.yMax,
    this.supergroupIndex = 0,
    this.groupIndex = 0,
    this.totalSupergroups = 1,
    this.totalGroups = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Constants
    const gridColor = Color(0xFFE5E7EB);
    const fitLineColor = Color(0xFFDC2626);
    const defaultBlue = Color(0xFF1E40AF);

    // Draw grid
    _drawGrid(canvas, size, gridColor);

    // Transform points based on plot type
    final transformedPoints = _transformPoints(chartData.points);

    // Calculate axis ranges
    final axisRanges = _calculateAxisRanges(transformedPoints);

    // Draw fit curve if enabled
    if (showFit && chartData.fitCurve != null && chartData.fitCurve!.isNotEmpty) {
      _drawFitCurve(canvas, size, axisRanges, fitLineColor);
    }

    // Draw data points
    _drawPoints(canvas, size, transformedPoints, axisRanges);
  }

  /// Transform points based on plot type
  List<_TransformedPoint> _transformPoints(List<TercenDataPoint> points) {
    final transformed = <_TransformedPoint>[];

    for (final point in points) {
      double x = point.mean;
      double y;

      // Apply plot type transform
      if (plotType == 'CV') {
        // CV = SD / mean
        y = point.mean > 0 ? point.sd / point.mean : 0;
      } else if (plotType == 'SNR') {
        // SNR = mean / SD
        y = point.sd > 0 ? point.mean / point.sd : 0;
      } else {
        // SD (default)
        y = point.sd;
      }

      // Apply log transform to X if enabled
      if (logXAxis) {
        if (x > 0) {
          x = log(x) / ln10; // log10
        } else {
          continue; // Skip non-positive values in log scale
        }
      }

      // Skip invalid values
      if (!x.isFinite || !y.isFinite || y < 0) {
        continue;
      }

      transformed.add(_TransformedPoint(
        x: x,
        y: y,
        point: point,
      ));
    }

    return transformed;
  }

  /// Calculate axis ranges
  _AxisRanges _calculateAxisRanges(List<_TransformedPoint> points) {
    if (points.isEmpty) {
      return _AxisRanges(minX: 0, maxX: 1, minY: 0, maxY: 1);
    }

    // Use manual limits if provided
    double minX = xMin ?? points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    double maxX = xMax ?? points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    double minY = yMin ?? points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    double maxY = yMax ?? points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    // Add 5% padding if auto
    if (xMin == null || xMax == null) {
      final xPadding = (maxX - minX) * 0.05;
      minX -= xPadding;
      maxX += xPadding;
    }

    if (yMin == null || yMax == null) {
      final yPadding = (maxY - minY) * 0.05;
      minY -= yPadding;
      maxY += yPadding;
    }

    // Ensure non-negative Y for CV/SNR/SD
    if (minY < 0) minY = 0;

    // Ensure valid range
    if (minX >= maxX) {
      minX = minX - 0.5;
      maxX = maxX + 0.5;
    }
    if (minY >= maxY) {
      minY = minY - 0.5;
      maxY = maxY + 0.5;
    }

    return _AxisRanges(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  /// Draw grid lines
  void _drawGrid(Canvas canvas, Size size, Color gridColor) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  /// Draw data points with colors and shapes
  void _drawPoints(
    Canvas canvas,
    Size size,
    List<_TransformedPoint> points,
    _AxisRanges ranges,
  ) {
    for (final tp in points) {
      final point = tp.point;

      // Determine color
      Color pointColor;
      if (showFit) {
        // Color by supergroup×group position (cycle through 8 pane colors)
        final colorIndex = (supergroupIndex * totalGroups + groupIndex) % 8;
        pointColor = AppColors.paneColors[colorIndex];
      } else {
        // All points blue when fit disabled
        pointColor = const Color(0xFF1E40AF);
      }

      // Calculate canvas position
      final xNorm = (tp.x - ranges.minX) / (ranges.maxX - ranges.minX);
      final yNorm = (tp.y - ranges.minY) / (ranges.maxY - ranges.minY);

      final canvasX = size.width * xNorm;
      final canvasY = size.height * (1 - yNorm); // Flip Y

      // Draw shape based on classification
      if (showFit) {
        if (point.bLow) {
          _drawTriangle(canvas, Offset(canvasX, canvasY), 4.5, pointColor);
        } else if (point.bHigh) {
          _drawSquare(canvas, Offset(canvasX, canvasY), 4.0, pointColor);
        } else {
          _drawCircle(canvas, Offset(canvasX, canvasY), 2.5, pointColor);
        }
      } else {
        // All circles when fit disabled
        _drawCircle(canvas, Offset(canvasX, canvasY), 2.5, pointColor);
      }
    }
  }

  /// Draw fit curve
  void _drawFitCurve(
    Canvas canvas,
    Size size,
    _AxisRanges ranges,
    Color fitLineColor,
  ) {
    final fitPaint = Paint()
      ..color = fitLineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Transform fit curve points
    final transformedFit = _transformPoints(chartData.fitCurve!);

    if (transformedFit.length < 2) return;

    final path = Path();
    bool started = false;

    for (final tp in transformedFit) {
      final xNorm = (tp.x - ranges.minX) / (ranges.maxX - ranges.minX);
      final yNorm = (tp.y - ranges.minY) / (ranges.maxY - ranges.minY);

      // Skip points outside visible range
      if (xNorm < -0.1 || xNorm > 1.1 || yNorm < -0.1 || yNorm > 1.1) {
        continue;
      }

      final canvasX = size.width * xNorm;
      final canvasY = size.height * (1 - yNorm);

      if (!started) {
        path.moveTo(canvasX, canvasY);
        started = true;
      } else {
        path.lineTo(canvasX, canvasY);
      }
    }

    canvas.drawPath(path, fitPaint);
  }

  /// Draw circle
  void _drawCircle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  /// Draw triangle (down pointing)
  void _drawTriangle(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy + size); // Bottom point
    path.lineTo(center.dx - size, center.dy - size); // Top left
    path.lineTo(center.dx + size, center.dy - size); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draw square
  void _drawSquare(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: size * 2, height: size * 2);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(MeanVarianceChartPainter oldDelegate) {
    return chartData != oldDelegate.chartData ||
        plotType != oldDelegate.plotType ||
        showFit != oldDelegate.showFit ||
        logXAxis != oldDelegate.logXAxis ||
        xMin != oldDelegate.xMin ||
        xMax != oldDelegate.xMax ||
        yMin != oldDelegate.yMin ||
        yMax != oldDelegate.yMax;
  }
}

/// Transformed point with original reference
class _TransformedPoint {
  final double x;
  final double y;
  final TercenDataPoint point;

  _TransformedPoint({
    required this.x,
    required this.y,
    required this.point,
  });
}

/// Axis ranges
class _AxisRanges {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  _AxisRanges({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
