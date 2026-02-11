import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sci_tercen_client/sci_client.dart' show CubeQueryTask, RunWebAppTask;
import 'package:sci_tercen_client/sci_client_service_factory.dart' show ServiceFactory;
import '../../domain/models/tercen_data.dart';
import '../../main.dart';

/// Service for extracting and transforming Tercen data following CRITICAL patterns:
/// - Issue #10: Metadata-to-Data ID Resolution
/// - Issue #11: Schema Service Filtering (schema APIs filter dot-prefixed columns BY DESIGN)
/// - Pattern: column-data-extraction.md
/// - Pattern: metadata-data-resolution.md
class TercenDataService {
  final ServiceFactory _serviceFactory;

  TercenDataService(this._serviceFactory);

  /// Factory constructor using GetIt singleton
  factory TercenDataService.fromGetIt() {
    return TercenDataService(getIt.get<ServiceFactory>());
  }

  /// Extract data from Tercen task context
  ///
  /// Returns TercenDataset with:
  /// - supergroups → rows in grid
  /// - groups → columns in grid
  /// - Each chart cell contains all rows (genes/proteins) as points
  Future<TercenDataset> extractTercenData({
    required String taskId,
    double lowThreshold = 0.0,
    double highThreshold = double.infinity,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('TERCEN DATA EXTRACTION START');
      debugPrint('========================================');
      debugPrint('Task ID: $taskId');

      // Step 1: Get task and navigate hierarchy
      final cubeTask = await _navigateToCubeQueryTask(taskId);

      // Step 2: Extract data via tableSchemaService API
      final extractedData = await _extractDataViaApi(cubeTask);

      // Step 3: Build grid structure
      final dataset = _buildGridStructure(
        extractedData,
        lowThreshold,
        highThreshold,
      );

      debugPrint('========================================');
      debugPrint('TERCEN DATA EXTRACTION COMPLETE');
      debugPrint('Grid dimensions: ${dataset.nSupergroups} × ${dataset.nGroups}');
      debugPrint('Total charts: ${dataset.nSupergroups * dataset.nGroups}');
      debugPrint('========================================');

      return dataset;
    } catch (e, stackTrace) {
      debugPrint('ERROR extracting Tercen data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Navigate task hierarchy to get CubeQueryTask
  /// Handles: RunWebAppTask → CubeQueryTask OR direct CubeQueryTask
  Future<CubeQueryTask> _navigateToCubeQueryTask(String taskId) async {
    debugPrint('');
    debugPrint('STEP 1: Navigate task hierarchy');
    debugPrint('--------------------------------');

    final task = await _serviceFactory.taskService.get(taskId);
    debugPrint('✓ Fetched task: ${task.runtimeType}');

    CubeQueryTask? cubeTask;

    if (task is RunWebAppTask) {
      debugPrint('  Task is RunWebAppTask, navigating to CubeQueryTask...');

      if (task.cubeQueryTaskId.isEmpty) {
        throw Exception('RunWebAppTask has empty cubeQueryTaskId');
      }

      final cubeTaskObj = await _serviceFactory.taskService.get(task.cubeQueryTaskId);

      if (cubeTaskObj is! CubeQueryTask) {
        throw Exception('Referenced task is not a CubeQueryTask: ${cubeTaskObj.runtimeType}');
      }

      cubeTask = cubeTaskObj;
      debugPrint('✓ Retrieved CubeQueryTask: ${cubeTask.id}');
    } else if (task is CubeQueryTask) {
      debugPrint('  Task is already CubeQueryTask');
      cubeTask = task;
    } else {
      throw Exception('Task is neither RunWebAppTask nor CubeQueryTask: ${task.runtimeType}');
    }

    return cubeTask;
  }

  /// Extract cross-tab data using tableSchemaService API
  /// Uses query.qtHash to fetch .y, .ri, .ci from the computed data table,
  /// and query.columnHash to resolve group/condition labels.
  Future<_ExtractedData> _extractDataViaApi(CubeQueryTask cubeTask) async {
    debugPrint('');
    debugPrint('STEP 2: Extract data via tableSchemaService API');
    debugPrint('--------------------------------');

    final query = cubeTask.query;
    final qtHash = query.qtHash;

    if (qtHash.isEmpty) {
      throw Exception('CubeQuery has empty qtHash');
    }

    debugPrint('qtHash: $qtHash');
    debugPrint('columnHash: ${query.columnHash}');
    debugPrint('rowHash: ${query.rowHash}');

    // Step 2a: Get schema to determine row count
    final qtSchema = await _serviceFactory.tableSchemaService.get(qtHash);
    final nRows = qtSchema.nRows;
    debugPrint('✓ Schema nRows: $nRows');
    debugPrint('  Schema columns: ${qtSchema.columns.map((c) => c.name).toList()}');

    if (nRows == 0) {
      throw Exception('Cross-tab table has 0 rows');
    }

    // Step 2b: Fetch .y, .ri, .ci from the cross-tab data table
    debugPrint('Fetching .y, .ri, .ci from qtHash ($nRows rows)...');
    final qtData = await _serviceFactory.tableSchemaService.select(
      qtHash, ['.y', '.ri', '.ci'], 0, nRows,
    );

    List<double>? yValues;
    List<dynamic>? riValues;
    List<dynamic>? ciValues;

    for (final col in qtData.columns) {
      final values = col.values as List?;
      if (values == null || values.isEmpty) continue;

      switch (col.name) {
        case '.y':
          yValues = values.map((v) => (v as num).toDouble()).toList();
          debugPrint('✓ Fetched .y: ${yValues.length} values');
          break;
        case '.ri':
          riValues = List.from(values);
          debugPrint('✓ Fetched .ri: ${riValues.length} values');
          break;
        case '.ci':
          ciValues = List.from(values);
          debugPrint('✓ Fetched .ci: ${ciValues.length} values');
          break;
      }
    }

    if (yValues == null) throw Exception('.y column not returned by select');
    if (riValues == null) throw Exception('.ri column not returned by select');
    if (ciValues == null) throw Exception('.ci column not returned by select');

    // Promote to non-nullable locals for use in closures
    final yVals = yValues;
    final ciVals = ciValues;

    // Step 2c: Fetch column table to resolve .ci → group/supergroup labels
    final columnHash = query.columnHash;
    List<String> supergroupValues;
    List<String> groupValues;

    if (columnHash.isNotEmpty) {
      final colSchema = await _serviceFactory.tableSchemaService.get(columnHash);
      final nCols = colSchema.nRows;
      debugPrint('✓ Column table: $nCols entries');

      // Find user-defined factor columns (non-dot-prefixed)
      final factorNames = colSchema.columns
          .map((c) => c.name)
          .where((name) => !name.startsWith('.'))
          .toList();
      debugPrint('  Factor columns: $factorNames');

      if (factorNames.isNotEmpty && nCols > 0) {
        final colData = await _serviceFactory.tableSchemaService.select(
          columnHash, factorNames, 0, nCols,
        );

        // Build map: ci index → {factorName: value}
        final Map<int, Map<String, String>> ciLabelMap = {};
        for (int ci = 0; ci < nCols; ci++) {
          ciLabelMap[ci] = {};
        }
        for (final col in colData.columns) {
          final vals = col.values as List?;
          if (vals == null) continue;
          for (int i = 0; i < vals.length; i++) {
            ciLabelMap[i]![col.name] = vals[i]?.toString() ?? '';
          }
        }

        debugPrint('  Label map: $ciLabelMap');

        // Map each data point's .ci to supergroup and group labels
        // If 2+ factors: first is supergroup, rest combined as group
        // If 1 factor: that's the group, supergroup is 'Default'
        if (factorNames.length >= 2) {
          final sgFactor = factorNames[0];
          final grpFactors = factorNames.sublist(1);
          debugPrint('  Supergroup factor: $sgFactor');
          debugPrint('  Group factors: $grpFactors');

          supergroupValues = List.generate(yVals.length, (i) {
            final ci = _toInt(ciVals[i]);
            return ciLabelMap[ci]?[sgFactor] ?? 'Default';
          });
          groupValues = List.generate(yVals.length, (i) {
            final ci = _toInt(ciVals[i]);
            final labels = ciLabelMap[ci] ?? {};
            return grpFactors.map((f) => labels[f] ?? '').join('.');
          });
        } else {
          supergroupValues = List.filled(yVals.length, 'Default');
          groupValues = List.generate(yVals.length, (i) {
            final ci = _toInt(ciVals[i]);
            return ciLabelMap[ci]?[factorNames[0]] ?? 'Group$ci';
          });
        }
      } else {
        debugPrint('⚠ No factor columns in column table, using .ci as labels');
        supergroupValues = List.filled(yVals.length, 'Default');
        groupValues = List.generate(yVals.length, (i) {
          return 'Group${_toInt(ciVals[i])}';
        });
      }
    } else {
      debugPrint('⚠ No columnHash, using defaults');
      supergroupValues = List.filled(yVals.length, 'Default');
      groupValues = List.filled(yVals.length, 'Group1');
    }

    debugPrint('✓ Data extraction complete: ${yVals.length} data points');

    return _ExtractedData(
      yValues: yValues,
      riValues: riValues,
      ciValues: ciValues,
      supergroupValues: supergroupValues,
      groupValues: groupValues,
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.parse(v.toString());
  }

  /// Build grid data structure from extracted data
  /// Grid: nSupergroups (rows) × nGroups (columns)
  /// Each chart contains all rows as points with x=mean, y=SD
  TercenDataset _buildGridStructure(
    _ExtractedData data,
    double lowThreshold,
    double highThreshold,
  ) {
    debugPrint('');
    debugPrint('STEP 3: Build grid structure');
    debugPrint('--------------------------------');

    // Map replicates: supergroup → group → rowId → List<y values>
    final Map<String, Map<String, Map<String, List<double>>>> replicatesMap = {};

    for (int i = 0; i < data.yValues.length; i++) {
      final y = data.yValues[i];
      final rowId = data.riValues[i].toString();
      final supergroup = data.supergroupValues[i];
      final group = data.groupValues[i];

      replicatesMap
          .putIfAbsent(supergroup, () => {})
          .putIfAbsent(group, () => {})
          .putIfAbsent(rowId, () => [])
          .add(y);
    }

    debugPrint('✓ Mapped replicates by supergroup × group × row');
    debugPrint('  Supergroups: ${replicatesMap.keys.length}');

    // Get unique supergroups and groups in order
    final supergroups = replicatesMap.keys.toList()..sort();
    final allGroups = <String>{};
    for (final sgMap in replicatesMap.values) {
      allGroups.addAll(sgMap.keys);
    }
    final groups = allGroups.toList()..sort();

    debugPrint('  Groups: ${groups.length}');
    debugPrint('  Grid dimensions: ${supergroups.length} × ${groups.length}');

    // Calculate summary statistics for each supergroup × group
    final Map<String, ChartData> chartData = {};
    int totalPointsCreated = 0;
    int pointsExcludedLowN = 0;

    for (final supergroup in supergroups) {
      for (final group in groups) {
        final rowMap = replicatesMap[supergroup]?[group] ?? {};
        final points = <TercenDataPoint>[];

        for (final entry in rowMap.entries) {
          final rowId = entry.key;
          final measurements = entry.value;

          // Need at least 2 replicates to calculate SD
          if (measurements.length < 2) {
            pointsExcludedLowN++;
            continue;
          }

          // Calculate mean and SD
          final mean = measurements.reduce((a, b) => a + b) / measurements.length;
          final variance = measurements
              .map((x) => pow(x - mean, 2))
              .reduce((a, b) => a + b) / (measurements.length - 1);
          final sd = sqrt(variance);

          // Skip if values are NaN or infinite
          if (!mean.isFinite || !sd.isFinite) {
            pointsExcludedLowN++;
            continue;
          }

          // Create point with classification flags
          final bLow = mean < lowThreshold;
          final bHigh = mean > highThreshold;

          points.add(TercenDataPoint(
            x: mean,
            y: sd, // Will be transformed based on plot type
            rowIndex: points.length,
            colorIndex: 0, // Will be set based on supergroup×group position
            testCondition: group,
            supergroup: supergroup,
            rowId: rowId,
            sd: sd,
            n: measurements.length,
            bLow: bLow,
            bHigh: bHigh,
          ));

          totalPointsCreated++;
        }

        if (points.isEmpty) continue;

        // Calculate axis ranges
        final xValues = points.map((p) => p.x).toList();
        final yValues = points.map((p) => p.y).toList();

        final minX = xValues.reduce((a, b) => a < b ? a : b);
        final maxX = xValues.reduce((a, b) => a > b ? a : b);
        final minY = yValues.reduce((a, b) => a < b ? a : b);
        final maxY = yValues.reduce((a, b) => a > b ? a : b);

        final paneKey = '$supergroup.$group';
        chartData[paneKey] = ChartData(
          supergroup: supergroup,
          testCondition: group,
          points: points,
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
        );
      }
    }

    debugPrint('✓ Created ${chartData.length} chart cells');
    debugPrint('  Total points: $totalPointsCreated');
    if (pointsExcludedLowN > 0) {
      debugPrint('  ⚠ Excluded $pointsExcludedLowN points (n < 2 or invalid values)');
    }

    return TercenDataset(
      supergroups: supergroups,
      testConditions: groups,
      chartData: chartData,
    );
  }
}

/// Container for extracted raw data
class _ExtractedData {
  final List<double> yValues;
  final List<dynamic> riValues;
  final List<dynamic> ciValues;
  final List<String> supergroupValues;
  final List<String> groupValues;

  _ExtractedData({
    required this.yValues,
    required this.riValues,
    required this.ciValues,
    required this.supergroupValues,
    required this.groupValues,
  });
}
