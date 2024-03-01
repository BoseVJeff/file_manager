import 'dart:async';

import 'package:file_manager/providers/file_database_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

Future<void> main(List<String> args) async {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.INFO;
  }
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      print(
        "${record.time.toIso8601String()} - ${record.loggerName} - ${record.level.name} - ${record.message}",
      );
    }
    // TODO: Deal with logs in production mode.
  });
  FileDatabaseProvider fileDatabaseProvider = FileDatabaseProvider();
  await fileDatabaseProvider
      .scanForFiles(r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\");

  // await compute<String, void>(
  //   (message) async {
  //     await fileDatabaseProvider.scanForFiles(message);
  //     return;
  //   },
  //   r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\",
  // );

  fileDatabaseProvider.dispose();
  return;
}
