import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/ui/views/files/widgets/file_card.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen(this.playlist, {super.key});
  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    return Scaffold(
      appBar: MyAppBar(title: playlist.title, onBackClick: () => Navigator.pop(context)),
      body: Column(
        children: [
          MyTextButton(
            "Add Song To ${playlist.title}",
            backgroundColor: Colors.grey,
            onPressed: () {
              //   open a list of files where the filecards ontap calls a new function that adds it to the playlist
            },
          ),
          ListView.separated(
            separatorBuilder: (_, index) => Gap(12.h),
            shrinkWrap: true,
            itemCount: playlist.songs.length,
            itemBuilder: (context, index) => FileCard(
              file: playlist.songs[index],
              // create new method for this ontap that sets the whole playlist to play not just the file
              onTap: () => context.read<AudioProvider>().setCurrentFile(playlist.songs[index]),
            ),
          ),
        ],
      ),
    );
  }
}
