class TelemetryPlatform {
  static void initSentry(String dsn) {}

  static void captureException(
    Object error,
    StackTrace? stack,
    Map<String, Object?>? context,
  ) {}

  static void addBreadcrumb(
    String category,
    String message,
    Map<String, Object?>? data,
  ) {}
}
