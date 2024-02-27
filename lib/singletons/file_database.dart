// Singleton
// Init method taken from https://stackoverflow.com/a/12649574
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_manager/utils/db_file.dart';
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

  late PreparedStatement _databaseCreateStatement;

  late PreparedStatement _databaseInsertFileStatement;

  late PreparedStatement _databaseFileSearchStatement;

  late PreparedStatement _databaseFileDumpStatement;

  FileDatabase._init() {
    _logger.fine("Intitialising database");
    fileDatabasePath = join(dirname(Platform.executable), 'file_database.db');

    _logger.info("Creating database at $fileDatabasePath");
    _database = sqlite3.open(fileDatabasePath);

    _logger.fine("Preparing database table");
    _databaseCreateStatement = _database.prepare("""
CREATE TABLE IF NOT EXISTS tbl_files (
  file_id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_drive_root TEXT,
  file_full_path TEXT,
  file_mime_type TEXT,
  file_hash TEXT
);
""");

    _logger.info("Creating database tables");
    _databaseCreateStatement.execute();

    _logger.fine("Preparing file insertion statement");
    _databaseInsertFileStatement = _database.prepare("""
INSERT INTO tbl_files (file_drive_root, file_full_path, file_mime_type, file_hash)
VALUES (?, ?, ?, ?);
""");

    _logger.fine("Preparing file search statement");
    _databaseFileSearchStatement = _database.prepare("""
SELECT * FROM tbl_files WHERE file_full_path LIKE ?;
""");

    _logger.fine("Preparing file dump statement");
    _databaseFileDumpStatement = _database.prepare("""
SELECT * FROM tbl_files;
""");
  }

  void insertFile(
    String fileDriveRoot,
    String fileFullPath,
    String? fileMimeType,
    String fileHash,
  ) {
    _logger.info("Inserting file $fileFullPath from drive $fileDriveRoot");
    _databaseInsertFileStatement.execute([
      fileDriveRoot,
      fileFullPath,
      fileMimeType,
      fileHash,
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

  void addFileToDatabase(File file) {
    final String? mimeType = lookupMimeType(file.path);
    final String driveRoot = rootPrefix(file.path);
    final String filePath = relative(file.path, from: driveRoot);

    Uint8List fileBytes = file.readAsBytesSync();

    final Digest digest = sha1.convert(fileBytes);

    _logger.finest(
      "Adding to DB:\n$driveRoot | $filePath | $mimeType | $digest",
    );
    insertFile(driveRoot, filePath, mimeType, digest.toString());
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
        addFileToDatabase(e);
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
        addFileToDatabase(File(path));
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
