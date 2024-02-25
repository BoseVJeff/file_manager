class FileDatabase {
  static final FileDatabase _fileDatabase = FileDatabase._init();

  factory FileDatabase() => FileDatabase._fileDatabase;

  FileDatabase._init() {}
}
