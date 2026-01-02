import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:just_audio/just_audio.dart';
import 'database_service.dart';
import 'dart:math';
import 'dart:io';

Future<AudioHandler> initAudioHandler() async {
  final dbService = getIt<DatabaseService>();
  final currentFile = await dbService.getCurrentFile();
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      rewindInterval: Duration(seconds: currentFile?.rewind ?? 5),
      fastForwardInterval: Duration(seconds: currentFile?.fastForward ?? 5),
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final audioProvider = getIt<AudioProvider>();

  AudioPlayer get player => _player;

  MyAudioHandler() {
    _init();
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  @override
  Future<void> play() async => await _player.play();

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> seek(Duration position) async => await _player.seek(position);

  @override
  Future<void> fastForward() async {
    if (audioProvider.currentFile!.isSkip) {
      // this doesnt make sense to me why both
      // it would skip to the end of the next track no?
      // also can clamp using duration directly no need for seconds
      await _player.seekToNext();
      await _player.seek(Duration(seconds: _player.duration!.inSeconds));
      return;
    }
    await _player.seek(
      Duration(
        seconds: min(
          (_player.position + Duration(seconds: audioProvider.currentFile!.fastForward)).inSeconds,
          _player.duration!.inSeconds,
        ),
      ),
    );
  }

  @override
  Future<void> rewind() async {
    if (audioProvider.currentFile!.isSkip) {
      await _player.seek(Duration(seconds: 0));
      return;
    }
    await _player.seek(
      Duration(seconds: max((_player.position - Duration(seconds: audioProvider.currentFile!.rewind)).inSeconds, 0)),
    );
  }

  @override
  Future<void> skipToNext() async => await fastForward();

  @override
  Future<void> skipToPrevious() async => await rewind();

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> playMediaItem(MediaItem item) async {
    _player.pause();
    final path = "${mediaDir.path}/${item.extras?["path"]}";
    final coverPath = "${mediaDir.path}/${item.extras?["coverPath"]}";
    final exists = await File(path).exists();
    print("Play path: $path");
    print("cover path: $coverPath");
    print("Exists on disk: $exists");
    mediaItem.add(item.copyWith(artUri: Uri.file(coverPath)));

    await _player.setAudioSource(AudioSource.file(path));
    _player.durationStream.listen((duration) {
      if (duration == null) return;
      final current = mediaItem.value;
      if (current == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          systemActions: {
            MediaAction.pause,
            MediaAction.play,
            MediaAction.seek,
            if (audioProvider.currentFile != null && audioProvider.currentFile!.fastForward != 1000)
              MediaAction.fastForward,
            if (audioProvider.currentFile != null && audioProvider.currentFile!.rewind != 1000) MediaAction.rewind,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
          processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }
}
