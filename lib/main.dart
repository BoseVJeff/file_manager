import 'dart:io';

import 'package:file_manager/database/db.dart';
import 'package:file_manager/files/scanner.dart';
import 'package:file_manager/providers/settings_provider.dart';
import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/router/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // debugPrint(
  //   // "Using SQLite version ${sqlite3.version} from ${Uri.parse(Platform.resolvedExecutable).pathSegments.join(' | ')}",
  //   "Using SQLite version ${sqlite3.version} from ${Uri.parse(Platform.resolvedExecutable).scheme}",
  // );
  DB db = DB();
  debugPrint("Creating database at ${db.dbPath}");

  Scanner scanner = Scanner(
      "C:/Users/jeffb/Desktop/dev/flutter/file_manager/build/windows/x64/runner/Debug");

  List<FileSystemEntity> list = await scanner.scan();

  Iterable<String> names =
      list.where((element) => element is! Directory).map((e) => e.path);

  debugPrint(names.join("\n"));

  try {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TitleProvider>(create: (_) => TitleProvider()),
          ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } finally {
    db.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TitleProvider>(builder: (
      BuildContext context,
      TitleProvider titleProvider,
      Widget? child,
    ) {
      return MaterialApp.router(
        title: titleProvider.title,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        routerConfig: goRouter,
      );
    });
  }
}
