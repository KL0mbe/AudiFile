import 'package:audio_player/core/models/playlist.dart';
import 'package:audio_player/core/services/default_data_service.dart';
import 'package:audio_player/core/models/file_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseService {
  late final Database _db;

  Future<void> init() async {
    // for testing
    // final dir = await getLibraryDirectory();
    // final dbPath = join(dir.path, 'master_db.db');
    // if (await File(dbPath).exists()) await File(dbPath).delete();
    // print("RESET DATABASE");

    await _openDB();
  }

  Future<void> _openDB() async {
    final databaseDirectory = await getLibraryDirectory();
    final dbPath = join(databaseDirectory.path, "master_db.db");
    _db = await openDatabase(dbPath, version: 1, onConfigure: _onConfigure, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  ///Files
  Future<void> insertFile(
    String path,
    String title,
    String author,
    String cover,
    String originalCover,
    int fastForward,
    int rewind,
    bool isSkip,
  ) async => await _db.execute(
    """INSERT INTO files (path, title, original_title, author, original_author, cover, original_cover, 
    fast_forward, rewind, is_skip) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
    [path, title, title, author, author, cover, originalCover, fastForward, rewind, isSkip],
  );

  Future<void> updateFile(
    String path,
    String title,
    String author,
    String cover,
    int fastForward,
    int rewind,
    bool iSSkip,
    bool isEdit,
  ) async {
    await _db.execute(
      "UPDATE files SET title = ?, author = ?, cover = ?, fast_forward = ?, rewind = ?, is_skip = ?, is_edit = ? WHERE path = ?",
      [title, author, cover, fastForward, rewind, iSSkip, isEdit, path],
    );
  }

  Future<bool> containsFile(String path) async {
    final result = await _db.rawQuery("SELECT * FROM files WHERE path = ?", [path]);
    return result.isNotEmpty;
  }

  Future<List<FileData>> getFiles() async {
    final result = await _db.rawQuery("SELECT * FROM files");
    return result.map((row) => FileData.fromMap(row)).toList();
  }

  /// Queue
  Future<Map<String, dynamic>?> getCurrentQueue() async {
    final result = await _db.rawQuery("SELECT * FROM current_queue");
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<FileData?> getCurrentFile() async {
    final result = await _db.rawQuery("""
      SELECT f.* 
      FROM current_queue AS cq 
      JOIN queue_items AS qi 
      ON cq.id = qi.queue_id 
      AND cq.current_index = qi.position 
      JOIN files as f 
      ON f.id = qi.song_id 
      LIMIT 1""");
    if (result.isEmpty) return null;
    return FileData.fromMap(result.first);
  }

  Future<List<Map<String, dynamic>>> getQueueItems() async {
    final result = await _db.rawQuery("SELECT * FROM queue_items WHERE queue_id = 1 ORDER BY position");
    return result;
  }

  Future<void> insertQueueItem(int songId, position) async => await _db.execute(
    "INSERT OR REPLACE INTO queue_items(queue_id, song_id, position) VALUES(1, ?, ?)",
    [songId, position],
  );

  Future<void> clearQueueItems() async => await _db.execute("DELETE FROM queue_items WHERE queue_id = 1");

  // resets last_position as we click a new index so a new file
  // but for podcasts this cant apply so probably need isSong/isPodcast check
  Future<void> updateCurrentIndex(int index) async =>
      await _db.execute("UPDATE current_queue SET current_index = ?, last_position = 0", [index]);

  /// Playlist
  Future<void> insertPlaylist(String title, String cover, bool isShuffle) async => await _db.execute(
    "INSERT OR REPLACE INTO playlists(title, cover, isShuffle) VALUES(?, ?, ?)",
    [title, cover, isShuffle],
  );

  Future<void> removePlaylist(int id) async => await _db.execute("DELETE FROM playlists WHERE id = ?", [id]);

  Future<void> insertPlaylistSong(int playlistId, int songId, int position) async => await _db.execute(
    "INSERT OR REPLACE INTO playlist_songs(playlist_id, song_id, position) VALUES(?, ?, ?)",
    [playlistId, songId, position],
  );

  Future<void> removePlaylistSong(int playlistId, int songId) async =>
      await _db.execute("DELETE FROM playlist_songs WHERE playlist_id = ? AND song_id = ?", [playlistId, songId]);

  Future<List<Playlist>> getPlaylists() async {
    final result = await _db.rawQuery("SELECT * FROM playlists");
    return result.map((row) => Playlist.fromMap(row)).toList();
  }

  Future<List<Map<String, dynamic>>> getPlaylistSongs() async {
    final result = await _db.rawQuery("SELECT * FROM playlist_songs ps ORDER BY ps.playlist_id, ps.position");
    return result;
  }

  /// Settings
  Future<DefaultDataService> getDefaultSettings() async {
    final result = await _db.rawQuery("SELECT * FROM default_settings WHERE id = 1");
    return DefaultDataService.fromMap(result.first);
  }

  Future<void> setDefaultSettings(DefaultDataService defaultSettings) async {
    await _db.execute("INSERT OR REPLACE INTO default_settings(id, fast_forward, rewind, is_skip) VALUES(1, ?, ?, ?)", [
      defaultSettings.fastForward,
      defaultSettings.rewind,
      defaultSettings.isSkip.name,
    ]);
  }

  Future<void> restoreDefaultSettings(int id, bool isSkip) async {
    await _db.execute(
      """
    UPDATE files 
    SET title = original_title, author = original_author, is_edit = 0, is_skip = ?, 
    fast_forward = (SELECT fast_forward FROM default_settings WHERE id = 1), 
    rewind = (SELECT rewind FROM default_settings WHERE id = 1) 
    WHERE  id = ?""",
      [isSkip, id],
    );
  }

  Future<void> overrideCustomSettings(String isSkip, int rewind, int fastForward, bool overrideAll) async {
    await _db.execute(
      """
    UPDATE files
    SET rewind = ?, fast_forward = ?, is_edit = 1,
    is_skip = 
    CASE ? 
      WHEN 'all' THEN 1 
      WHEN 'none' THEN 0
      WHEN 'song' THEN
      CASE
        WHEN lower(path) LIKE '%.mp3'
          OR lower(path) LIKE '%.m4a'
          OR lower(path) LIKE '%.aac'
          OR lower(path) LIKE '%.wav'
          OR lower(path) LIKE '%.flac'
        THEN 1
        ELSE 0
      END
      ELSE 0
    END
    WHERE (? = 1) OR (is_edit = 0)
    """,
      [rewind, fastForward, isSkip, overrideAll],
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {}

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE files (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      original_title TEXT NOT NULL,
      author TEXT NOT NULL,
      original_author TEXT NOT NULL,
      cover TEXT NOT NULL,
      original_cover TEXT NOT NULL,
      fast_forward INTEGER DEFAULT 15,
      rewind INTEGER DEFAULT 15,
      last_position REAL DEFAULT 0,
      is_skip BOOLEAN DEFAULT 0,
      speed REAL DEFAULT 1,
      is_edit BOOLEAN DEFAULT 0
        )""");
    await db.execute("""
      CREATE TABLE current_queue (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      current_index INTEGER NOT NULL,
      last_position INTEGER NOT NULL DEFAULT 0
    )""");
    await db.execute("INSERT INTO current_queue(current_index, last_position) VALUES(0, 0)");
    await db.execute("""
    CREATE TABLE queue_items (
    queue_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    
    PRIMARY KEY (queue_id, position),
    FOREIGN KEY (queue_id) REFERENCES current_queue(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES files(id) ON DELETE CASCADE
    )""");
    await db.execute(""" 
    CREATE TABLE playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL UNIQUE,
    cover TEXT NOT NULL,
    isShuffle INTEGER NOT NULL
    )""");
    await db.execute("""
    CREATE TABLE playlist_songs(
    playlist_id INTEGER NOT NULL,
    song_id INTEGER NOT NULL,
    position INTEGER NOT NULL, -- Switch to DateTime so we have when it was added along with the position
    
    PRIMARY KEY (playlist_id, song_id),
    
    FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY (song_id) REFERENCES files(id) ON DELETE CASCADE
    )""");
    await db.execute("""
    CREATE INDEX songs_in_playlist
    ON playlist_songs(playlist_id, position
    )""");
    await db.execute("""
    CREATE TABLE default_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    fast_forward INTEGER NOT NULL DEFAULT 15,
    rewind INTEGER NOT NULL DEFAULT 15,
    is_skip TEXT NOT NULL DEFAULT 'none' CHECK (is_skip IN ('all', 'song', 'none'))
    )
    """);
    await db.execute("""
    INSERT INTO default_settings (id, fast_forward, rewind, is_skip) VALUES(1, 15, 15, 'none')
    """);
  }
}
