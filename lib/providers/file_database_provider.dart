import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart';

class FileDatabaseProvider extends ChangeNotifier {
  final Database _database;

  final Logger _logger = Logger("FileDatabaseProvider");

  final List<FileSystemEntity> _filesToBeScanned = [];

  FileDatabaseProvider([String? databasePath])
      : _database = (databasePath != null)
            ? sqlite3.open(databasePath)
            : sqlite3.openInMemory() {
    _logger.info(
        "Initialising database ${(databasePath == null) ? 'in memory' : 'at $databasePath'}");
    _logger.info("Present database version: ${_database.userVersion}");
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

  @override
  void dispose() {
    _database.dispose();
    super.dispose();
  }
}
