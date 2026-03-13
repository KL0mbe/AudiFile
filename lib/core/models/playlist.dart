import 'package:audio_player/core/models/file_data.dart';

class Playlist {
  Playlist({required this.id, required this.title, required this.songs, required this.cover, required this.isShuffle});

  final int id;
  String title;
  List<FileData> songs;
  String cover;
  bool isShuffle;

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map["id"] as int,
      title: map["title"] as String,
      songs: [], //not needed we load all songs on init and append as needed to the model while running.
      cover: map["cover"] as String,
      isShuffle: (map["isShuffle"] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "title": title, "cover": cover, "isShuffle": isShuffle == true ? 1 : 0};
}
