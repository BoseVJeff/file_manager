// Singleton
// Init method taken from https://stackoverflow.com/a/12649574
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_manager/utils/db_file.dart';
import 'package:file_manager/utils/db_scan_path.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

import 'package:sqlite3/sqlite3.dart';

import 'package:mime/mime.dart';

// TODO: Get rid of async wherever possible

class FileDatabase {
  // Singleton shenanigans
  static final FileDatabase _fileDatabase = FileDatabase._init();

  factory FileDatabase() => FileDatabase._fileDatabase;

  // Our stuff
  late String fileDatabasePath;

  final Logger _logger = Logger("FileDatabase");

  late Database _database;

  late PreparedStatement _databaseCreateFilesTableStatement;

  late PreparedStatement _databaseCreatePathsTableStatement;

  late PreparedStatement _databaseInsertFileStatement;

  late PreparedStatement _databaseFileSearchStatement;

  late PreparedStatement _databaseFileDumpStatement;

  late PreparedStatement _databaseInsertScanPathStatement;

  // TODO: Count the rows for each path_id in tbl_files
  late PreparedStatement _databaseCountFilesFromPath;

  late PreparedStatement _databasePathDumpStatement;

  late PreparedStatement _databaseRemovePath;

  late PreparedStatement _databaseUpdatePath;

  late PreparedStatement _databaseDeletePathChildrenStatement;

  FileDatabase._init() {
    _logger.fine("Intitialising database");
    fileDatabasePath = join(dirname(Platform.executable), 'file_database.db');

    _logger.info("Creating database at $fileDatabasePath");
    _database = sqlite3.open(fileDatabasePath);

// Not that the date is stored as `2024-02-28 14:24:08` i.e. in this format with GMT TZ
    _logger.fine("Preparing database table");
    _databaseCreateFilesTableStatement = _database.prepare("""
CREATE TABLE IF NOT EXISTS tbl_files (
  file_id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_drive_root TEXT,
  file_full_path TEXT,
  file_mime_type TEXT,
  file_hash TEXT,
  path_id INTEGER REFERENCES tbl_path ON DELETE CASCADE
);
""");

    _databaseCreatePathsTableStatement = _database.prepare("""
CREATE TABLE IF NOT EXISTS tbl_path (
  path_id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT,
  path_scanned_on_date TEXT DEFAULT CURRENT_TIMESTAMP
);
""");

    _logger.info("Creating database tables");
    _databaseCreateFilesTableStatement.execute();
    _databaseCreatePathsTableStatement.execute();

    _logger.fine("Preparing file insertion statement");
    _databaseInsertFileStatement = _database.prepare("""
INSERT INTO tbl_files (file_drive_root, file_full_path, file_mime_type, file_hash, path_id)
VALUES (?, ?, ?, ?, (SELECT path_id FROM tbl_path WHERE path=? LIMIT 1));
""");

    _logger.fine("Preparing file search statement");
    _databaseFileSearchStatement = _database.prepare("""
SELECT * FROM tbl_files WHERE file_full_path LIKE ?;
""");

    _logger.fine("Preparing file dump statement");
    _databaseFileDumpStatement = _database.prepare("""
SELECT * FROM tbl_files;
""");

    _logger.fine("Preparing scan path insertion statement");
    _databaseInsertScanPathStatement = _database.prepare("""
INSERT INTO tbl_path (path) VALUES (?);
""");

    _logger.fine("Preparing path child count statement");
    _databaseCountFilesFromPath = _database.prepare("""
SELECT count(file_id) FROM tbl_files WHERE path_id=?;
""");

    _logger.fine("Preparing path dump statement");
    _databasePathDumpStatement = _database.prepare("""
SELECT * FROM tbl_path;
""");

    _logger.fine("Preparing path removal statement");
    _databaseRemovePath = _database.prepare("""
DELETE FROM tbl_path WHERE path_id=?;
""");

    _logger.fine("Preparing path updation statement");
    _databaseUpdatePath = _database.prepare("""
UPDATE tbl_path SET path=? WHERE path_id=?;
""");

    _logger.fine("Preparing path children removal statement");
    _databaseDeletePathChildrenStatement = _database.prepare("""
DELETE FROM tbl_files WHERE path_id=?;
""");
  }

  Future<void> insertPath(String path) async {
    _databaseInsertScanPathStatement.execute([path]);
    await scanFilesToDatabase(path);
  }

  Iterable<DbScanPath> getAllPaths() => DbScanPath.fromRows(
        _databasePathDumpStatement.select(),
      );

  Future<void> updatePath(int pathId, String newPath) async {
    _databaseDeletePathChildrenStatement.execute([pathId]);
    _databaseUpdatePath.execute([newPath, pathId]);
    await scanFilesToDatabase(newPath);
  }

  void removePath(int pathId) {
    _databaseDeletePathChildrenStatement.execute([pathId]);
    _databaseRemovePath.execute([pathId]);
  }

