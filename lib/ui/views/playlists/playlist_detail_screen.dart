import 'package:audio_player/ui/views/playlists/playlist_song_selector_screen.dart';
import 'package:audio_player/ui/widgets/app_defaults/confirmation_dialog.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/ui/views/files/widgets/file_card.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlaylistDetailScreen extends StatefulWidget {
  const PlaylistDetailScreen(this.playlist, {super.key});
  final Playlist playlist;

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    return Scaffold(
      appBar: MyAppBar(title: widget.playlist.title, onBackClick: () => Navigator.pop(context)),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: PopupMenuButton(
              itemBuilder: (context) {
                List<PopupMenuEntry<Object>> list = [];
                list.add(
                  PopupMenuItem(
                    child: MyBodyText("Delete Playlist"),
                    onTap: () async {
                      final bool? result = await showDialog<bool>(
                        context: context,
                        builder: (context) => ConfirmationDialog(
                          isDelete: true,
                          title: "Are you sure you want to delete ${widget.playlist.title}",
                          description: "this action is irreversible",
                          confirmButtonText: "Delete",
                          cancelButtonText: "Cancel",
                        ),
                      );
                      if (result == true) {
                        audioProvider.deletePlaylist(widget.playlist);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                );
                return list;
              },
            ),
          ),
          MyTextButton(
            "Add Song To ${widget.playlist.title}",
            backgroundColor: Colors.grey,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlaylistSongSelectorScreen(playlist: widget.playlist)),
            ),
          ),

          ListView.separated(
            separatorBuilder: (_, index) => Gap(12.h),
            shrinkWrap: true,
            itemCount: widget.playlist.songs.length,
            itemBuilder: (context, index) {
              final song = widget.playlist.songs[index];
              return Slidable(
                key: ValueKey(widget.playlist.songs[index].id),
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  dismissible: DismissiblePane(
                    onDismissed: () {
                      setState(() => widget.playlist.songs.remove(song));
                      audioProvider.removeSongFromPlaylist(widget.playlist, song);
                    },
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        setState(() => widget.playlist.songs.remove(song));
                        audioProvider.removeSongFromPlaylist(widget.playlist, song);
                      },
                      backgroundColor: Color(0xFFFE4A49),
                      foregroundColor: Colors.white,
                      icon: CupertinoIcons.delete_solid,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FileCard(
                    file: widget.playlist.songs[index],
                    // create new method for this ontap that sets the whole playlist to play not just the file
                    onTap: () => audioProvider.setCurrentFile(widget.playlist.songs[index]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
