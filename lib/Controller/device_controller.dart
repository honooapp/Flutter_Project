import 'package:flutter/material.dart';

class DeviceController {
  static final DeviceController _instance = DeviceController._internal();

  factory DeviceController() {
    return _instance;
  }

  DeviceController._internal();

  bool isPhone() {
    // Determine if we should use mobile layout or not. The
    // number 600 here is a common breakpoint for a typical
    // 7-inch tablet.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final data = MediaQueryData.fromView(view);
    return data.size.shortestSide < 600;
  }

  double getWidth() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final data = MediaQueryData.fromView(view);
    return data.size.width;
  }

  double getHeight() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final data = MediaQueryData.fromView(view);
    return data.size.height;
  }
}
