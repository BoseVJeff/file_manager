import 'dart:async';

import 'package:file_manager/providers/file_database_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await fileDatabaseProvider.scanForFilesCompute(
      r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\");

  // await fileDatabaseProvider
  //     .scanForFiles(r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\");

  // await compute<String, void>(
  //   (message) async {
  //     await fileDatabaseProvider.scanForFiles(message);
  //     return;
  //   },
  //   r"C:\Users\jeffb\Desktop\dev\flutter\file_manager\lib\",
  // );

  fileDatabaseProvider.dispose();

  print(await launchUrl(Uri.parse(r"C:\Users\jeffb\Downloads\download.csv")));
  return;
}
