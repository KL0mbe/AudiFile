import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/ui/views/files/widgets/file_card.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    return Scaffold(
      appBar: MyAppBar(title: "Files"),
      body: SafeArea(
        child: Column(
          children: [
            MyTextButton(
              "Pick A File",
              backgroundColor: Colors.grey,
              onPressed: () async => await context.read<AudioProvider>().pickFiles(),
            ),
            Gap(16.h),
            ListView.separated(
              separatorBuilder: (_, index) => Gap(12.h),
              shrinkWrap: true,
              itemCount: audioProvider.files.length,
              itemBuilder: (context, index) => FileCard(
                file: audioProvider.files[index],
                onTap: () async => await context.read<AudioProvider>().setCurrentFile(audioProvider.files[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
