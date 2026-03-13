import 'package:audio_player/ui/views/playlists/playlist_detail_screen.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard(this.playlist, {super.key});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlist))),
        child: Container(
          padding: EdgeInsetsGeometry.all(8.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: Colors.blueGrey),
          child: MyBodyText(basename(playlist.title)),
        ),
      ),
    );
  }
}
