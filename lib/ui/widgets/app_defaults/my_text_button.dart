import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'my_body_text.dart';

class MyTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? color;
  final Color? backgroundColor;
  final double fontSize;
  final FontWeight? fontWeight;
  final TextDecoration? textDecoration;
  final TextStyle? style;

  const MyTextButton(
    this.text, {
    this.onPressed,
    this.icon,
    super.key,
    this.color,
    this.backgroundColor,
    this.fontSize = 16,
    this.fontWeight,
    this.textDecoration,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: TextButton.icon(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(backgroundColor?.withValues(alpha: 0.5) ?? Colors.transparent),
          minimumSize: WidgetStatePropertyAll(Size.zero),
          padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(8.h)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: icon,
        iconAlignment: IconAlignment.end,
        onPressed: onPressed,
        label: MyBodyText(
          text,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontSize: fontSize.sp,
          color: color ?? Colors.black,
        ),
      ),
    );
  }
}
