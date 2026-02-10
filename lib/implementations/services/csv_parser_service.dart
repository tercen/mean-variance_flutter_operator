import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/models/tercen_data.dart';

class CsvParserService {
  static Future<TercenDataset> parseExampleData() async {
    // Load CSV files from assets
    final qtCsv = await rootBundle.loadString('_local/Example files/qt.csv');
    final columnCsv =
        await rootBundle.loadString('_local/Example files/column.csv');

    // Parse column data (supergroups and test conditions)
    final columnLines = LineSplitter().convert(columnCsv);
    final supergroups = <String>{};
    final testConditions = <String>{};

    for (var i = 1; i < columnLines.length; i++) {
      final line = columnLines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCsvLine(line);
      if (parts.length >= 2) {
        supergroups.add(parts[0]);
        testConditions.add(parts[1]);
      }
    }

    // Parse qt data (quantitative data points)
    final qtLines = LineSplitter().convert(qtCsv);
    final headers = _parseCsvLine(qtLines[0]);

    // Find column indices
    final yIdx = headers.indexOf('.y');
    final riIdx = headers.indexOf('.ri');
    final ciIdx = headers.indexOf('.ci');
    final testConditionIdx = headers.indexOf('js0.Test Condition');
    final supergroupIdx = headers.indexOf('js0.Supergroup');
    final xsIdx = headers.indexOf('.xs');
    final ysIdx = headers.indexOf('.ys');

    // Group data points by pane (supergroup + test condition)
    final Map<String, List<TercenDataPoint>> panePoints = {};

    for (var i = 1; i < qtLines.length; i++) {
      final line = qtLines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCsvLine(line);
      if (parts.length <= yIdx) continue;

      final y = double.tryParse(parts[yIdx]) ?? 0.0;
      final rowIndex = int.tryParse(parts[riIdx]) ?? 0;
      final colorIndex = int.tryParse(parts[ciIdx]) ?? 0;
      final testCondition = parts[testConditionIdx];
      final supergroup = parts[supergroupIdx];
      final xs = int.tryParse(parts[xsIdx]) ?? 0;

      // Convert xs to normalized X value (0-1 range for simplicity)
      final x = xs / 65535.0;

      final point = TercenDataPoint(
        x: x,
        y: y,
        rowIndex: rowIndex,
        colorIndex: colorIndex,
        testCondition: testCondition,
        supergroup: supergroup,
        // Mock values for new fields
        rowId: 'row_$rowIndex',
        sd: y * 0.1, // Mock SD as 10% of y value
        n: 3, // Mock replicate count
        bLow: false,
        bHigh: false,
      );

      final paneKey = '$supergroup.$testCondition';
      panePoints.putIfAbsent(paneKey, () => []).add(point);
    }

    // Create ChartData for each pane
    final Map<String, ChartData> chartData = {};

    for (final entry in panePoints.entries) {
      final parts = entry.key.split('.');
      final supergroup = parts[0];
      final testCondition = parts[1];
      final points = entry.value;

      if (points.isEmpty) continue;

      // Calculate axis ranges
      final xValues = points.map((p) => p.x).toList();
      final yValues = points.map((p) => p.y).toList();

      final minX = xValues.reduce((a, b) => a < b ? a : b);
      final maxX = xValues.reduce((a, b) => a > b ? a : b);
      final minY = yValues.reduce((a, b) => a < b ? a : b);
      final maxY = yValues.reduce((a, b) => a > b ? a : b);

      chartData[entry.key] = ChartData(
        supergroup: supergroup,
        testCondition: testCondition,
        points: points,
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
      );
    }

    return TercenDataset(
      supergroups: supergroups.toList(),
      testConditions: testConditions.toList(),
      chartData: chartData,
    );
  }

  // Parse a CSV line, handling quoted fields
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    if (current.isNotEmpty) {
      result.add(current.trim());
    }

    return result;
  }
}
