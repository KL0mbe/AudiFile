import 'package:audio_player/ui/views/playback_settings/playback_settings_screen.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/ui/views/playlists/playlists_screen.dart';
import 'package:audio_player/ui/views/settings/settings_screen.dart';
import 'package:audio_player/ui/views/home/playback_section.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:audio_player/ui/views/files/files_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Scaffold(
      appBar: AppBar(title: MyBodyText.semiBold("Audio Player")),
      drawer: Drawer(
        width: 150.h,
        child: Column(
          children: [
            Gap(64.h),
            MyTextButton(
              "Files",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FilesScreen())),
            ),
            Gap(12.h),
            MyTextButton(
              "Playlists",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistsScreen())),
            ),
            Gap(12.h),
            MyTextButton(
              "Settings",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: audioProvider.currentFile == null
              ? MyBodyText("Select a file to play")
              : Column(
                  children: [
                    Align(
                      alignment: AlignmentGeometry.topRight,
                      child: MyTextButton(
                        "Edit",
                        icon: Icon(Icons.edit, color: Colors.black),
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PlaybackSettingsScreen())),
                      ),
                    ),
                    Gap(32.h),
                    MyBodyText.semiBold(audioProvider.currentFile!.title),
                    Gap(24.h),
                    SizedBox(
                      width: 300.h,
                      height: 300.h,
                      child: Image.memory(
                        File(audioProvider.currentFile!.coverPath).readAsBytesSync(),
                        gaplessPlayback: true,
                      ),
                    ),
                    Gap(24.h),
                    PlaybackSection(),
                  ],
                ),
        ),
      ),
    );
  }
}
