import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

extension PumpSizer on WidgetTester {
  Future<void> pumpSizer(Widget child, {ThemeData? theme}) async {
    await pumpWidget(
      Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: theme,
            home: child,
          );
        },
      ),
    );

    await pumpAndSettle();
  }
}
