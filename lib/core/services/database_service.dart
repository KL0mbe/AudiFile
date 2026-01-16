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

  Future<FileData?> getCurrentFile() async {
    final result = await _db.rawQuery('SELECT f.* FROM files f JOIN current_file c ON f.id = c.file_id WHERE c.id = 1');
    if (result.isEmpty) return null;
    return FileData.fromMap(result.first);
  }

  Future<DefaultDataService> getDefaultSettings() async {
    final result = await _db.rawQuery("SELECT * FROM default_settings WHERE id = 1");
    return DefaultDataService.fromMap(result.first);
  }

  Future<void> setCurrentFile(int id) async =>
      await _db.execute("INSERT OR REPLACE INTO current_file(id, file_id) VALUES(1, ?)", [id]);

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
    SET title = original_title, author = original_author, is_edit = FALSE, is_skip = ?, 
    fast_forward = (SELECT fast_forward FROM default_settings WHERE id = 1), 
    rewind = (SELECT rewind FROM default_settings WHERE id = 1) 
    WHERE  id = ?""",
      [isSkip, id],
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
      is_skip BOOLEAN DEFAULT FALSE,
      speed REAL DEFAULT 1,
      is_edit BOOLEAN DEFAULT FALSE
        )""");
    await db.execute("""
      CREATE TABLE current_file (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      file_id INTEGER,
      FOREIGN KEY (file_id)
      REFERENCES files(id)
      ON DELETE SET NULL
      ON UPDATE CASCADE
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
