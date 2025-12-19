import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class SkipRow extends StatelessWidget {
  const SkipRow(this.label, {required this.getValue, required this.onChanged, required this.specialValue, super.key});
  final String label;
  final String specialValue;
  final int Function() getValue;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyBodyText(label, fontSize: 16),
        SizedBox(
          width: getValue() == 1000 ? 85.h : 50.h,
          child: DropdownButton(
            isExpanded: true,
            value: getValue(),
            items: [
              DropdownMenuItem(value: 5, child: Text("5")),
              DropdownMenuItem(value: 10, child: Text("10")),
              DropdownMenuItem(value: 15, child: Text("15")),
              DropdownMenuItem(value: 30, child: Text("30")),
              DropdownMenuItem(value: 45, child: Text("45")),
              DropdownMenuItem(value: 60, child: Text("60")),
              DropdownMenuItem(value: 1000, child: Text(specialValue)),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
