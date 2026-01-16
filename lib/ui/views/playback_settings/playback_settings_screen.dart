import 'package:audio_player/ui/views/playback_settings/widgets/skip_row.dart';
import 'package:audio_player/ui/views/playback_settings/widgets/text_row.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:io';

class PlaybackSettingsScreen extends StatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  State<PlaybackSettingsScreen> createState() => _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState extends State<PlaybackSettingsScreen> {
  late FileData currentFileCopy;
  late Uint8List tempBytes;
  late Uint8List originalBytes;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    currentFileCopy = getIt<AudioProvider>().currentFile!.copy();
    // maybe change to readasbytes in initstateasync later
    tempBytes = File(currentFileCopy.coverPath).readAsBytesSync();
    // breaks comparison supposedly but not in practice?
    originalBytes = tempBytes;
  }

  void pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    tempBytes = await image.readAsBytes();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: MyAppBar(title: "Edit Playback Settings", onBackClick: () => Navigator.pop(context)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            shrinkWrap: true,
            children: [
              if (currentFileCopy.isEdit)
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: MyTextButton(
                    "Restore Settings",
                    fontSize: 12,
                    onPressed: () async {
                      // TODO: add alertdialog warning
                      await audioProvider.restoreDefaultSettings(currentFileCopy.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              Gap(16.h),
              TextRow(
                "Title: ",
                errorLabel: "Please enter a title",
                getValue: () => currentFileCopy.title,
                onChanged: (newString) => setState(() => currentFileCopy.title = newString),
              ),
              Gap(12.h),
              TextRow(
                "Authors: ",
                errorLabel: "Author cant be empty",
                getValue: () => currentFileCopy.author.join(", "),
                onChanged: (authorList) => setState(
                  () => currentFileCopy.author = authorList
                      .split(",")
                      .map((string) => string.trim())
                      .where((string) => string.isNotEmpty)
                      .toList(),
                ),
              ),
              Gap(12.h),
              Row(
                children: [
                  MyBodyText("Cover: ", fontSize: 16),
                  GestureDetector(
                    onTap: () => pickImage(),
                    child: SizedBox(width: 300.h, height: 300.h, child: Image.memory(tempBytes, gaplessPlayback: true)),
                  ),
                ],
              ),
              Gap(12.h),
              Row(
                children: [
                  MyBodyText("Is Skip: ${currentFileCopy.isSkip}", fontSize: 16),
                  CupertinoSwitch(
                    value: currentFileCopy.isSkip,
                    onChanged: (newValue) => setState(() => currentFileCopy.isSkip = newValue),
                  ),
                ],
              ),
              Gap(12.h),
              if (currentFileCopy.isSkip == false) ...[
                SkipRow(
                  "Rewind: ",
                  specialValue: "Rewind",
                  getValue: () => currentFileCopy.rewind,
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    setState(() => currentFileCopy.rewind = newValue);
                  },
                ),
                Gap(12.h),
                SkipRow(
                  "fast Forward: ",
                  specialValue: "Skip",
                  getValue: () => currentFileCopy.fastForward,
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    setState(() => currentFileCopy.fastForward = newValue);
                  },
                ),
              ],
              Gap(12.h),
              (mapEquals(currentFileCopy.toJson(), audioProvider.currentFile!.toJson()) &&
                      listEquals(originalBytes, tempBytes))
                  ? SizedBox.shrink()
                  : MyTextButton(
                      "Save",
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        await File(currentFileCopy.coverPath).writeAsBytes(tempBytes);
                        if (currentFileCopy.fastForward == 1000 && currentFileCopy.rewind == 1000) {
                          currentFileCopy.isSkip = true;
                        }
                        await audioProvider.updateCurrentFile(currentFileCopy, tempBytes);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
