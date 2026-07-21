class BuildMetadata {
  const BuildMetadata._();

  static const version = '1.1.0+2';
  static const sha = String.fromEnvironment(
    'BUILD_SHA',
    defaultValue: 'development',
  );
  static const ref = String.fromEnvironment('BUILD_REF', defaultValue: 'local');

  static String get shortSha => abbreviateSha(sha);

  static String get displayLabel => 'v$version · $shortSha';

  static String abbreviateSha(String value) {
    if (value == 'development' || value.isEmpty) return 'development';
    return value.length <= 8 ? value : value.substring(0, 8);
  }
}
