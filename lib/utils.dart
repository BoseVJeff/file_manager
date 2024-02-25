import 'dart:io';

import 'package:path/path.dart';

const Map<Type, String> typeNames = {
  File: 'File',
  Directory: 'Directory',
  Link: 'Link',
};

Future<void> openFile(FileSystemEntity entity) async {}
