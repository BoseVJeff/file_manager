import 'dart:io';

import 'package:file_manager/utils/database_file.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
