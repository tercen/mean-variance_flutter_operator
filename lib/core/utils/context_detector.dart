/// Detects whether the app is running embedded in Tercen or standalone
/// Following app-frame.md context detection pattern
class AppContextDetector {
  AppContextDetector._();

  /// Checks if the app is running in a Tercen data step (embedded context)
  /// Returns true if taskId URL parameter is present
  static bool get isInDataStep {
    try {
      // Use Uri.base which works in both JS and WASM contexts
      return Uri.base.queryParameters.containsKey('taskId');
    } catch (e) {
      // If we can't parse the URL, assume standalone
      return false;
    }
  }

  /// Determines if the top bar should be shown
  /// Top bar is only shown when NOT in a data step (i.e., standalone/fullscreen mode)
  static bool get shouldShowTopBar => !isInDataStep;
}
