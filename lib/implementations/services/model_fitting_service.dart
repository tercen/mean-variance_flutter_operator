import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../domain/models/tercen_data.dart';

/// Service for fitting two-component error model
///
/// Matches the Shiny R implementation:
///   variance = ssq0 + ssq1 × mean²
///
/// Where:
/// - ssq0: Low signal variance (Poisson/constant component)
/// - ssq1: High signal proportional variance (CV² component)
/// - cvFit = sqrt(ssq1 + ssq0/mean²)
/// - sdFit = sqrt(ssq1 × mean² + ssq0)
/// - snrFit = -10 × log10(cvFit)
///
/// Thresholds (pLow, pHigh) are QUANTILES of the mean distribution,
/// not absolute values.
class ModelFittingService {
  /// Fit model to chart data
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
      debugPrint('pLow quantile: $lowThreshold');
      debugPrint('pHigh quantile: $highThreshold');

      final points = chartData.points;
      if (points.length < 3) {
        debugPrint('⚠ Not enough points for fitting');
        return chartData;
      }

      // Step 1: Compute quantile thresholds from mean distribution
      final sortedMeans = points.map((p) => p.mean).toList()..sort();
      final lowMeanThreshold = _quantile(sortedMeans, lowThreshold);
      final highMeanThreshold = _quantile(sortedMeans, highThreshold);

      debugPrint('Mean range: ${sortedMeans.first.toStringAsFixed(2)} - ${sortedMeans.last.toStringAsFixed(2)}');
      debugPrint('Low threshold (${lowThreshold} quantile): ${lowMeanThreshold.toStringAsFixed(2)}');
      debugPrint('High threshold (${highThreshold} quantile): ${highMeanThreshold.toStringAsFixed(2)}');

      // Step 2: Initial classification
      var bLow = points.map((p) => p.mean <= lowMeanThreshold).toList();
      var bHigh = points.map((p) => p.mean >= highMeanThreshold).toList();

      final lowCount = bLow.where((b) => b).length;
      final highCount = bHigh.where((b) => b).length;
      debugPrint('Initial classification: $lowCount low, ${points.length - lowCount - highCount} mid, $highCount high');

      // Step 3: Iterative fitting (matching Shiny's cvmodel function)
      double ssq0 = double.nan;
      double ssq1 = double.nan;
      int iter = 0;
      const maxIter = 25;
      var bModel = List.generate(points.length, (i) => bLow[i] || bHigh[i]);

      try {
        while (bModel.any((b) => b)) {
          // Calculate pooled variance for low-signal spots
          final lowVars = <double>[];
          final lowNs = <int>[];
          for (int i = 0; i < points.length; i++) {
            if (bLow[i]) {
              lowVars.add(points[i].sd * points[i].sd); // variance = sd²
              lowNs.add(points[i].n);
            }
          }

          if (lowVars.isEmpty || lowNs.isEmpty) {
            ssq0 = double.nan;
            ssq1 = double.nan;
            break;
          }

          ssq0 = _pooledVarEst(lowVars, lowNs);

          // Calculate ssq1 from high-signal spots using log-variance
          // Uses real var(log(values)) computed from raw replicates (matching Shiny)
          final highLvars = <double>[];
          for (int i = 0; i < points.length; i++) {
            if (bHigh[i] && points[i].mean > 0 && points[i].lvar.isFinite && points[i].lvar > 0) {
              highLvars.add(points[i].lvar);
            }
          }

          if (highLvars.isEmpty) {
            ssq0 = double.nan;
            ssq1 = double.nan;
            break;
          }

          highLvars.sort();
          final lssq1 = _median(highLvars);
          ssq1 = exp(lssq1) - 1;
          if (ssq1 < 0) ssq1 = 0;

          // Calculate presence values and reclassify
          final newBLow = List<bool>.filled(points.length, false);
          final newBHigh = List<bool>.filled(points.length, false);

          for (int i = 0; i < points.length; i++) {
            final m = max(0.0, points[i].mean);
            final propComponent = sqrt(ssq1) * m;
            final constComponent = sqrt(ssq0);
            final denom = propComponent + constComponent;
            final presence = denom > 0 ? propComponent / denom : 0.0;

            newBLow[i] = presence < lowThreshold;
            newBHigh[i] = presence > highThreshold;
          }

          // Check if all points are one class (degenerate case)
          if (newBLow.every((b) => !b) || newBHigh.every((b) => !b)) {
            ssq0 = double.nan;
            ssq1 = double.nan;
            break;
          }

          // Check convergence
          final newBModel = List.generate(
            points.length, (i) => newBLow[i] || newBHigh[i]);

          bool converged = true;
          for (int i = 0; i < points.length; i++) {
            if (newBModel[i] != bModel[i]) {
              converged = false;
              break;
            }
          }

          if (converged) {
            bLow = newBLow;
            bHigh = newBHigh;
            break;
          }

          bLow = newBLow;
          bHigh = newBHigh;
          bModel = newBModel;
          iter++;

          if (iter > maxIter) break;
        }
      } catch (e) {
        debugPrint('⚠ Error during iterative fitting: $e');
        ssq0 = double.nan;
        ssq1 = double.nan;
      }

