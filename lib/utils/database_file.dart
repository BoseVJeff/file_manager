import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
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

  /// The mime-type of the file
  ///
  /// This is determined by using the filename and the first 256 bytes of the file contents.
  ///
  /// This is null if the mime-type could not be determined.
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

  /// Attempts to get the mime-type of the file.
  ///
  /// Uses the filename and the first [defaultMagicNumbersMaxLength] bytes to make the determination.
  static Future<String?> getFileMimeType(String fullPath) async {
    File file = File(fullPath);

    Stream<List<int>> byteStream =
        file.openRead(0, defaultMagicNumbersMaxLength);

    List<int> bytes = (await byteStream.toList()).first;

    return lookupMimeType(fullPath, headerBytes: bytes);
  }

  /// Gets the SHA1 hash of the file.
  ///
  /// SHA1 was chosen because it is reasonably fast and has reasonable resistance to hash collisions.
  ///
  /// Security concerns are ignored here as this is not a security-sensitive context.
  static Future<String> getFileHash(String fullPath) async {
    File file = File(fullPath);

    AccumulatorSink<Digest> output = AccumulatorSink<Digest>();
    ByteConversionSink input = sha1.startChunkedConversion(output);

    Stream<List<int>> byteStream = file.openRead();

    await for (final List<int> chunk in byteStream) {
      input.add(chunk);
    }

    input.close();

    Digest digest = output.events.single;

    return digest.toString();
  }
}
