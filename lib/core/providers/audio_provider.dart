import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/core/helpers/ios_remote_intervals.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:audio_player/core/services/database_service.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:audio_player/core/models/playlist.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io';

/// split into file provider, playlist provider etc
class AudioProvider extends ChangeNotifier {
  final dbService = getIt<DatabaseService>();

  FileData? _currentFile;
  FileData? get currentFile => _currentFile;

  List<FileData> _files = [];
  List<FileData> get files => _files;

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  late DefaultDataService defaultSettings;

  Future<void> init() async {
    await loadFiles();
    await loadPlaylists();
    await loadPlaylistSongs();
    await loadCurrentFile();
    await loadDefaultSettings();
  }

  Future<void> loadCurrentFile() async {
    _currentFile = await dbService.getCurrentFile();
    if (_currentFile != null) {
      await setCurrentFile(_currentFile!);
    }
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
    final result = await dbService.getPlaylistSongs();
    for (Map<String, dynamic> entry in result) {
      _playlists
          .firstWhere((playlist) => playlist.id == entry["playlist_id"])
          .songs
          .add(_files.firstWhere((file) => file.id == entry["song_id"]));
    }
  }

  Future<void> loadDefaultSettings() async {
    defaultSettings = await dbService.getDefaultSettings();
  }

  Future<void> setCurrentFile(FileData file) async {
    // passing file might be stale (somehow) so use id and get the file
    await dbService.setCurrentFile(file.id);
    final mediaItem = MediaItem(
      id: file.id.toString(),
      title: file.title,
      artist: file.author.first,
      artUri: Uri.file("${mediaDir.path}/${file.cover}"),
      extras: {'path': file.path},
    );
    await getIt<AudioHandler>().playMediaItem(mediaItem);
    _currentFile = file;
    notifyListeners();
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
    // refactor this as we use it in setcurrentfile too
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
    await loadCurrentFile();
    notifyListeners();
  }

  Future<void> createPlaylist(String title) async {
    final coverPath = "${title}_playlist_cover";
    final data = await rootBundle.load("assets/media/avatar.png");
    final bytes = data.buffer.asUint8List();
    File("${mediaDir.path}/$coverPath").writeAsBytes(bytes);
    await dbService.insertPlaylist(title, coverPath, false);
    notifyListeners();
  }

  Future<void> updateDefaultSettings(DefaultDataService newSettings) async {
    defaultSettings = newSettings;
    await dbService.setDefaultSettings(defaultSettings);
    notifyListeners();
  }

  Future<void> restoreDefaultSettings(FileData file) async {
    bool isSong = [".mp3", ".m4a", ".aac", ".wav", ".flac"].contains(extension(file.path).toLowerCase());
    bool isSkip = defaultSettings.setIsSkip(isSong);
    await dbService.restoreDefaultSettings(file.id, isSkip);

    final bytes = await File(_currentFile!.originalPath).readAsBytes();
    await File(_currentFile!.coverPath).writeAsBytes(bytes);

    await loadCurrentFile();
    notifyListeners();
  }

  Future<void> overrideCustomSettings(IsSkip isSkip, int rewind, int fastForward, bool overrideAll) async {
    await dbService.overrideCustomSettings(isSkip.name, rewind, fastForward, overrideAll);
    await loadFiles();
    // maybe doesnt restart ui if you getcurrentfile instead of load?
    // holy shit i dont think it does try this with updating regular settings
    _currentFile = await dbService.getCurrentFile();
    // await loadCurrentFile();
    notifyListeners();
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
