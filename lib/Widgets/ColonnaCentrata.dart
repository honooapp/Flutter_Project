import 'package:flutter/material.dart';
import 'package:honoo/Controller/DeviceController.dart';
import 'package:honoo/Utility/HonooColors.dart';

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
