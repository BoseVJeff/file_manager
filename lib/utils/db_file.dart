import 'package:sqlite3/common.dart';

class DbFile {
  final int id;
  final String fileDriveRoot;
  final String filePath;
  final String? mimeType;
  final String fileHash;

  const DbFile(
    this.id,
    this.fileDriveRoot,
    this.filePath,
    this.mimeType,
    this.fileHash,
  );

  /// Assumes that the row is a result of `SELECT * FROM tbl_file ...`
  factory DbFile.fromRow(Row row) => DbFile(
        row.columnAt(0),
        row.columnAt(1),
        row.columnAt(2),
        row.columnAt(3),
        row.columnAt(4),
      );

  static Iterable<DbFile> fromRows(ResultSet resultSet) => resultSet.map(
        (Row row) => DbFile.fromRow(row),
      );
}
