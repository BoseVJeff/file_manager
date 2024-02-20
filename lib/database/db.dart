import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class DB {
  late Database _dbObject;

  /// Path to the executable
  /// Note that the drive letter is `DB._execPath.scheme` and the path without the drive letter is `DB._execPath.path`/`.pathSegments` as desired.
  late Uri _execPath;

  /// Path to the database file
  /// Includes the name of the DB
  late Uri? _dbPath;

  // DB(String dbName) {
  DB([String? dbRelativePath]) {
    // TODO: Make this work on web using WASM builds
    // It will be useless there so maybe using an imported database would be nice
    _execPath = Uri.parse(Platform.resolvedExecutable).normalizePath();

    if (dbRelativePath != null) {
      _dbPath = _execPath.resolve(dbRelativePath);

      _dbObject = sqlite3.open(_dbPath.toString());
    } else {
      _dbPath = null;

      _dbObject = sqlite3.openInMemory();
    }
  }

  static String dumpVersionInfoString() {
    return sqlite3.version.toString();
  }

  void dispose() {
    _dbObject.dispose();
  }

  String get dbPath => (_dbPath != null)
      ? _dbPath!.replace(scheme: _dbPath!.scheme.toUpperCase()).toString()
      : ":memory:";
}
