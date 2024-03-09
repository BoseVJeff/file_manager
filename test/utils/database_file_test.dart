import 'dart:io';

import 'package:file_manager/utils/database_file.dart';
import 'package:flutter_test/flutter_test.dart';

/// The file to be tested on
const String testFilePath = r"test\utils\database_file_test.dart";

void main() {
  group('Static Methods', () {
    test(
      "Drive Root",
      () {
        // Files in the same drive as the executable (incl. exec. itself) return null
        expect(DatabaseFile.getFileDriveRoot(Platform.executable), isNull);

        // Files in other drives return the value itself.
        // Note that this test assumes that the test is not run on the `Z:\` drive.
        expect(
          DatabaseFile.getFileDriveRoot(
            r"Z:\flutter_project\file_manager\test\utils\database_file_test.dart",
          ),
          equals(r"Z:\"),
        );
      },
    );

    test('Drive Mime Type', () async {
      // print(await DatabaseFile.getFileMimeType(
      //     r"test\utils\database_file_test.dart"));
      // Standard File
      expect(
        await DatabaseFile.getFileMimeType(
            r"test\utils\database_file_test.dart"),
        equals("text/x-dart"),
      );
      // Non-existent File
      expect(
        await DatabaseFile.getFileMimeType(
            r"test\utils\database_file_test.dar"),
        isNull,
      );
      // Directory, should return null as mime types are defined only for files
      expect(
        await DatabaseFile.getFileMimeType(r"test\"),
        isNull,
      );
    });

    test('File Hash', () async {
      // print((await Process.run("pwsh.exe", [
      //   "-Command",
      //   r"(Get-FileHash .\test\utils\database_file_test.dart -Algorithm SHA1).Hash",
      // ]))
      //     .stdout);
      const String filePath = testFilePath;
      // Source of truth, assuming that the devs a Microsoft don't mess up
      final String pwshHash = ((await Process.run("pwsh.exe", [
        "-Command",
        "(Get-FileHash $filePath -Algorithm SHA1).Hash",
      ]))
              .stdout as String)
          // The output needs to be trimmed as it returns a `/r/n` at the end
          .trim();
      final String dartHash = await DatabaseFile.getFileHash(filePath);
      expect(dartHash, equals(pwshHash));
    });
  });
}
