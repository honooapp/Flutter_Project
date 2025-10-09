import 'dart:io';

String env(String k) {
  final fromDefine = _fromDefines(k);
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return Platform.environment[k] ?? '';
}

String _fromDefines(String key) {
  switch (key) {
    case 'SUPABASE_URL':
      return const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    case 'SUPABASE_ANON_KEY':
      return const String.fromEnvironment('SUPABASE_ANON_KEY',
          defaultValue: '');
    case 'TEST_EMAIL':
      return const String.fromEnvironment('TEST_EMAIL', defaultValue: '');
    case 'TEST_BEARER_TOKEN':
      return const String.fromEnvironment('TEST_BEARER_TOKEN', defaultValue: '');
    case 'TEST_IMAGE_URL':
      return const String.fromEnvironment('TEST_IMAGE_URL', defaultValue: '');
    default:
      return '';
  }
}
