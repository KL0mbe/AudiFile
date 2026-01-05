import 'package:audio_player/ui/views/playback_settings/widgets/skip_row.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late DefaultDataService defaultSettingsCopy;

  @override
  void initState() {
    defaultSettingsCopy = getIt<AudioProvider>().defaultSettings.copy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    return Scaffold(
      appBar: MyAppBar(title: "Settings", onBackClick: () => Navigator.pop(context)),
      body: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          children: [
            // MyBodyText("Color"),
            // Row(
            //   children: [
            //     MyBodyText("Dark Mode"),
            //     // we need app settings
            //     CupertinoSwitch(value: false, onChanged: (newValue) {}),
            //   ],
            // ),
            Gap(16.h),
            MyBodyText("Default settings for new files", fontSize: 18),
            Row(
              children: [
                MyBodyText("Is Skip: ", fontSize: 16),
                SizedBox(
                  width: 100.h,
                  child: DropdownButton(
                    value: defaultSettingsCopy.isSkip,
                    items: [
                      DropdownMenuItem(value: IsSkip.all, child: Text("all")),
                      DropdownMenuItem(value: IsSkip.song, child: Text("song")),
                      DropdownMenuItem(value: IsSkip.none, child: Text("none")),
                    ],
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      setState(() => defaultSettingsCopy.isSkip = newValue);
                    },
                  ),
                ),
              ],
            ),
            Gap(12.h),
            SkipRow(
              "Rewind: ",
              specialValue: "Rewind",
              getValue: () => defaultSettingsCopy.rewind,
              onChanged: (newValue) {
                if (newValue == null) return;
                setState(() => defaultSettingsCopy.rewind = newValue);
              },
            ),
            Gap(12.h),
            SkipRow(
              "fast Forward: ",
              specialValue: "Skip",
              getValue: () => defaultSettingsCopy.fastForward,
              onChanged: (newValue) {
                if (newValue == null) return;
                setState(() => defaultSettingsCopy.fastForward = newValue);
              },
            ),
            (mapEquals(defaultSettingsCopy.toJson(), audioProvider.defaultSettings.toJson()))
                ? SizedBox.shrink()
                : MyTextButton(
                    "Save",
                    onPressed: () async {
                      await audioProvider.updateDefaultSettings(defaultSettingsCopy);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
