import 'package:audio_player/ui/widgets/app_defaults/my_icon_button.dart';
import 'package:audio_player/ui/widgets/app_defaults/my_body_text.dart';
import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:math';

class PlaybackSection extends StatefulWidget {
  const PlaybackSection({super.key});

  @override
  State<PlaybackSection> createState() => _PlaybackSectionState();
}

class _PlaybackSectionState extends State<PlaybackSection> {
  final handler = getIt<AudioHandler>();
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool playing = false;
  bool isScrubbing = false;
  double dragValue = 0;

  @override
  void initState() {
    super.initState();
    AudioService.position.listen((p) => setState(() => position = p));
    handler.playbackState.listen((state) => setState(() => playing = state.playing));
    handler.mediaItem.listen((item) {
      if (item?.duration != null) setState(() => duration = item!.duration!);
    });
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes : $seconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Slider(
            value: isScrubbing ? dragValue : position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
            min: 0,
            max: max(1, duration.inSeconds.toDouble()),
            onChanged: (newValue) {
              isScrubbing = true;
              dragValue = newValue;
              setState(() {});
            },
            onChangeEnd: (newValue) async {
              isScrubbing = false;
              await handler.seek(Duration(seconds: newValue.toInt()));
            },
          ),
        ),
        Gap(12.h),
        MyBodyText(formatDuration(isScrubbing ? Duration(seconds: dragValue.toInt()) : position)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            MyIconButton(icon: audioProvider.currentFile!.getRewindIcon, onPressed: () => handler.rewind()),
            MyIconButton(
              icon: handler.playbackState.value.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_arrow_solid,
              onPressed: () => handler.playbackState.value.playing ? handler.pause() : handler.play(),
            ),
            MyIconButton(icon: audioProvider.currentFile!.getFastForwardIcon, onPressed: () => handler.fastForward()),
          ],
        ),
      ],
    );
  }
}
