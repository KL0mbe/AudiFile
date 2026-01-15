import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:audio_player/core/app_init.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'dart:convert';

class FileData {
  FileData({
    required this.id,
    required this.path,
    required this.title,
    required this.author,
    required this.cover,
    required this.originalCover,
    required this.fastForward,
    required this.rewind,
    this.lastPosition = 0,
    this.isSkip = false,
    this.speed = 1,
  });

  final int id;
  final String path;
  String title;
  List<String> author;
  String cover;
  String originalCover;
  int fastForward;
  int rewind;
  // probably not final either for audiobooks/podcasts
  final double lastPosition;
  bool isSkip;
  double speed;

  String get coverPath => "${mediaDir.path}/$cover";
  String get originalPath => "${mediaDir.path}/$originalCover";

  IconData get getFastForwardIcon {
    if (isSkip) {
      return CupertinoIcons.forward_fill;
    }
    switch (fastForward) {
      case 5:
        return SFIcons.sf_5_arrow_trianglehead_clockwise;
      case 10:
        return CupertinoIcons.goforward_10;
      case 15:
        return CupertinoIcons.goforward_15;
      case 30:
        return CupertinoIcons.goforward_30;
      case 45:
        return CupertinoIcons.goforward_45;
      case 60:
        return CupertinoIcons.goforward_60;
      case 1000:
        return CupertinoIcons.forward_fill;
      default:
        return CupertinoIcons.forward_fill;
    }
  }

  IconData get getRewindIcon {
    if (isSkip) {
      return CupertinoIcons.backward_fill;
    }
    switch (rewind) {
      case 5:
        return SFIcons.sf_5_arrow_trianglehead_counterclockwise;
      case 10:
        return CupertinoIcons.gobackward_10;
      case 15:
        return CupertinoIcons.gobackward_15;
      case 30:
        return CupertinoIcons.gobackward_30;
      case 45:
        return CupertinoIcons.gobackward_45;
      case 60:
        return CupertinoIcons.gobackward_60;
      case 1000:
        return CupertinoIcons.backward_fill;
      default:
        return CupertinoIcons.backward_fill;
    }
  }

  FileData copy() => FileData.fromMap(toJson());

  FileData copyWith({
    String? path,
    String? title,
    List<String>? author,
    String? cover,
    String? originalCover,
    int? fastForward,
    int? rewind,
    double? lastPosition,
    bool? isSkip,
    double? speed,
  }) {
    return FileData(
      id: id,
      path: path ?? this.path,
      title: title ?? this.title,
      author: author ?? this.author,
      cover: cover ?? this.cover,
      originalCover: originalCover ?? this.originalCover,
      fastForward: fastForward ?? this.fastForward,
      rewind: rewind ?? this.rewind,
      lastPosition: lastPosition ?? this.lastPosition,
      isSkip: isSkip ?? this.isSkip,
      speed: speed ?? this.speed,
    );
  }

  factory FileData.fromMap(Map<String, Object?> map) {
    final decoded = jsonDecode(map["author"] as String);
    return FileData(
      id: map["id"] as int,
      path: map["path"] as String,
      title: (map["title"] as String) != ""
          ? (map["title"] as String)
          : basenameWithoutExtension(map["path"] as String),
      author: List<String>.from((decoded != null && decoded is List && decoded.isNotEmpty) ? decoded : ["Unknown"]),
      // could get lib dir in here and set it right away
      cover: map["cover"] as String,
      originalCover: map["original_cover"] as String,
      fastForward: map["fast_forward"] as int,
      rewind: map["rewind"] as int,
      lastPosition: map["last_position"] as double,
      isSkip: (map["is_skip"] as int) == 1,
      speed: map["speed"] as double,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "path": path,
    "title": title,
    "author": jsonEncode(author),
    "cover": cover,
    "original_cover": originalCover,
    "fast_forward": fastForward,
    "rewind": rewind,
    "last_position": lastPosition,
    "is_skip": isSkip == true ? 1 : 0,
    "speed": speed,
  };
}
