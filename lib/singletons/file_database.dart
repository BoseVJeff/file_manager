// Singleton
// Init method taken from https://stackoverflow.com/a/12649574
import 'dart:io';

class FileDatabase {
  static final FileDatabase _fileDatabase = FileDatabase._init();

  factory FileDatabase() => FileDatabase._fileDatabase;

  late String fileDatabasePath;

  FileDatabase._init() {
    fileDatabasePath = Platform.executable;
  }
}