  int countPathChildren(int pathId) =>
      _databaseCountFilesFromPath.select([pathId]).first.columnAt(0) as int;

  void insertFile(
    String fileDriveRoot,
    String fileFullPath,
    String? fileMimeType,
    String fileHash,
    String? scanPath,
  ) {
    _logger.info("Inserting file $fileFullPath from drive $fileDriveRoot");
    _databaseInsertFileStatement.execute([
      fileDriveRoot,
      fileFullPath,
      fileMimeType,
      fileHash,
      scanPath,
    ]);
  }

  /// Searches for the string and returns files whose paths include the string
  ///
  /// This is done this way so that all files in a folder can also be selected
  Iterable<DbFile> getFileByName(String? str) {
    if (str != null) {
      _logger.info("Searching for substring $str");
      ResultSet resultSet = _databaseFileSearchStatement.select(["%$str%"]);
      return DbFile.fromRows(resultSet);
    }
    _logger.info("Term is empty. Dumping all");
    return DbFile.fromRows(_databaseFileDumpStatement.select());
  }

  void addFileToDatabase(File file, String? scanPath) {
    final String? mimeType = lookupMimeType(file.path);
    final String driveRoot = rootPrefix(file.path);
    final String filePath = relative(file.path, from: driveRoot);

    Uint8List fileBytes = file.readAsBytesSync();

    final Digest digest = sha1.convert(fileBytes);

    _logger.finest(
      "Adding to DB:\n$driveRoot | $filePath | $mimeType | $digest",
    );
    insertFile(driveRoot, filePath, mimeType, digest.toString(), scanPath);
  }

  Future<void> addDirectoryContentsToFile(Directory directory) async {
    Stream<FileSystemEntity> entityStream = directory.list(
      recursive: true,
      followLinks: true,
    );

    await entityStream.forEach((FileSystemEntity entity) async {
      FileSystemEntity e = entity;
      if (e is Link) {
        String s = await e.resolveSymbolicLinks();
        if (await FileSystemEntity.isFile(s)) {
          e = File(s);
        }
      }
      if (e is File) {
        addFileToDatabase(e, directory.path);
      }
    });

    return;
  }

  Future<void> scanFilesToDatabase(String path) async {
    switch (await FileSystemEntity.type(path)) {
      case FileSystemEntityType.directory:
        await addDirectoryContentsToFile(Directory(path));
        break;
      case FileSystemEntityType.file:
        addFileToDatabase(File(path), path);
        break;
      case FileSystemEntityType.link:
        final Link link = Link(path);
        final String resolvedPath = await link.resolveSymbolicLinks();
        await scanFilesToDatabase(resolvedPath);
        break;
      case FileSystemEntityType.notFound:
        throw PathNotFoundException(path, const OSError());
      case FileSystemEntityType.pipe:
        throw UnimplementedError("Pipes are currently unsupported!");
      case FileSystemEntityType.unixDomainSock:
        throw UnimplementedError(
            "UNIX Domain Socks are currently unsupported!");
    }
  }

  // void scanFilesToDatabaseSync(String path) {
  //   _logger.fine("Scanning $path");
  //   switch (FileSystemEntity.typeSync(path)) {
  //     case FileSystemEntityType.directory:
  //       _logger.fine("$path is Directory");
  //       final Directory directory = Directory(path);

  //       final List<FileSystemEntity> list = directory.listSync(
  //         recursive: true,
  //         followLinks: true,
  //       );

  //       for (FileSystemEntity entity in list) {
  //         if (entity is Directory) {
  //           _logger.fine("${entity.path} is directory. Ignoring");
  //           return;
  //         } else if (entity is File) {
  //           _logger.fine("${entity.path} is File");
  //           addFileToDatabase(entity);
  //         } else {
  //           _logger.warning("Ignoring ${entity.path}");
  //         }
  //       }

  //       break;
  //     case FileSystemEntityType.file:
  //       _logger.fine("$path is File");
  //       final File file = File(path).absolute;
  //       addFileToDatabase(file);

  //       break;
  //     case FileSystemEntityType.link:
  //       _logger.fine("$path is Link. It will be resolved");
  //       scanFilesToDatabaseSync(Link(path).resolveSymbolicLinksSync());
  //       break;
  //     case FileSystemEntityType.notFound:
  //       _logger.warning("$path does not exist!");
  //       throw PathNotFoundException(path, const OSError());
  //     case FileSystemEntityType.pipe:
  //       _logger.fine("$path is Pipe");
  //       _logger.severe("Pipe handling is not implemented!");
  //       throw UnimplementedError();
  //     case FileSystemEntityType.unixDomainSock:
  //       _logger.fine("$path is UNIX Domain Sock");
  //       _logger.severe("UNIX Doman Sock handling is not implemented!");
  //       throw UnimplementedError();
  //   }
  // }

  dispose() {
    _logger.info("Disposing database");
    _database.dispose();
  }
}
