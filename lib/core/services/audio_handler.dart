import 'package:audio_player/core/providers/audio_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:just_audio/just_audio.dart';
import 'database_service.dart';
import 'dart:async';
import 'dart:math';

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
  StreamSubscription<Duration?>? _durationSub;

  AudioPlayer get player => _player;

  MyAudioHandler() {
    _init();
    _notifyAudioHandlerAboutPlaybackEvents();
    _player.currentIndexStream.listen((index) async {
      if (index == null) return;
      if (index == audioProvider.currentIndex) return;
      mediaItem.add(_player.sequence[index].tag as MediaItem);
      audioProvider.updateCurrentIndex(index);
      // extract to method for DRY
      await _durationSub?.cancel();
      _durationSub = _player.durationStream.listen((duration) {
        if (duration == null) return;
        final current = mediaItem.value;
        if (current == null) return;
        mediaItem.add(current.copyWith(duration: duration));
      });
    });
    // update and store position to restore session
    // _player.positionStream.listen((position) {
    // });
  }

  @override
  Future<void> play() async => await _player.play();

  @override
  Future<void> pause() async => await _player.pause();

  @override
  Future<void> stop() async {
    await _durationSub?.cancel();
    _durationSub = null;
    await _player.stop();
    await super.stop();
  }

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

  Future<void> loadQueue(List<AudioSource> playlist, int initialIndex, Duration initialPosition) async {
    List<MediaItem> mediaItems = [];
    await _player.pause();
    await _player.setAudioSources(playlist, initialIndex: initialIndex, initialPosition: initialPosition);
    for (IndexedAudioSource song in _player.sequence) {
      mediaItems.add(song.tag as MediaItem);
    }
    mediaItem.add(_player.sequence[initialIndex].tag as MediaItem);
    queue.add(mediaItems);
    await _durationSub?.cancel();
    _durationSub = _player.durationStream.listen((duration) {
      if (duration == null) return;
      final current = mediaItem.value;
      if (current == null) return;
      mediaItem.add(current.copyWith(duration: duration));
    });
  }

  @override
  // ignore: avoid_renaming_method_parameters
  Future<void> updateMediaItem(MediaItem item) async {
    final merged = item.copyWith(
      duration: item.duration ?? mediaItem.value?.duration,
      extras: item.extras ?? mediaItem.value?.extras,
    );
    mediaItem.add(merged);
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      final file = audioProvider.currentFile;
      final showFF = file != null && file.fastForward != 1000 && !file.isSkip;
      final showRewind = file != null && file.rewind != 1000 && !file.isSkip;
      playbackState.add(
        playbackState.value.copyWith(
          systemActions: {
            MediaAction.pause,
            MediaAction.play,
            MediaAction.seek,
            if (showFF) MediaAction.fastForward,
            if (showRewind) MediaAction.rewind,
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
