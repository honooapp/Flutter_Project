import 'package:flutter/material.dart';
import 'package:honoo/Controller/device_controller.dart';
import 'package:honoo/Utility/honoo_colors.dart';

class ColonnaCentrata extends StatelessWidget {
  final Widget child;

  const ColonnaCentrata({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container()),
        Container(
          color: HonooColor.background,
          constraints: DeviceController().isPhone()
              ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width)
              : BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.5,
                ),
          child: Center(
            child: child,
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }
}
