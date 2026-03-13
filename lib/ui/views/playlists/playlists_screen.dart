import 'package:audio_player/ui/views/playlists/widgets/playlist_card.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_text_field.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_app_bar.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _formkey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: "Playlists", onBackClick: () => Navigator.pop(context)),
      body: SafeArea(
        child: Column(
          children: [
            MyTextButton(
              "Create Playlist",
              backgroundColor: Colors.grey,
              onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(16.h),
                      child: SizedBox(
                        width: 250.h,
                        height: 200.h,
                        child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MyBodyText("Enter Playlist Name", fontSize: 18),
                              Gap(12.h),
                              MyTextField(
                                width: 200.h,
                                controller: _controller,
                                validator: (newValue) {
                                  if (newValue == null || newValue.isEmpty) {
                                    return "Enter a name for your playlist";
                                  }
                                  if (context.read<AudioProvider>().playlists.any(
                                    (playlist) => playlist.title.toLowerCase() == newValue.toLowerCase(),
                                  )) {
                                    "$newValue playlist already exists";
                                  }
                                  return null;
                                },
                                hintText: "Bluegrass",
                              ),
                              Gap(12.h),
                              MyTextButton(
                                "Create",
                                onPressed: () async {
                                  if (!_formkey.currentState!.validate()) return;
                                  context.read<AudioProvider>().createPlaylist(_controller.text.trim());
                                  _controller.clear();
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Gap(16.h),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, index) => Gap(12.h),
                shrinkWrap: true,
                itemCount: context.watch<AudioProvider>().playlists.length, //PlaceHolder
                itemBuilder: (context, index) => PlaylistCard(context.read<AudioProvider>().playlists[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
