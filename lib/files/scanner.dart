import 'dart:io';

class Scanner {
  final String _initPath;

  Scanner(this._initPath);

  Future<List<FileSystemEntity>> scan() async {
    String path = _initPath;
    if (await FileSystemEntity.isLink(path)) {
      Link link = Link(path);
      path = await link.resolveSymbolicLinks();
    }

    if (await FileSystemEntity.isFile(path)) {
      return [File(path)];
    } else {
      // Assuming it is a directory
      assert(FileSystemEntity.isDirectorySync(path));

      Directory directory = Directory(path);

      List<FileSystemEntity> list =
          await directory.list(recursive: true, followLinks: false).toList();

      return list;
    }
  }
}

class UnknownFileTypeException implements Exception {
  final String filePath;

  const UnknownFileTypeException(this.filePath);

  String get message => "FileSystemEntity is neither Directory, File, or Link";
}
