import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:honoo/Services/app_failure.dart';
import 'package:honoo/Services/reliability_policy.dart';

void main() {
  group('AppFailure', () {
    test('classifies transport and parsing failures', () {
      expect(AppFailure.from(const SocketException('offline')).kind,
          AppFailureKind.offline);
      expect(AppFailure.from(TimeoutException('slow')).kind,
          AppFailureKind.timeout);
      expect(AppFailure.from(const FormatException('bad json')).kind,
          AppFailureKind.invalidData);
    });

    test('preserves an existing application failure', () {
      const failure = AppFailure(AppFailureKind.rlsDenied);
      expect(AppFailure.from(failure), same(failure));
    });
  });

  group('ReliabilityPolicy', () {
    test('retries a failed read once', () async {
      var attempts = 0;
      final result = await const ReliabilityPolicy(
        readTimeout: Duration(seconds: 1),
      ).read(() async {
        attempts++;
        if (attempts == 1) throw const SocketException('offline');
        return 42;
      });

      expect(result, 42);
      expect(attempts, 2);
    });

    test('does not retry writes', () async {
      var attempts = 0;
      await expectLater(
        const ReliabilityPolicy(writeTimeout: Duration(seconds: 1))
            .write(() async {
          attempts++;
          throw const SocketException('offline');
        }),
        throwsA(isA<AppFailure>()),
      );
      expect(attempts, 1);
    });
  });
}
