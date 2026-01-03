import 'package:flutter/services.dart';
import 'dart:io';

const _ch = MethodChannel('now_playing_override');

Future<void> iosApplyNowPlayingOverride({
  required String title,
  required String artist,
  required int fastForward,
  required int rewind,
  required Uint8List artworkBytes,
  required bool isSkip,
}) async {
  if (!Platform.isIOS) return;

  await _ch.invokeMethod('apply', {
    'title': title,
    'artist': artist,
    'ffSeconds': fastForward.toDouble(),
    'rwSeconds': rewind.toDouble(),
    'artworkBytes': artworkBytes,
    'isSkip': isSkip,
  });
}
