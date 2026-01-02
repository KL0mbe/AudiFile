import 'package:flutter/services.dart';
import 'dart:io';

const _ch = MethodChannel("audio_intervals");

Future<void> setForwardInterval({required bool enabled, required int seconds}) async {
  if (!Platform.isIOS) return;
  await _ch.invokeMethod("setForwardInterval", {"enabled": enabled, "seconds": seconds.toDouble()});
}

Future<void> setBackwardInterval({required bool enabled, required int seconds}) async {
  if (!Platform.isIOS) return;
  await _ch.invokeMethod("setBackwardInterval", {"enabled": enabled, "seconds": seconds.toDouble()});
}
