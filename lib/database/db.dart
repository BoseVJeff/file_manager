import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

class DB {
  late Database _dbObject;

  /// Path to the executable
  /// Note that the drive letter is `DB._execPath.scheme` and the path without the drive letter is `DB._execPath.path`/`.pathSegments` as desired.
  late Uri _execPath;

  /// Path to the database file
  /// Includes the name of the DB
  late Uri? _dbPath;

  late PreparedStatement _systemInputPreparedStatement;

  late PreparedStatement _systemSearchPreparedStatement;

  late PreparedStatement _fileInputPreparedStatement;

  late PreparedStatement _fileSearchPreparedStatement;

  late String? _systemName;
  late String _systemOs;

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

  static const String sqlCreateTablesv1 = """
CREATE TABLE IF NOT EXISTS tbl_system (
system_id INTEGER PRIMARY KEY AUTOINCREMENT,
system_name TEXT,
system_os TEXT
);

CREATE TABLE IF NOT EXISTS tbl_file (
file_id INTEGER PRIMARY KEY AUTOINCREMENT,
system_id INTEGER REFERENCES tbl_system,
file_drive_root TEXT,
file_full_path TEXT,
file_name TEXT,
file_mime_type TEXT,
file_hash TEXT
);
""";

// Adds key constraint
  static const String sqlCreateTablesv2 = """
CREATE TABLE IF NOT EXISTS "tbl_system" (
	"system_id"	INTEGER NOT NULL UNIQUE,
	"system_name"	TEXT,
	"system_os"	INTEGER,
	CONSTRAINT "system_name_os_combo_unique" UNIQUE("system_name","system_os"),
	PRIMARY KEY("system_id" AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS tbl_file (
file_id INTEGER PRIMARY KEY AUTOINCREMENT,
system_id INTEGER REFERENCES tbl_system,
file_drive_root TEXT,
file_full_path TEXT,
file_name TEXT,
file_mime_type TEXT,
file_hash TEXT
);
""";

  void init() async {
    _dbObject.execute(sqlCreateTablesv2);
    _dbObject.userVersion = 2;

    if (Platform.isWindows) {
      _systemName = Platform.environment['COMPUTERNAME'];
    } else {
      dynamic systemNameProcessResult =
          (await Process.run("hostnamectl", ["hostname"])).stdout;
      if (systemNameProcessResult is List<int>) {
        _systemName = null;
      } else {
        assert(systemNameProcessResult is String);
        _systemName = systemNameProcessResult;
      }
    }

    _systemOs = Platform.operatingSystem;

    _systemInputPreparedStatement = _dbObject.prepare("""
INSERT INTO tbl_system (system_name, system_os) VALUES (?,?);
""");

    _fileInputPreparedStatement = _dbObject.prepare("""
INSERT INTO tbl_file (
system_id, file_drive_root, file_full_path, file_name, file_mime_type, file_hash
) VALUES (
(SELECT system_name FROM tbl_system WHERE system_name=? AND system_os=?),
?,?,?,?,?
);""");

    _systemSearchPreparedStatement = _dbObject.prepare(
        "SELECT * FROM tbl_system WHERE system_name=? AND system_os=?");

    if (searchSystem(_systemName, _systemOs) == null) {
      _systemInputPreparedStatement.execute([_systemName, _systemOs]);
    }
  }

  int? searchSystem(String? systemName, String systemOs) {
    final ResultSet res =
        _systemSearchPreparedStatement.select([systemName, systemOs]);
    if (res.isEmpty) {
      return null;
    }
    return res.first.columnAt(0) as int;
  }

  Iterable<(int index, String fullPath)>? searchFile(
    String fileName, {
    String? driveRoot,
    String? mimeType,
  }) {
    String searchSqlString = "SELECT file_id, file_full_path FROM tbl_file";

    List<Object?> params = [];

    const List<String> conditions = [];

    conditions.add("file_name LIKE '?%'");
    params.add(fileName);

    if (driveRoot != null) {
      conditions.add("file_drive_root = ?");
      params.add(driveRoot);
    }

    if (mimeType != null) {
      conditions.add("file_mime_type = ?");
      params.add(mimeType);
    }

    if (conditions.isNotEmpty) {
      searchSqlString = "$searchSqlString WHERE ${conditions.join(" AND ")}";
    }

    final ResultSet resultSet = _dbObject.select(searchSqlString, params);

    if (resultSet.isEmpty) {
      return null;
    }

    return resultSet.map((Row row) {
      return (row.columnAt(0) as int, row.columnAt(1) as String);
    });
  }

  void addFileSystemEntity(FileSystemEntity entity) async {
    // TODO: Missing values for mime type, and file hash
    _fileInputPreparedStatement.execute([
      _systemName,
      _systemOs,
      rootPrefix(entity.path),
      entity.path,
      basename(entity.path),
      lookupMimeType(basename(entity.path)),
      null,
    ]);
  }

  // String getFilePathById(int id) {
  //   final res = _dbObject.select("SELECT ");
  // }

  static String dumpVersionInfoString() {
    return sqlite3.version.toString();
  }

  void dispose() {
    _dbObject.dispose();
    _systemInputPreparedStatement.dispose();
    _fileInputPreparedStatement.dispose();
  }

  String get dbPath => (_dbPath != null)
      ? _dbPath!.replace(scheme: _dbPath!.scheme.toUpperCase()).toString()
      : ":memory:";
}
