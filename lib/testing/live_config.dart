class LiveConfig {
  static const liveRun =
      bool.fromEnvironment('HONOO_LIVE_RUN', defaultValue: false);
  static const supaUrl = String.fromEnvironment('HONOO_SUPABASE_URL');
  static const supaAnon = String.fromEnvironment('HONOO_SUPABASE_ANON_KEY');
  static const email = String.fromEnvironment('HONOO_LIVE_EMAIL');
  static const pass = String.fromEnvironment('HONOO_LIVE_PASSWORD');
  static const testImageUrl = String.fromEnvironment('HONOO_TEST_IMAGE_URL');

  static bool get isValid =>
      supaUrl.isNotEmpty &&
      supaAnon.isNotEmpty &&
      email.isNotEmpty &&
      pass.isNotEmpty &&
      testImageUrl.isNotEmpty;
}
