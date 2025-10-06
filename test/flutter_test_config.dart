import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ensureInitializedTestSupabase();
  await testMain();
}
