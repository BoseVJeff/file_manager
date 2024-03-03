import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:file_manager/providers/file_database_provider.dart';
import 'package:path/path.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

DynamicLibrary _openOnWindows() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final libraryNextToScript = File(
    join(scriptDir.path, 'test', 'providers', 'sqlite3', 'sqlite3.dll'),
  );
  print("Loading dll from ${libraryNextToScript.path}");
  return DynamicLibrary.open(libraryNextToScript.path);
}

void main() {
  group('Database Migration Queries', () {
    test('Zero-to-Hero Migration', () {
      // Tests if the query is able to create a database from scratch
      print(Platform.executable);
      open.overrideFor(
        OperatingSystem.windows,
        () => _openOnWindows(),
      );

      Database database = sqlite3.openInMemory();
      database.userVersion = 0;

      try {
        Map<int, List<String>> migrationSql =
            FileDatabaseProvider.dbMigrationSql;
        int i = database.userVersion;
        while (migrationSql.containsKey(i)) {
          // Putting a null check here as this is checked in the parent `if` statement
          for (String sql in migrationSql[i]!) {
            print("Executing:\n$sql");
            database.execute(sql);
          }
          i++;
        }
      } finally {
        database.dispose();
      }
    });
  });
}
