class FileDatabase {
  static final FileDatabase _fileDatabase = FileDatabase._internal();

  factory FileDatabase() => FileDatabase._fileDatabase;

  FileDatabase._internal() {}
}
