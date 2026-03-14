import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String? confirmButtonText;
  final String? cancelButtonText;
  final bool isDelete;

  const ConfirmationDialog({
    required this.title,
    required this.description,
    this.confirmButtonText,
    this.cancelButtonText,
    this.isDelete = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.blueGrey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 34.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MyBodyText(title, fontSize: 21, fontWeight: FontWeight.w600, align: TextAlign.center, color: Colors.white),
            Gap(12.h),
            MyBodyText(description, fontSize: 15, align: TextAlign.center, color: Colors.white),
            Gap(24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: MyBodyText(
                        cancelButtonText ?? 'Cancel',
                        fontSize: 17,
                        color: Colors.white,
                        align: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Gap(24.h),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: isDelete == true ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: MyBodyText(
                        confirmButtonText ?? 'Confirm',
                        fontSize: 17,
                        color: Colors.white,
                        align: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
