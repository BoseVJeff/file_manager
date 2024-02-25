import 'dart:io';

import 'package:file_manager/database/db.dart';
import 'package:flutter/foundation.dart';

class FileEntityProvider extends ChangeNotifier {
  List<FileSystemEntity> fileEntities = [];

  String _parentPath = "";

  final DB _db;

  FileEntityProvider(String path, DB db)
      : _db = db,
        _parentPath = path {
    debugPrint("Using DB at ${_db.dbPath}");
  }

  Future<void> scanDirectory(bool followLinks) async {
    switch (await FileSystemEntity.type(_parentPath)) {
      case FileSystemEntityType.notFound:
        throw FileNotFoundException(_parentPath);

      case FileSystemEntityType.directory:
        Directory directory = Directory(_parentPath);

        await for (final FileSystemEntity entity in directory.list(
          recursive: false,
          followLinks: false,
        )) {
          fileEntities.add(entity);
          _db.addFileSystemEntity(entity);
          notifyListeners();
        }
        break;

      case FileSystemEntityType.file:
        fileEntities = [File(_parentPath)];
        notifyListeners();
        break;

      case FileSystemEntityType.link:
        if (followLinks) {
          _parentPath = await Link(_parentPath).resolveSymbolicLinks();
          scanDirectory(followLinks);
        }
        notifyListeners();
        break;
      case FileSystemEntityType.pipe:
        debugPrint("Pipe type!");
        throw UnimplementedFileTypeException(_parentPath);
      case FileSystemEntityType.unixDomainSock:
        debugPrint("Unix Domain Sock type!");
        throw UnimplementedFileTypeException(_parentPath);
    }
  }
}

class FileNotFoundException implements Exception {
  final String filePath;

  const FileNotFoundException(this.filePath);
}

class UnimplementedFileTypeException implements Exception {
  final String filePath;

  const UnimplementedFileTypeException(this.filePath);
}
