import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart';

/// The provider for all things related to the base File Database
///
/// This is a [ChangeNotifier] because this meant to be injected into the widget tree.
/// Doing so avoids all the pitfalls of using a singleton while at the same time ensuring that only one instance is active at any given time.
class FileDatabaseProvider extends ChangeNotifier {
  /// The database that everything will happen in
  final Database _database;

  /// The logger for this class
  final Logger _logger = Logger("FileDatabaseProvider");

  /// List of files that are awating to be scanned into the database
  ///
  /// This is treated akin to a stack where items are popped off as they are scanned into the database.
  /// Scanning stops when this list is empty.
  ///
  /// This is a seperate list as the file scanning happens in a seperate isolate where the database object is unavailable.
  /// For more info on the scanning object see [FileDatabaseProvider.scanForFilesCompute].
  final List<FileSystemEntity> _filesToBeScanned = [];

  /// Statements to migrate DB version `i` to DB version `i+1`.
  ///
  /// The key here is the version the DB is currently at.
  /// The result of this migration should be to upgrade the database to the next version.
  ///
  /// Statements used here *should not* require any arguments.
  ///
  /// The statement corresponding to the index `0` should be the base creation statement and not have any `ALTER` statements.
  ///
  /// Ideally, these statements are append-only and not modified once defined/released.
  // late Map<int, List<PreparedStatement>> _dbMigrationStmts;
  static final Map<int, List<String>> dbMigrationSql = {
    0: [
      """
CREATE TABLE IF NOT EXISTS tbl_path (
  path_id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT,
  path_scanned_on_date TEXT DEFAULT CURRENT_TIMESTAMP
);""",
      """
CREATE TABLE IF NOT EXISTS tbl_file (
  file_id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_drive_root TEXT,
  file_full_path TEXT,
  file_mime_type TEXT,
  file_hash TEXT,
  path_id INTEGER REFERENCES tbl_path ON DELETE CASCADE
);
"""
    ],
  };

  // late PreparedStatement _databaseInsertFileStatement;

  // late PreparedStatement _databaseFileSearchStatement;

  // late PreparedStatement _databaseFileDumpStatement;

  // late PreparedStatement _databaseInsertScanPathStatement;

  // // TODO: Count the rows for each path_id in tbl_files
  // late PreparedStatement _databaseCountFilesFromPath;

  // late PreparedStatement _databasePathDumpStatement;

  // late PreparedStatement _databaseRemovePath;

  // late PreparedStatement _databaseUpdatePath;

  // late PreparedStatement _databaseDeletePathChildrenStatement;

  FileDatabaseProvider([String? databasePath])
      : _database = (databasePath != null)
            ? sqlite3.open(databasePath)
            : sqlite3.openInMemory() {
    _logger.info(
        "Initialising database ${(databasePath == null) ? 'in memory' : 'at $databasePath'}");
    _logger.info("Present database version: ${_database.userVersion}");

//     _dbMigrationStmts = {
//       0: _database.prepareMultiple("""
// CREATE TABLE IF NOT EXISTS tbl_path (
//   path_id INTEGER PRIMARY KEY AUTOINCREMENT,
//   path TEXT,
//   path_scanned_on_date TEXT DEFAULT CURRENT_TIMESTAMP
// );
// CREATE TABLE IF NOT EXISTS tbl_file (
//   file_id INTEGER PRIMARY KEY AUTOINCREMENT,
//   file_drive_root TEXT,
//   file_full_path TEXT,
//   file_mime_type TEXT,
//   file_hash TEXT,
//   path_id INTEGER REFERENCES tbl_path ON DELETE CASCADE
// );
// """),
//     };
    // _dbMigrationStmts =
    //     dbMigrationSql.map<int, List<PreparedStatement>>((key, value) {
    //   List<PreparedStatement> list = [];
    //   for (String sql in value) {
    //     list.add(_database.prepare(sql));
    //   }
    //   return MapEntry<int, List<PreparedStatement>>(key, list);
    // });
  }

