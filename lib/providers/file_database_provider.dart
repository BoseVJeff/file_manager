import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:file_manager/utils/database_file.dart';
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

  late StreamSubscription<SqliteUpdate> updateSubs;

  /// List of files that are awating to be scanned into the database
  ///
  /// This is treated akin to a stack where items are popped off as they are scanned into the database.
  /// Scanning stops when this list is empty.
  ///
  /// This is a seperate list as the file scanning happens in a seperate isolate where the database object is unavailable.
  /// For more info on the scanning object see [FileDatabaseProvider.scanForFilesCompute].
  final List<(FileSystemEntity entity, int pathId)> _filesToBeScanned = [];

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
    // Initial table
    0: [
      """
CREATE TABLE IF NOT EXISTS tbl_path (
  path_id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT,
  path_scanned_on_date TEXT DEFAULT CURRENT_TIMESTAMP
);
""",
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
    // `path_scanned_on_date` should really be `path_added_on_date` as ot records the timestamp when the path was added.
    // Adding back a `path_scanned_on_date` with better constraints as that is also needed.
    1: [
      """
ALTER TABLE tbl_path RENAME COLUMN path_scanned_on_date TO path_added_on_date;
""",
      """
ALTER TABLE tbl_path ADD COLUMN path_scanned_on_date TEXT;
""",
    ],
    // Database hashes are now strictly in uppercase
    // Older versions of the code relied on the default dart behaviour, which would emit lowercase.
    // The newer versions force uppercase, so the existing values must be updated so that hash equality continues to function as expected
    2: [
      """
UPDATE tbl_file SET file_hash=upper(file_hash);
"""
    ]
  };

  // late PreparedStatement _databaseInsertFileStatement;

  // late PreparedStatement _databaseFileSearchStatement;

  // late PreparedStatement _databaseFileDumpStatement;

  late PreparedStatement _databaseInsertScanPathStatement;

  late PreparedStatement _databaseRemoveScanPathStatement;

  // // TODO: Count the rows for each path_id in tbl_files
  // late PreparedStatement _databaseCountFilesFromPath;

  // late PreparedStatement _databasePathDumpStatement;

  // late PreparedStatement _databaseRemovePath;

  // late PreparedStatement _databaseUpdatePath;

  // late PreparedStatement _databaseDeletePathChildrenStatement;

  late PreparedStatement _databaseLastPathIdStatement;

  FileDatabaseProvider([Database? database])
      : _database = database ?? sqlite3.openInMemory() {
    _logger.info(
        "Initialising database ${(database == null) ? 'in memory' : 'provided'}");

    _logger
        .config("Migrating Database from ${_database.userVersion} to latest");
    migrateDbToLatest();

    _logger.info("Present database version: ${_database.userVersion}");

    _logger.fine("Preparing path insertion statement");
    _databaseInsertScanPathStatement =
        _database.prepare("INSERT INTO tbl_path (path) VALUES (?)");

    _logger.fine("Preparing path removal statement");
    _databaseRemoveScanPathStatement =
        _database.prepare("DELETE FROM tbl_path WHERE path_id=?");

    _logger.fine("Preparing last path id statement");
    _databaseLastPathIdStatement = _database
        .prepare("SELECT path_id FROM tbl_path ORDER BY path_id DESC LIMIT 1;");

    updateSubs = _database.updates.listen(sqliteUpdateLogger);
  }

  void sqliteUpdateLogger(SqliteUpdate update) {
    switch (update.kind) {
      case SqliteUpdateKind.insert:
        _logger.fine("Inserted row ${update.rowId} in ${update.tableName}");
        break;
      case SqliteUpdateKind.update:
        _logger.fine("Updated row ${update.rowId} in ${update.tableName}");
        break;
      case SqliteUpdateKind.delete:
        _logger.fine("Deleted row ${update.rowId} in ${update.tableName}");
        break;
    }
    return;
  }

  // This method is mainly used for debugging and testing purposes
  int get databaseVersion => _database.userVersion;

  /// This migrates the existing DB to the current version and then sets the current version to the version it was updated to.
  ///
  /// If [Database.userVersion] of the database is negative, it sets it to zero and proceeds assuming it is zero.
  ///
  /// Version `0` is considered to be non-existent.
  /// We delete the tables regardless if that is the case as an incorrect migration in the past may have screwed things up.
  ///
  /// The statements are executed in the order they are specified in.
  ///
  /// This is janky. May fix in the future.
  void migrateDbToLatest() {
    if (_database.userVersion < 0) {
      _database.userVersion = 0;
    }
    assert(_database.userVersion >= 0);
    int currentVersion = _database.userVersion;
    // Current version == 0 ==> The database does not exist
    if (currentVersion == 0) {
      // The database may have been created by another application or a much older version of the application.
      // Deleting the tables involved ensures that we always start from scratch as this is unknown territory.
      // NOTE: Ensure that this always accounts for ALL tables involved.
      _database.execute("DROP TABLE IF EXISTS tbl_file");
      _database.execute("DROP TABLE IF EXISTS tbl_path");
    }

    int i = currentVersion;
    // If the database is already at latest, this loop gets skipped over and nothing gets done
    while (dbMigrationSql.containsKey(i)) {
      // Putting a null check here as this is checked in the parent `if` statement
      for (String sql in dbMigrationSql[i]!) {
        _database.execute(sql);
      }
      i++;
    }
    _database.userVersion = i;
  }

  /// Add the path to the `tbl_path` table.
  ///
  /// Returns the index where this file was inserted.
  int addSourcePath(String path) {
    _logger.info("Adding path to tbl_path");
    _databaseInsertScanPathStatement.execute([path]);

    _logger.info("Returning the last row");
    return _databaseLastPathIdStatement.select([]).first['path_id'];
  }

  void removeSourcePath(int id) {
    _logger.info("Removing path with id $id");
    _databaseRemoveScanPathStatement.execute([id]);

    return;
  }

  /// Scans the given `path` and its subdirectories for files that can be added to the database.
  /// These files are added to the an internal list of files that are pending to be scanned.
  ///
  /// Internally, this data is stored as a list of ([FileSystemEntity] entity, [int] pathId) tuples.
  ///
  /// Note that the file data is not computed untill just before the files are added to the database.
  ///
  /// This method spawns a seperate isolate for scanning, keeping the load off the main isolate.
  ///
  /// The path is also added into the database as a source path.
  /// Specifically, the path is added to the `tbl_path` table in the database.
  ///
  /// This method does not check for duplicates, so it is the responsiblity of the caller to ensure that the same path does not get added twice.
  Future<void> scanForFilesCompute(String path, int pathId) async {
    // int pathId = addSourcePath(path);

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

    _filesToBeScanned.addAll(tmpList.map((e) => (e, pathId)));

    _logger.info(
      "${_filesToBeScanned.length} entities awaiting addition to database",
    );
  }

  Future<void> scanForFiles(String path, int pathId) async {
    // _logger.fine("Adding $path to database");
    // int pathId = addSourcePath(path);

    _logger.info("Scanning $path for files");

    switch (await FileSystemEntity.type(path)) {
      case FileSystemEntityType.directory:
        Directory directory = Directory(path);
        Stream<FileSystemEntity> files = directory.list(
          recursive: true,
          followLinks: true,
        );
        await for (final FileSystemEntity entity in files) {
          _filesToBeScanned.add((entity, pathId));
          // print(await entity.stat());
        }
        break;
      case FileSystemEntityType.file:
        _filesToBeScanned.add((File(path), pathId));
        break;
      case FileSystemEntityType.link:
        await scanForFiles(await Link(path).resolveSymbolicLinks(), pathId);
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

  Future<void> addScannedFilesToDatabase() async {
    // Handle to the database that will be passed into the isolate
    final Pointer<void> databasePointer = _database.handle;

    // Preparing file insert statement
    // This is prepared here as there is an advantage to having this statement be pre-computed here for large number of files.
    // Note that this statement MUST be disposed after it is done being used.
    // PreparedStatement statement = _database.prepare(
    //     "INSERT INTO tbl_file (file_drive_root, file_full_path, file_mime_type, file_hash) VALUES (?, ?, ?, ?);");

    for (final (FileSystemEntity entity, int pathId) in _filesToBeScanned) {
      await compute<(Pointer<void> pointer, String filePath, int pathid), void>(
        (message) async {
          Pointer<void> dbPointer;
          String filePath;
          int pathid;
          (dbPointer, filePath, pathid) = message;

          Database isolateDatabase = sqlite3.fromPointer(dbPointer);
          DatabaseFile databaseFile = await DatabaseFile.fromPath(filePath);

          isolateDatabase.execute(
            "INSERT INTO tbl_file (file_drive_root, file_full_path, file_mime_type, file_hash, path_id) VALUES (?, ?, ?, ?, ?);",
            [
              databaseFile.driveRoot,
              databaseFile.path,
              databaseFile.mimeType,
              databaseFile.hash,
              pathid,
            ],
          );

          return;
        },
        (databasePointer, entity.absolute.path, pathId),
        debugLabel: 'File into Database',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await updateSubs.cancel();
    _database.dispose();
    super.dispose();
  }
}
