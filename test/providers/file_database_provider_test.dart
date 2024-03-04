import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:file_manager/providers/file_database_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

DynamicLibrary _openOnWindows() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final libraryNextToScript = File(
    p.join(scriptDir.path, 'test', 'providers', 'sqlite3', 'sqlite3.dll'),
  );
  return DynamicLibrary.open(libraryNextToScript.path);
}

void main() {
  setUp(() {
    open.overrideFor(
      OperatingSystem.windows,
      () => _openOnWindows(),
    );
  });

  group('Database Migration Queries', () {
    test('Zero-to-Hero Migration', () {
      // Tests if the query is able to create a database from scratch

      Database database = sqlite3.openInMemory();
      database.userVersion = 0;

      try {
        Map<int, List<String>> migrationSql =
            FileDatabaseProvider.dbMigrationSql;
        int i = database.userVersion;
        while (migrationSql.containsKey(i)) {
          // Putting a null check here as this is checked in the parent `if` statement
          for (String sql in migrationSql[i]!) {
            // print("Executing:\n$sql");
            database.execute(sql);
          }
          i++;
        }
        // The key is the version that the database is migrating from
        // So the current version should be the next version
        expect(i, equals(FileDatabaseProvider.dbMigrationSql.keys.last + 1));
      } finally {
        database.dispose();
      }
    });
  });
}
