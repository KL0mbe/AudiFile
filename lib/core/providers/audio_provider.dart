import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:audio_player/core/services/database_service.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:io';

class AudioProvider extends ChangeNotifier {
  final dbService = getIt<DatabaseService>();

  FileData? _currentFile;
  FileData? get currentFile => _currentFile;

  List<FileData> _files = [];
  List<FileData> get files => _files;

  Future<void> init() async {
    await loadFiles();
    await loadCurrentFile();
  }

  Future<void> loadCurrentFile() async {
    _currentFile = await dbService.getCurrentFile();
    if (_currentFile != null) {
      setCurrentFile(_currentFile!);
      notifyListeners();
    }
  }

  Future<void> loadFiles() async {
    _files = await dbService.getFiles();
    notifyListeners();
  }

  Future<void> setCurrentFile(FileData file) async {
    // passing file might be stale (somehow) so use id and get the file
    await dbService.setCurrentFile(file.id);
    final mediaItem = MediaItem(
      id: file.id.toString(),
      title: file.title,
      artist: file.author.first,
      extras: {'path': file.path, "coverPath": file.cover},
    );
    await getIt<AudioHandler>().playMediaItem(mediaItem);
    _currentFile = file;
    notifyListeners();
  }

  Future<void> updateCurrentFile(FileData file) async {
    // Maybe just pass the FileData directly
    // we just pass it its db that extracts and does
    // what it wants with it
    await dbService.updateFile(
      file.path,
      file.title,
      jsonEncode(file.author),
      file.cover,
      file.fastForward.toString(),
      file.rewind.toString(),
      file.isSkip,
    );
    await loadCurrentFile();
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
      if (metadata.albumArt != null) {
        await File("${mediaDir.path}/$coverPath").writeAsBytes(metadata.albumArt!);
      } else {
        final data = await rootBundle.load("assets/media/avatar.png");
        final bytes = data.buffer.asUint8List();
        File("${mediaDir.path}/$coverPath").writeAsBytes(bytes);
      }
      // bool isSong = ["mp3", "m4a", "aac", "wav", "flac"].contains(extension(file.path));
      await dbService.insertFile(basePath, metadata.trackName ?? "", jsonEncode(metadata.trackArtistNames), coverPath);
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
