import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/core/helpers/ios_remote_intervals.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:audio_player/core/services/database_service.dart';
import 'package:audio_player/core/services/audio_handler.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io';

/// split into file provider, playlist provider etc
class AudioProvider extends ChangeNotifier {
  final dbService = getIt<DatabaseService>();

  List<FileData> _files = [];
  List<FileData> get files => _files;

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  int lastPosition = 0;
  int currentIndex = 0;

  List<FileData> _queue = [];
  List<FileData> get queue => _queue;
  FileData? get currentFile => queue.isEmpty ? null : queue[currentIndex];

  late DefaultDataService defaultSettings;

  Future<void> init() async {
    await loadFiles();
    await loadPlaylists();
    await loadPlaylistSongs();
    await loadCurrentQueue();
    await loadInitialQueue();
    await loadDefaultSettings();
  }

  /// Load Database Data
  Future<void> loadCurrentQueue() async {
    _queue = [];
    final result = await dbService.getCurrentQueue();
    if (result == null) return;

    currentIndex = result["current_index"];
    lastPosition = result["last_position"];

    final items = await dbService.getQueueItems();
    if (items.isEmpty) return;

    if (_files.isEmpty) return;
    for (Map<String, dynamic> song in items) {
      _queue.add(_files.firstWhere((file) => file.id == song["song_id"]));
    }
    notifyListeners();
  }

  // rename queue load method names
  Future<void> loadInitialQueue() async {
    if (_queue.isEmpty) return;
    final audioSourcePlaylist = createAudioSourcePlaylist();
    await (getIt<AudioHandler>() as MyAudioHandler).loadQueue(
      audioSourcePlaylist,
      currentIndex,
      Duration(milliseconds: lastPosition),
    );
    notifyListeners();
  }

  Future<void> loadFiles() async {
    _files = await dbService.getFiles();
    notifyListeners();
  }

  Future<void> loadPlaylists() async {
    _playlists = await dbService.getPlaylists();
    notifyListeners();
  }

  Future<void> loadPlaylistSongs() async {
    playlists.forEach((playlist) => playlist.songs = []);
    final result = await dbService.getPlaylistSongs();
    for (Map<String, dynamic> entry in result) {
      _playlists
          .firstWhere((playlist) => playlist.id == entry["playlist_id"])
          .songs
          .add(_files.firstWhere((file) => file.id == entry["song_id"]));
    }
    notifyListeners();
  }

  Future<void> loadDefaultSettings() async {
    defaultSettings = await dbService.getDefaultSettings();
  }

  /// Current File
  Future<void> updateCurrentIndex(int index) async {
    currentIndex = index;
    await dbService.updateCurrentIndex(index);
    notifyListeners();
  }

  Future<void> setQueue(List<FileData> playlist, int index) async {
    await dbService.clearQueueItems();
    await dbService.updateCurrentIndex(index);

    int queuePosition = 0;
    for (FileData song in playlist) {
      await dbService.insertQueueItem(song.id, queuePosition);
      queuePosition++;
    }
    await loadCurrentQueue();
    final audioSourcePlaylist = createAudioSourcePlaylist();
    await (getIt<AudioHandler>() as MyAudioHandler).loadQueue(
      audioSourcePlaylist,
      currentIndex,
      Duration(milliseconds: lastPosition),
    );
  }

  List<AudioSource> createAudioSourcePlaylist() {
    List<AudioSource> audioSourcePlaylist = [];
    for (FileData file in _queue) {
      audioSourcePlaylist.add(
        AudioSource.file(
          "${mediaDir.path}/${file.path}",
          tag: MediaItem(
            id: file.id.toString(),
            title: file.title,
            artist: file.author.first,
            artUri: Uri.file("${mediaDir.path}/${file.cover}"),
          ),
        ),
      );
    }
    return audioSourcePlaylist;
  }

  Future<void> updateCurrentFile(FileData file, Uint8List artWorkBytes) async {
    // Maybe just pass the FileData directly
    // we just pass it its db that extracts and does
    // what it wants with it
    await dbService.updateFile(
      file.path,
      file.title,
      jsonEncode(file.author),
      file.cover,
      file.fastForward,
      file.rewind,
      file.isSkip,
      true,
    );
    // check if this is correct still with extras?
    final mediaItem = MediaItem(
      id: file.id.toString(),
      title: file.title,
      artist: file.author.first,
      artUri: Uri.file("${mediaDir.path}/${file.cover}"),
      extras: {'path': file.path},
    );
    await getIt<AudioHandler>().updateMediaItem(mediaItem);
    await iosApplyNowPlayingOverride(
      title: file.title,
      artist: file.author.first,
      fastForward: file.fastForward,
      rewind: file.rewind,
      artworkBytes: artWorkBytes,
      isSkip: file.isSkip,
    );
    await loadFiles();
    await loadCurrentQueue();
    notifyListeners();
  }