  /// This migrates the existing DB to the current version and then sets the current version to the version it was updated to.
  ///
  /// Does nothing if `currentVersion` is negative.
  ///
  /// Version `0` is considered to be non-existent.
  /// We delete the tables regardless if that is the case as an incorrect migration in the past may have screwed things up.
  ///
  /// The statements are executed in the order they are specified in.
  ///
  /// This is janky. May fix in the future.
  void migrateDbToLatest() {
    int currentVersion = _database.userVersion;
    // Current version == 0 ==> The database does not exist
    if (currentVersion == 0) {
      // Ensure that this always accounts for ALL tables involved.
      _database.execute("DROP TABLE IF EXISTS tbl_file");
      _database.execute("DROP TABLE IF EXISTS tbl_path");
    }

    int i = currentVersion;
    while (dbMigrationSql.containsKey(i)) {
      // Putting a null check here as this is checked in the parent `if` statement
      for (String sql in dbMigrationSql[i]!) {
        _database.execute(sql);
      }
      i++;
    }
  }

  Future<void> scanForFilesCompute(String path) async {
    _logger.info("Scanning $path for files");

    List<FileSystemEntity> tmpList =
        await compute<String, List<FileSystemEntity>>(
      (message) async {
        String targetPath = message;

        final FileSystemEntityType entityType =
            await FileSystemEntity.type(targetPath);

        if (entityType == FileSystemEntityType.pipe ||
            entityType == FileSystemEntityType.unixDomainSock) {
          throw UnimplementedError("$entityType is not supported!");
        }

        if (entityType == FileSystemEntityType.link) {
          targetPath = await (Link(targetPath)).resolveSymbolicLinks();
        }

        if (entityType == FileSystemEntityType.notFound) {
          throw PathNotFoundException(targetPath, const OSError());
        }

        if (entityType == FileSystemEntityType.file) {
          return [File(message)];
        }

        List<FileSystemEntity> list = [];

        Directory directory = Directory(message);
        Stream<FileSystemEntity> files = directory.list(
          recursive: true,
          followLinks: true,
        );
        await for (final FileSystemEntity entity in files) {
          list.add(entity);
          // print(await entity.stat());
        }

        return list;
      },
      path,
      debugLabel: "File Scan",
    );

    _filesToBeScanned.addAll(tmpList);

    _logger.info(
      "${_filesToBeScanned.length} entities awaiting addition to database",
    );
  }

  Future<void> scanForFiles(String path) async {
    _logger.info("Scanning $path for files");

    switch (await FileSystemEntity.type(path)) {
      case FileSystemEntityType.directory:
        Directory directory = Directory(path);
        Stream<FileSystemEntity> files = directory.list(
          recursive: true,
          followLinks: true,
        );
        await for (final FileSystemEntity entity in files) {
          _filesToBeScanned.add(entity);
          // print(await entity.stat());
        }
        break;
      case FileSystemEntityType.file:
        _filesToBeScanned.add(File(path));
        break;
      case FileSystemEntityType.link:
        await scanForFiles(await Link(path).resolveSymbolicLinks());
        break;
      case FileSystemEntityType.notFound:
        _logger.warning("$path doesnot exist");
        break;
      case FileSystemEntityType.pipe:
        _logger.severe("Pipes not supported yet!");
        throw UnimplementedError("Pipes not supported yet!");
      case FileSystemEntityType.unixDomainSock:
        _logger.severe("UNIX DOmain Socks not supported yet!");
        throw UnimplementedError("UNIX Domain Socks not implemented yet!");
    }
    _logger.info(
      "${_filesToBeScanned.length} entities awaiting addition to database",
    );
  }

  Future<void> addScannedFilesToDatabase() async {}

  @override
  void dispose() {
    _database.dispose();
    super.dispose();
  }
}
