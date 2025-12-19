import 'package:audio_player/ui/widgets/app_defaults/my_text_field.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:flutter/material.dart';

class TextRow extends StatelessWidget {
  const TextRow(this.label, {this.errorLabel, required this.getValue, required this.onChanged, super.key});

  final String label;
  final String? errorLabel;
  final String Function() getValue;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyBodyText(label, fontSize: 16),
        MyTextField(
          isExpand: true,
          validator: (newValue) {
            if (newValue == null || newValue.isEmpty) return errorLabel ?? "Please Enter a Value";
            return null;
          },
          initialValue: getValue(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
