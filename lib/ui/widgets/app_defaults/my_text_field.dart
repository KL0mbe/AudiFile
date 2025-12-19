import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final double? width;
  final bool isExpand;
  final double fontSize;
  final Color? textColor;
  final String? hintText;
  final double? borderRadius;
  final String? initialValue;
  final FontWeight? fontWeight;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const MyTextField({
    this.width,
    this.hintText,
    this.onChanged,
    this.validator,
    this.textColor,
    this.controller,
    this.keyboardType,
    this.initialValue,
    this.borderRadius,
    this.fontSize = 14,
    this.isExpand = false,
    this.fontWeight = FontWeight.w500,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(width: 1.5.h),
      borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
    );
    final OutlineInputBorder border = OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius ?? 12.r));
    return Expanded(
      flex: isExpand ? 1 : 0,
      child: Container(
        width: width?.h ?? 100.h,
        padding: EdgeInsets.zero,
        child: TextFormField(
          maxLines: 1,
          onChanged: onChanged,
          validator: validator,
          controller: controller,
          keyboardType: keyboardType,
          initialValue: initialValue,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          textAlign: isExpand ? TextAlign.start : TextAlign.center,
          style: TextStyle(fontSize: fontSize.sp, color: Colors.black, fontWeight: fontWeight),
          decoration: InputDecoration(
            errorBorder: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            focusedErrorBorder: focusedBorder,
            contentPadding: EdgeInsets.only(top: 0.h, left: 0.h),
          ),
        ),
      ),
    );
  }
}
