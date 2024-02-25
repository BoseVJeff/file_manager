import 'package:file_manager/singletons/file_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Check that the database class is a singleton', () {
    // This test only exists to enforce that the class is a singleton
    FileDatabase fileDatabase1 = FileDatabase();
    FileDatabase fileDatabase2 = FileDatabase();
    expect(fileDatabase1 == fileDatabase2, isTrue);
  });
}
