// Singleton
// Init method taken from https://stackoverflow.com/a/12649574
import 'dart:io';

import 'package:logging/logging.dart';

class FileDatabase {
  // Singleton shenanigans
  static final FileDatabase _fileDatabase = FileDatabase._init();

  factory FileDatabase() => FileDatabase._fileDatabase;

  // Our stuff
  late String fileDatabasePath;

  final Logger _logger = Logger("FileDatabase");

  FileDatabase._init() {
    fileDatabasePath = Platform.executable;
  }
}
