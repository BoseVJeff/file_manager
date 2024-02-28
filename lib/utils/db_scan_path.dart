import 'package:sqlite3/sqlite3.dart';

class DbScanPath {
  final int id;
  final String path;
  final DateTime timeLastScannedAt;

  const DbScanPath(
    this.id,
    this.path,
    this.timeLastScannedAt,
  );

  /// Assumes that this is the output of `SELECT * FROM tbl_path` or similar
  factory DbScanPath.fromRow(Row row) => DbScanPath(
        row.columnAt(0) as int,
        row.columnAt(1),
        DateTime.parse(row.columnAt(2)),
      );

  static Iterable<DbScanPath> fromRows(ResultSet resultSet) => resultSet.map(
        (Row row) => DbScanPath.fromRow(row),
      );
}
