import 'package:audio_player/ui/views/settings/override_settings_screen.dart';
import 'package:audio_player/ui/views/settings/default_settings_screen.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/app_init.dart';
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
    return Scaffold(
      appBar: MyAppBar(title: "Settings", onBackClick: () => Navigator.pop(context)),
      body: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          children: [
            // MyBodyText("Color"),
            // Row(
            //   children: [
            //     MyBodyText("Dark Mode"),
            //     // we need app settings
            //     CupertinoSwitch(value: false, onChanged: (newValue) {}),
            //   ],
            // ),
            Gap(32.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MyTextButton(
                  "Import Settings",
                  backgroundColor: Colors.black12,
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DefaultSettingsScreen())),
                ),
                MyTextButton(
                  "Override Settings",
                  backgroundColor: Colors.black12,
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OverrideSettingsScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
