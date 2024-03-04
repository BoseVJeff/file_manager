import 'dart:io';

import 'package:path/path.dart';

class DatabaseFile {
  /// The full path to the file
  ///
  /// Is relative to drive root to ensure that the paths remain valid even when the drive letter changes
  final String path;

  /// The drive root folder for the file.
  ///
  /// This will be null if the file is on the same drive as the executable.
  ///
  /// This is to ensure that in cases where this drive is on a thumb drive, it does not consdier files to be distinct if the drive letter changes.
  ///
  /// Drive letters for all files except the executable drive are recorded.
  final String? driveRoot;
  final String mimeType;
  final String hash;

  const DatabaseFile(
    this.path,
    this.driveRoot,
    this.mimeType,
    this.hash,
  );

  static String? getFileDriveRoot(String fullPath) {
    String fileRoot = rootPrefix(fullPath);
    String execRoot = rootPrefix(Platform.executable);
    if (fileRoot == execRoot) {
      return null;
    } else {
      return fileRoot;
    }
  }
}
