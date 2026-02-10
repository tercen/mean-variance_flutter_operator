import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sci_tercen_client/sci_client.dart' show CubeQueryTask, RunWebAppTask, Task;
import '../../domain/models/tercen_data.dart';
import '../../main.dart';

/// Service for extracting and transforming Tercen data following CRITICAL patterns:
/// - Issue #10: Metadata-to-Data ID Resolution
/// - Issue #11: Schema Service Filtering (schema APIs filter dot-prefixed columns BY DESIGN)
/// - Pattern: column-data-extraction.md
/// - Pattern: metadata-data-resolution.md
class TercenDataService {
  final dynamic _serviceFactory;

  TercenDataService(this._serviceFactory);

  /// Factory constructor using GetIt singleton
  factory TercenDataService.fromGetIt() {
    return TercenDataService(getIt.get());
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

      // Step 2: Extract data from task JSON (CRITICAL: NOT schema API!)
      final extractedData = await _extractDataFromTaskJson(cubeTask);

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

  /// Extract data from task JSON using proper patterns
  /// CRITICAL: Schema APIs filter dot-prefixed columns BY DESIGN (Issue #11)
  /// Must use task.toJson() and navigate relation hierarchy
  Future<_ExtractedData> _extractDataFromTaskJson(CubeQueryTask cubeTask) async {
    debugPrint('');
    debugPrint('STEP 2: Extract data from task JSON');
    debugPrint('--------------------------------');
    debugPrint('CRITICAL: Using task.toJson() (schema APIs filter dot-prefixed columns)');

    // Convert to JSON to access unfiltered columns
    final taskJson = cubeTask.toJson();
    final queryJson = taskJson['query'] as Map?;

    if (queryJson == null || queryJson['relation'] == null) {
      throw Exception('Task has no query relation');
    }

    // Navigate relation hierarchy to find InMemoryTable
    debugPrint('Navigating relation hierarchy...');
    var currentRelation = queryJson['relation'] as Map?;
    int depth = 0;
    const maxDepth = 20;

    while (currentRelation != null && depth < maxDepth) {
      final kind = currentRelation['kind'] as String?;
      debugPrint('  Depth $depth: $kind');

      if (kind == 'InMemoryRelation' && currentRelation['inMemoryTable'] != null) {
        debugPrint('✓ Found InMemoryTable at depth $depth');
        break;
      }

      // Navigate deeper through wrappers
      if (currentRelation['relation'] != null) {
        currentRelation = currentRelation['relation'] as Map?;
      } else if (kind == 'CompositeRelation' && currentRelation['mainRelation'] != null) {
        currentRelation = currentRelation['mainRelation'] as Map?;
      } else if (kind == 'GatherRelation' && currentRelation['relation'] != null) {
        currentRelation = currentRelation['relation'] as Map?;
      } else {
        break;
      }

      depth++;
    }

    if (currentRelation == null || currentRelation['inMemoryTable'] == null) {
      throw Exception('Could not find InMemoryTable in relation hierarchy (max depth: $maxDepth)');
    }

    // Extract columns from InMemoryTable
    final inMemoryTable = currentRelation['inMemoryTable'] as Map;
    final columns = inMemoryTable['columns'] as List?;

    if (columns == null || columns.isEmpty) {
      throw Exception('InMemoryTable has no columns');
    }

    debugPrint('✓ Found ${columns.length} columns in InMemoryTable');

    // Extract required columns
    List<double>? yValues;
    List<dynamic>? riValues;
    List<dynamic>? ciValues;
    List<String>? supergroupValues;
    List<String>? groupValues;

    for (final col in columns) {
      final colMap = col as Map;
      final name = colMap['name'] as String?;
      final values = colMap['values'] as List?;

      if (name == null || values == null) continue;

      if (name == '.y') {
        yValues = values.cast<double>();
        debugPrint('✓ Extracted .y: ${yValues.length} values');
      } else if (name == '.ri') {
        riValues = values;
        debugPrint('✓ Extracted .ri: ${riValues.length} values');
      } else if (name == '.ci') {
        ciValues = values;
        debugPrint('✓ Extracted .ci: ${ciValues.length} values');
      } else if (name.startsWith('js') && values.isNotEmpty) {
        // User columns (non-dot-prefixed)
        // Try to identify supergroup and group columns
        // For now, we'll use a heuristic: first user column is supergroup, second is group
        if (supergroupValues == null) {
          supergroupValues = values.map((v) => v?.toString() ?? '').toList();
          debugPrint('✓ Extracted supergroup column "$name": ${supergroupValues.length} values');
        } else if (groupValues == null) {
          groupValues = values.map((v) => v?.toString() ?? '').toList();
          debugPrint('✓ Extracted group column "$name": ${groupValues.length} values');
        }
      }
    }

    // Validate required columns
    if (yValues == null) {
      throw Exception('Required column .y not found');
    }
    if (riValues == null) {
      throw Exception('Required column .ri not found');
    }
    if (ciValues == null) {
      throw Exception('Required column .ci not found');
    }

    // If no user columns found, create defaults
    if (supergroupValues == null) {
      debugPrint('⚠ No supergroup column found, using default');
      supergroupValues = List.filled(yValues.length, 'Default');
    }
    if (groupValues == null) {
      debugPrint('⚠ No group column found, using default');
      groupValues = List.filled(yValues.length, 'Group1');
    }

    // Validate lengths match
    if (yValues.length != riValues.length ||
        yValues.length != ciValues.length ||
        yValues.length != supergroupValues.length ||
        yValues.length != groupValues.length) {
      throw Exception(
        'Column length mismatch: .y=${yValues.length}, .ri=${riValues.length}, '
        '.ci=${ciValues.length}, supergroups=${supergroupValues.length}, groups=${groupValues.length}'
      );
    }

    return _ExtractedData(
      yValues: yValues,
      riValues: riValues,
      ciValues: ciValues,
      supergroupValues: supergroupValues,
      groupValues: groupValues,
    );
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