      debugPrint('Final ssq0: ${ssq0.isNaN ? "NaN" : ssq0.toStringAsFixed(4)}');
      debugPrint('Final ssq1: ${ssq1.isNaN ? "NaN" : ssq1.toStringAsFixed(6)}');
      debugPrint('Iterations: $iter');

      // Step 4: Generate classified points and fit curve
      final classifiedPoints = <TercenDataPoint>[];
      for (int i = 0; i < points.length; i++) {
        classifiedPoints.add(TercenDataPoint(
          x: points[i].x,
          y: points[i].y,
          rowIndex: points[i].rowIndex,
          colorIndex: points[i].colorIndex,
          testCondition: points[i].testCondition,
          supergroup: points[i].supergroup,
          rowId: points[i].rowId,
          sd: points[i].sd,
          n: points[i].n,
          lvar: points[i].lvar,
          bLow: bLow[i],
          bHigh: bHigh[i],
        ));
      }

      List<TercenDataPoint>? fitCurve;
      double? sigma0Val;
      double? cv1Val;
      double? snrVal;
      bool didConverge = false;

      if (!ssq0.isNaN && !ssq1.isNaN) {
        sigma0Val = sqrt(ssq0);
        cv1Val = sqrt(ssq1);
        snrVal = ssq1 > 0 ? 1.0 / sqrt(ssq1) : 0.0;
        didConverge = true;

        debugPrint('σ₀ (sqrt(ssq0)): ${sigma0Val.toStringAsFixed(4)}');
        debugPrint('CV₁ (sqrt(ssq1)): ${cv1Val.toStringAsFixed(6)}');
        debugPrint('SNR (1/CV₁): ${snrVal.toStringAsFixed(2)}');

        fitCurve = _generateFitCurve(points, ssq0, ssq1);
        debugPrint('Fit curve: ${fitCurve.length} points');
      } else {
        debugPrint('⚠ Model did not converge - no fit curve');
      }

      return ChartData(
        supergroup: chartData.supergroup,
        testCondition: chartData.testCondition,
        points: classifiedPoints,
        minX: chartData.minX,
        maxX: chartData.maxX,
        minY: chartData.minY,
        maxY: chartData.maxY,
        sigma0: sigma0Val,
        cv1: cv1Val,
        snr: snrVal,
        converged: didConverge,
        fitCurve: fitCurve,
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR fitting model: $e');
      debugPrint('Stack trace: $stackTrace');
      return chartData;
    }
  }

  /// Pooled variance estimate (matching R's pooledVarEst)
  /// est = sum(s2 * (n-1)) / (sum(n) - length(n))
  double _pooledVarEst(List<double> variances, List<int> ns) {
    double numerator = 0;
    int totalN = 0;
    int count = 0;

    for (int i = 0; i < variances.length; i++) {
      final n = ns[i];
      if (n > 1 && variances[i].isFinite) {
        numerator += variances[i] * (n - 1);
        totalN += n;
        count++;
      }
    }

    final denom = totalN - count;
    if (denom <= 0) return 0;
    return numerator / denom;
  }

  /// Generate fit curve using the two-component model
  /// sdFit = sqrt(ssq1 × mean² + ssq0)
  List<TercenDataPoint> _generateFitCurve(
    List<TercenDataPoint> points,
    double ssq0,
    double ssq1,
  ) {
    if (points.isEmpty) return [];

    final means = points.map((p) => p.mean).toList();
    final minMean = means.reduce((a, b) => a < b ? a : b);
    final maxMean = means.reduce((a, b) => a > b ? a : b);

    if (maxMean <= 0 || minMean >= maxMean) return [];

    // Use positive range
    final startMean = max(0.001, minMean);
    const nPoints = 200;
    final curve = <TercenDataPoint>[];

    for (int i = 0; i < nPoints; i++) {
      final t = i / (nPoints - 1);
      final mean = startMean + t * (maxMean - startMean);

      // sdFit = sqrt(ssq1 × mean² + ssq0)
      final sd = sqrt(ssq1 * mean * mean + ssq0);

      curve.add(TercenDataPoint(
        x: mean,
        y: sd,
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

  /// Quantile function (matching R's quantile with default type=7)
  double _quantile(List<double> sortedValues, double p) {
    if (sortedValues.isEmpty) return 0;
    if (sortedValues.length == 1) return sortedValues[0];

    final n = sortedValues.length;
    final index = (n - 1) * p;
    final lo = index.floor();
    final hi = index.ceil();
    final frac = index - lo;

    if (lo == hi || hi >= n) {
      return sortedValues[min(lo, n - 1)];
    }

    return sortedValues[lo] * (1 - frac) + sortedValues[hi] * frac;
  }

  /// Median of a sorted list
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
