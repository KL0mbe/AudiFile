import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/ui/views/files/widgets/file_card.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlaylistSongSelectorScreen extends StatefulWidget {
  const PlaylistSongSelectorScreen({required this.playlist, super.key});
  final Playlist playlist;

  @override
  State<PlaylistSongSelectorScreen> createState() => _PlaylistSongSelectorScreenState();
}

class _PlaylistSongSelectorScreenState extends State<PlaylistSongSelectorScreen> {
  void onTapSelectedSong(FileData file) {
    if (widget.playlist.songs.contains(file)) {
      // and remove them from in here if they are in playlist
      context.read<AudioProvider>().removeSongFromPlaylist(widget.playlist, file);
    } else {
      context.read<AudioProvider>().addSongToPlaylist(widget.playlist, file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    return Scaffold(
      appBar: MyAppBar(title: "Select Files To Add", onBackClick: () => Navigator.pop(context)),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, _) => Gap(12.h),
              shrinkWrap: true,
              itemCount: audioProvider.files.length,
              itemBuilder: (context, index) {
                final currentFile = audioProvider.files[index];
                return Row(
                  children: [
                    Icon(
                      widget.playlist.songs.contains(currentFile)
                          ? CupertinoIcons.checkmark_alt_circle_fill
                          : CupertinoIcons.checkmark_alt_circle,
                    ),
                    Expanded(
                      child: FileCard(
                        file: audioProvider.files[index],
                        onTap: () => setState(() => onTapSelectedSong(audioProvider.files[index])),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // selectedSongs.isEmpty
          //     ? SizedBox.shrink()
          //     : Padding(
          //         padding: EdgeInsets.symmetric(vertical: 32.h),
          //         child: MyTextButton(
          //           "Add Selected Songs to ${widget.playlist.title}",
          //           backgroundColor: CupertinoColors.activeBlue,
          //           onPressed: () {
          //             //   for song in selected songs add to playlist
          //           },
          //         ),
          //       ),
        ],
      ),
    );
  }
}
