import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Utility/app_diagnostics.dart';
import 'package:honoo/Utility/build_metadata.dart';

void main() {
  tearDown(AppDiagnostics.clearForTests);

  test('build SHA is abbreviated without changing development label', () {
    expect(BuildMetadata.abbreviateSha('1234567890abcdef'), '12345678');
    expect(BuildMetadata.abbreviateSha('development'), 'development');
  });

  test('diagnostics retain only bounded, privacy-safe metadata', () {
    for (var index = 0; index < 45; index++) {
      AppDiagnostics.record(
        code: 'operation_failed',
        scope: 'test',
        error: StateError('sensitive-payload-$index'),
      );
    }

    expect(AppDiagnostics.recentEvents, hasLength(40));
    final event = AppDiagnostics.recentEvents.last;
    expect(event.code, 'operation_failed');
    expect(event.scope, 'test');
    expect(event.errorType, 'StateError');
    expect(event.toString(), isNot(contains('sensitive-payload')));
  });
}
