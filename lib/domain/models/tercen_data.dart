// Domain models for Tercen data structure

class TercenDataPoint {
  final double x; // mean value
  final double y; // transformed value (SD, CV, or SNR)
  final int rowIndex; // Row index for internal use
  final int colorIndex; // Color index for visualization
  final String testCondition; // Group/test condition
  final String supergroup; // Supergroup

  // New fields for real implementation
  final String rowId; // Row identifier from .ri (e.g., gene/protein name)
  final double sd; // Standard deviation
  final int n; // Replicate count
  final bool bLow; // true if mean < lowThreshold
  final bool bHigh; // true if mean > highThreshold

  TercenDataPoint({
    required this.x,
    required this.y,
    required this.rowIndex,
    required this.colorIndex,
    required this.testCondition,
    required this.supergroup,
    required this.rowId,
    required this.sd,
    required this.n,
    this.bLow = false,
    this.bHigh = false,
  });

  // Convenience getters
  double get mean => x;
}

class ChartData {
  final String supergroup;
  final String testCondition; // Also known as "group"
  final List<TercenDataPoint> points;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  // Optional fit results
  final double? sigma0; // Low signal noise
  final double? cv1; // High signal coefficient of variation
  final double? snr; // Signal-to-noise ratio (1/CV1)
  final bool? converged; // Whether fitting converged
  final List<TercenDataPoint>? fitCurve; // Fit curve points (if fit enabled)

  ChartData({
    required this.supergroup,
    required this.testCondition,
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.sigma0,
    this.cv1,
    this.snr,
    this.converged,
    this.fitCurve,
  });

  String get paneKey => '$supergroup.$testCondition';
  String get group => testCondition; // Alias for clarity
}

class TercenDataset {
  final List<String> supergroups;
  final List<String> testConditions; // Also known as "groups"
  final Map<String, ChartData> chartData; // Key: "Sgroup1.Group1", etc.

  TercenDataset({
    required this.supergroups,
    required this.testConditions,
    required this.chartData,
  });

  // Alias for clarity
  List<String> get groups => testConditions;

  List<String> getSupergroupsOrdered() {
    // Return supergroups in natural order
    return supergroups..sort();
  }

  List<String> getTestConditionsOrdered() {
    // Return groups in natural order
    final ordered = List<String>.from(testConditions);
    ordered.sort((a, b) {
      if (a == 'Control') return -1;
      if (b == 'Control') return 1;
      return a.compareTo(b);
    });
    return ordered;
  }

  List<String> getGroupsOrdered() => getTestConditionsOrdered();

  ChartData? getChartData(String supergroup, String testCondition) {
    return chartData['$supergroup.$testCondition'];
  }

  // Grid dimensions
  int get nSupergroups => supergroups.length;
  int get nGroups => testConditions.length;
}
