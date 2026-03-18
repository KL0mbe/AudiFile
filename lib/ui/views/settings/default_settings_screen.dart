import 'package:audio_player/ui/views/playback_settings/widgets/skip_row.dart';
import 'package:audio_player/ui/widgets/app_defaults/confirmation_dialog.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DefaultSettingsScreen extends StatefulWidget {
  const DefaultSettingsScreen({super.key});

  @override
  State<DefaultSettingsScreen> createState() => _DefaultSettingsScreenState();
}

class _DefaultSettingsScreenState extends State<DefaultSettingsScreen> {
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
      appBar: MyAppBar(title: "Import Settings", onBackClick: () => Navigator.pop(context)),
      body: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyBodyText("Default settings for new imports", fontSize: 16),
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
            Gap(12.h),
            (mapEquals(defaultSettingsCopy.toJson(), audioProvider.defaultSettings.toJson()))
                ? SizedBox.shrink()
                : Align(
                    alignment: Alignment.center,
                    child: MyTextButton(
                      "Save",
                      onPressed: () async {
                        final bool? result = await showDialog(
                          context: context,
                          builder: (context) => ConfirmationDialog(
                            title: "Are You Sure You Want To Change Default Settings",
                            description: "All newly imported Files will have these Settings",
                            titleFontSize: 20,
                          ),
                        );
                        if (result == true) {
                          await audioProvider.updateDefaultSettings(defaultSettingsCopy);
                          if (context.mounted) Navigator.pop(context);
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