  /// Playlist
  Future<void> createPlaylist(String title) async {
    final coverPath = "${title}_playlist_cover";
    final data = await rootBundle.load("assets/media/avatar.png");
    final bytes = data.buffer.asUint8List();
    File("${mediaDir.path}/$coverPath").writeAsBytes(bytes);
    await dbService.insertPlaylist(title, coverPath, false);
    await loadPlaylists();
    await loadPlaylistSongs();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    dbService.removePlaylist(playlist.id);
    await loadPlaylists();
    await loadPlaylistSongs();
  }

  Future<void> addSongToPlaylist(Playlist playlist, song) async {
    // Switch to Milliseconds since epoch
    await dbService.insertPlaylistSong(playlist.id, song.id, playlist.songs.length);
    playlist.songs.add(song);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, song) async {
    await dbService.removePlaylistSong(playlist.id, song.id);
    playlist.songs.remove(song);
    notifyListeners();
  }

  /// Default Settings
  Future<void> updateDefaultSettings(DefaultDataService newSettings) async {
    defaultSettings = newSettings;
    await dbService.setDefaultSettings(defaultSettings);
    notifyListeners();
  }

  Future<void> restoreDefaultSettings(FileData file) async {
    bool isSong = [".mp3", ".m4a", ".aac", ".wav", ".flac"].contains(extension(file.path).toLowerCase());
    bool isSkip = defaultSettings.setIsSkip(isSong);
    await dbService.restoreDefaultSettings(file.id, isSkip);

    final bytes = await File(currentFile!.originalPath).readAsBytes();
    await File(currentFile!.coverPath).writeAsBytes(bytes);

    await loadFiles();
    await loadCurrentQueue();
    notifyListeners();
  }

  Future<void> overrideCustomSettings(IsSkip isSkip, int rewind, int fastForward, bool overrideAll) async {
    await dbService.overrideCustomSettings(isSkip.name, rewind, fastForward, overrideAll);
    await loadFiles();
    // maybe doesnt restart ui if you getcurrentfile instead of load?
    // holy shit i dont think it does try this with updating regular settings
    // _currentFile = await dbService.getCurrentIndex();
    await loadCurrentQueue();
  }

  Future<void> pickFiles() async {
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      initialDirectory: appDir.path,
      type: FileType.custom,
      allowedExtensions: [
        // audio files
        "mp3", "m4a", "aac", "wav", "flac",
        // video files
        "mp4", "m4v", "mov", "avi", "mkv",
      ],
    );

    if (result == null) return;

    final files = result.paths.map((path) => File(path!)).toList();
    for (final file in files) {
      final basePath = basename(file.path);
      final dest = File("${mediaDir.path}/${basename(file.path)}");

      if (await dbService.containsFile(basePath)) continue;

      await file.copy(dest.path);
      final metadata = await MetadataRetriever.fromFile(dest);
      final coverPath = "${basenameWithoutExtension(dest.path)}_cover";
      final originalPath = "${basenameWithoutExtension(dest.path)}_original_cover";
      if (metadata.albumArt != null) {
        await File("${mediaDir.path}/$coverPath").writeAsBytes(metadata.albumArt!);
        await File("${mediaDir.path}/$originalPath").writeAsBytes(metadata.albumArt!);
      } else {
        final data = await rootBundle.load("assets/media/avatar.png");
        final bytes = data.buffer.asUint8List();
        File("${mediaDir.path}/$coverPath").writeAsBytes(bytes);
        File("${mediaDir.path}/$originalPath").writeAsBytes(bytes);
      }
      bool isSong = [".mp3", ".m4a", ".aac", ".wav", ".flac"].contains(extension(file.path).toLowerCase());

      await dbService.insertFile(
        basePath,
        metadata.trackName ?? "",
        jsonEncode(metadata.trackArtistNames),
        coverPath,
        originalPath,
        defaultSettings.fastForward,
        defaultSettings.rewind,
        defaultSettings.setIsSkip(isSong),
      );
    }
    await loadFiles();
  }

  // Future<void> pickCoverArt(/*pass in xfile perhaps*/) async {
  //   final picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image == null) return;
  //   final bytes = await image.readAsBytes();
  //   print("pre temp");
  //   await File("${tempDir.path}/${currentFile!.cover}").writeAsBytes(bytes);
  //   print("post temp");
  //   await File(currentFile!.coverPath).writeAsBytes(bytes);
  //   final oldPath = currentFile!.coverPath;
  //   print("pre set temp");
  //   updateCurrentFile(currentFile!.copyWith(cover: "${tempDir.path}/${currentFile!.cover}"));
  //   print("post set temp");
  //   updateCurrentFile(currentFile!.copyWith(cover: oldPath));
  //   print("post old path");
  //   notifyListeners();
  // }
}
