import 'package:audio_player/ui/views/playback_settings/widgets/skip_row.dart';
import 'package:audio_player/ui/widgets/app_defaults/confirmation_dialog.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OverrideSettingsScreen extends StatefulWidget {
  const OverrideSettingsScreen({super.key});

  @override
  State<OverrideSettingsScreen> createState() => _OverrideSettingsScreenState();
}

class _OverrideSettingsScreenState extends State<OverrideSettingsScreen> {
  late IsSkip isSkip;
  late int rewind;
  late int fastForward;
  bool overrideAll = false;

  @override
  void initState() {
    final defaultSettings = getIt<AudioProvider>().defaultSettings.copy();
    isSkip = defaultSettings.isSkip;
    rewind = defaultSettings.rewind;
    fastForward = defaultSettings.fastForward;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: "Override Settings", onBackClick: () => Navigator.pop(context)),
      body: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyBodyText("Override settings for existing files", fontSize: 16),
            Row(
              children: [
                MyBodyText("Is Skip: ", fontSize: 16),
                SizedBox(
                  width: 100.h,
                  child: DropdownButton(
                    value: isSkip,
                    items: [
                      DropdownMenuItem(value: IsSkip.all, child: Text("all")),
                      DropdownMenuItem(value: IsSkip.song, child: Text("song")),
                      DropdownMenuItem(value: IsSkip.none, child: Text("none")),
                    ],
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      setState(() => isSkip = newValue);
                    },
                  ),
                ),
              ],
            ),
            Gap(12.h),
            SkipRow(
              "Rewind: ",
              specialValue: "Rewind",
              getValue: () => rewind,
              onChanged: (newValue) {
                if (newValue == null) return;
                setState(() => rewind = newValue);
              },
            ),
            Gap(12.h),
            SkipRow(
              "fast Forward: ",
              specialValue: "Skip",
              getValue: () => fastForward,
              onChanged: (newValue) {
                if (newValue == null) return;
                setState(() => fastForward = newValue);
              },
            ),
            Gap(12.h),
            MyBodyText("include files with custom settings?:"),
            Gap(12.h),
            CupertinoSwitch(value: overrideAll, onChanged: (newValue) => setState(() => overrideAll = newValue)),
            Gap(32.h),
            // probably delete
            // (mapEquals(defaultSettingsCopy.toJson(), audioProvider.defaultSettings.toJson()))
            Align(
              alignment: Alignment.center,
              child: MyTextButton(
                "Override",
                onPressed: () async {
                  final bool? result = await showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                      title: "Are You Sure You Want To Override File Settings",
                      description: "This Will ${overrideAll ? null : "not"} Override Files With Custom Settings",
                    ),
                  );
                  if (result == true) {
                    if (context.mounted) {
                      await context.read<AudioProvider>().overrideCustomSettings(
                        isSkip,
                        rewind,
                        fastForward,
                        overrideAll,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
