import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/tercen_data.dart';

/// Service for fitting two-component error model
///
/// Algorithm from Shiny version:
/// variance = sigma0² + (CV1 × mean)²
///
/// Where:
/// - sigma0: Low signal noise (constant variance term)
/// - CV1: High signal coefficient of variation (proportional term)
/// - SNR: Signal-to-noise ratio = 1 / CV1
class ModelFittingService {
  /// Fit model to chart data
  ///
  /// Returns updated ChartData with fit results
  ChartData fitModel({
    required ChartData chartData,
    required double lowThreshold,
    required double highThreshold,
  }) {
    try {
      debugPrint('');
      debugPrint('FITTING MODEL: ${chartData.paneKey}');
      debugPrint('--------------------------------');
      debugPrint('Points: ${chartData.points.length}');
      debugPrint('Low threshold: $lowThreshold');
      debugPrint('High threshold: $highThreshold');

      // Step 1: Classify points
      final classifiedPoints = _classifyPoints(
        chartData.points,
        lowThreshold,
        highThreshold,
      );

      // Step 2: Initialize parameters
      final initialParams = _initializeParameters(classifiedPoints);

      if (initialParams == null) {
        debugPrint('⚠ Could not initialize parameters');
        return chartData.copyWith(points: classifiedPoints);
      }

      debugPrint('Initial σ₀: ${initialParams.sigma0.toStringAsFixed(4)}');
      debugPrint('Initial CV₁: ${initialParams.cv1.toStringAsFixed(4)}');

      // Step 3: Iterative fitting
      final fitResult = _iterativeFit(
        classifiedPoints,
        initialParams.sigma0,
        initialParams.cv1,
      );

      debugPrint('Final σ₀: ${fitResult.sigma0.toStringAsFixed(4)}');
      debugPrint('Final CV₁: ${fitResult.cv1.toStringAsFixed(4)}');
      debugPrint('SNR: ${fitResult.snr.toStringAsFixed(2)}');
      debugPrint('Converged: ${fitResult.converged}');
      debugPrint('Iterations: ${fitResult.iterations}');

      // Step 4: Generate fit curve
      final fitCurve = _generateFitCurve(
        classifiedPoints,
        fitResult.sigma0,
        fitResult.cv1,
      );

      return ChartData(
        supergroup: chartData.supergroup,
        testCondition: chartData.testCondition,
        points: classifiedPoints,
        minX: chartData.minX,
        maxX: chartData.maxX,
        minY: chartData.minY,
        maxY: chartData.maxY,
        sigma0: fitResult.sigma0,
        cv1: fitResult.cv1,
        snr: fitResult.snr,
        converged: fitResult.converged,
        fitCurve: fitCurve,
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR fitting model: $e');
      debugPrint('Stack trace: $stackTrace');
      return chartData;
    }
  }

  /// Classify points by thresholds
  List<TercenDataPoint> _classifyPoints(
    List<TercenDataPoint> points,
    double lowThreshold,
    double highThreshold,
  ) {
    final classified = <TercenDataPoint>[];

    for (final point in points) {
      final bLow = point.mean < lowThreshold;
      final bHigh = point.mean > highThreshold;

      classified.add(TercenDataPoint(
        x: point.x,
        y: point.y,
        rowIndex: point.rowIndex,
        colorIndex: point.colorIndex,
        testCondition: point.testCondition,
        supergroup: point.supergroup,
        rowId: point.rowId,
        sd: point.sd,
        n: point.n,
        bLow: bLow,
        bHigh: bHigh,
      ));
    }

    final lowCount = classified.where((p) => p.bLow).length;
    final highCount = classified.where((p) => p.bHigh).length;
    final midCount = classified.length - lowCount - highCount;

    debugPrint('Classification: $lowCount low, $midCount mid, $highCount high');

    return classified;
  }

  /// Initialize parameters from data
  _InitialParams? _initializeParameters(List<TercenDataPoint> points) {
    final lowPoints = points.where((p) => p.bLow).toList();
    final highPoints = points.where((p) => p.bHigh).toList();

    // Calculate sigma0 from low signal points (median SD)
    double sigma0;
    if (lowPoints.isNotEmpty) {
      final sds = lowPoints.map((p) => p.sd).toList()..sort();
      sigma0 = _median(sds);
    } else {
      // No low points, use minimum SD
      if (points.isEmpty) return null;
      sigma0 = points.map((p) => p.sd).reduce((a, b) => a < b ? a : b);
    }

    // Calculate CV1 from high signal points (median CV)
    double cv1;
    if (highPoints.isNotEmpty) {
      final cvs = highPoints.map((p) => p.sd / p.mean).toList()..sort();
      cv1 = _median(cvs);
    } else {
      // No high points, use median CV of all points
      if (points.isEmpty) return null;
      final cvs = points.map((p) => p.sd / p.mean).toList()..sort();
      cv1 = _median(cvs);
    }

    // Ensure reasonable bounds
    if (sigma0 < 0) sigma0 = 0;
    if (cv1 < 0) cv1 = 0.01;
    if (!sigma0.isFinite) sigma0 = 0;
    if (!cv1.isFinite) cv1 = 0.01;

    return _InitialParams(sigma0: sigma0, cv1: cv1);
  }

  /// Iterative fitting with weighted least squares
  _FitResult _iterativeFit(
    List<TercenDataPoint> points,
    double initialSigma0,
    double initialCv1,
  ) {
    double sigma0 = initialSigma0;
    double cv1 = initialCv1;
    bool converged = false;
    int iterations = 0;
    const maxIterations = 25;
    const convergenceThreshold = 0.001;

    for (int iter = 0; iter < maxIterations; iter++) {
      iterations = iter + 1;

      // Calculate expected variance for each point
      final weights = <double>[];
      final logMeans = <double>[];
      final logSds = <double>[];

      for (final point in points) {
        final mean = point.mean;
        final sd = point.sd;

        if (mean <= 0 || sd <= 0) continue;

        // Expected variance: sigma0² + (CV1 × mean)²
        final expectedVar = pow(sigma0, 2) + pow(cv1 * mean, 2);

        if (expectedVar <= 0) continue;

        // Weight = 1 / expected variance
        final weight = 1.0 / expectedVar;

        weights.add(weight);
        logMeans.add(log(mean));
        logSds.add(log(sd));
      }

      if (weights.length < 2) {
        // Not enough points for fitting
        break;
      }

      // Weighted least squares: log(SD) ~ log(mean)
      final fit = _weightedLinearRegression(logMeans, logSds, weights);

      if (fit == null) break;

      // Extract new parameters from fit
      // Model: log(SD) = log(sqrt(sigma0² + (CV1×mean)²))
      // Approximation: log(SD) ≈ intercept + slope × log(mean)
      // For large means: log(SD) ≈ log(CV1) + log(mean)
      // So: slope ≈ 1, intercept ≈ log(CV1)

      final newSigma0 = exp(fit.intercept);
      final newCv1 = exp(fit.intercept) * exp(fit.slope);

      // Check convergence
      final deltaSigma0 = (newSigma0 - sigma0).abs();
      final deltaCv1 = (newCv1 - cv1).abs();

      if (deltaSigma0 < convergenceThreshold && deltaCv1 < convergenceThreshold) {
        converged = true;
        sigma0 = newSigma0;
        cv1 = newCv1;
        break;
      }

      sigma0 = newSigma0;
      cv1 = newCv1;

      // Ensure reasonable bounds
      if (!sigma0.isFinite || sigma0 < 0) sigma0 = initialSigma0;
      if (!cv1.isFinite || cv1 < 0) cv1 = initialCv1;
    }

    final snr = cv1 > 0 ? 1.0 / cv1 : 0.0;

    return _FitResult(
      sigma0: sigma0,
      cv1: cv1,
      snr: snr,
      converged: converged,
      iterations: iterations,
    );
  }

  /// Weighted linear regression
  _LinearFit? _weightedLinearRegression(
    List<double> x,
    List<double> y,
    List<double> weights,
  ) {
    if (x.length != y.length || x.length != weights.length || x.length < 2) {
      return null;
    }

    // Calculate weighted sums
    double sumW = 0;
    double sumWX = 0;
    double sumWY = 0;
    double sumWXX = 0;
    double sumWXY = 0;

    for (int i = 0; i < x.length; i++) {
      final w = weights[i];
      final xi = x[i];
      final yi = y[i];

      sumW += w;
      sumWX += w * xi;
      sumWY += w * yi;
      sumWXX += w * xi * xi;
      sumWXY += w * xi * yi;
    }

    // Calculate slope and intercept
    final denominator = sumW * sumWXX - sumWX * sumWX;

    if (denominator.abs() < 1e-10) {
      return null;
    }

    final slope = (sumW * sumWXY - sumWX * sumWY) / denominator;
    final intercept = (sumWY - slope * sumWX) / sumW;

    return _LinearFit(slope: slope, intercept: intercept);
  }

  /// Generate fit curve points
  List<TercenDataPoint> _generateFitCurve(
    List<TercenDataPoint> points,
    double sigma0,
    double cv1,
  ) {
    if (points.isEmpty) return [];

    final means = points.map((p) => p.mean).toList();
    final minMean = means.reduce((a, b) => a < b ? a : b);
    final maxMean = means.reduce((a, b) => a > b ? a : b);

    if (minMean <= 0 || maxMean <= 0 || minMean >= maxMean) {
      return [];
    }

    // Generate 100 points from min to max
    const nPoints = 100;
    final curve = <TercenDataPoint>[];

    for (int i = 0; i < nPoints; i++) {
      final t = i / (nPoints - 1);
      final mean = minMean + t * (maxMean - minMean);

      // Calculate SD from model: sd = sqrt(sigma0² + (CV1 × mean)²)
      final sd = sqrt(pow(sigma0, 2) + pow(cv1 * mean, 2));

      curve.add(TercenDataPoint(
        x: mean,
        y: sd, // Will be transformed based on plot type later
        rowIndex: i,
        colorIndex: 0,
        testCondition: '',
        supergroup: '',
        rowId: 'fit_$i',
        sd: sd,
        n: 0,
        bLow: false,
        bHigh: false,
      ));
    }

    return curve;
  }

  /// Calculate median of a sorted list
  double _median(List<double> sortedValues) {
    if (sortedValues.isEmpty) return 0;

    final n = sortedValues.length;
    if (n % 2 == 1) {
      return sortedValues[n ~/ 2];
    } else {
      return (sortedValues[n ~/ 2 - 1] + sortedValues[n ~/ 2]) / 2;
    }
  }
}

/// Initial parameter estimates
class _InitialParams {
  final double sigma0;
  final double cv1;

  _InitialParams({required this.sigma0, required this.cv1});
}

/// Fit result
class _FitResult {
  final double sigma0;
  final double cv1;
  final double snr;
  final bool converged;
  final int iterations;

  _FitResult({
    required this.sigma0,
    required this.cv1,
    required this.snr,
    required this.converged,
    required this.iterations,
  });
}

/// Linear fit result
class _LinearFit {
  final double slope;
  final double intercept;

  _LinearFit({required this.slope, required this.intercept});
}

/// Extension to add copyWith to ChartData
extension ChartDataExtension on ChartData {
  ChartData copyWith({
    List<TercenDataPoint>? points,
    double? sigma0,
    double? cv1,
    double? snr,
    bool? converged,
    List<TercenDataPoint>? fitCurve,
  }) {
    return ChartData(
      supergroup: supergroup,
      testCondition: testCondition,
      points: points ?? this.points,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      sigma0: sigma0 ?? this.sigma0,
      cv1: cv1 ?? this.cv1,
      snr: snr ?? this.snr,
      converged: converged ?? this.converged,
      fitCurve: fitCurve ?? this.fitCurve,
    );
  }
}
