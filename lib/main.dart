import 'dart:io';

import 'package:file_manager/providers/settings_provider.dart';
import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/singletons/app_router.dart';
import 'package:file_manager/singletons/file_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

void main() async {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.WARNING;
  }

  // Record logs
  Logger.root.onRecord.listen((LogRecord record) {
    debugPrint(
        "[${record.loggerName}] [${record.level.name}] [${record.time}] ${record.message}");
    if (record.error != null) {
      debugPrint("Error: ${record.error}\nStacktrace:\n${record.stackTrace}");
    }
  });

  // Setting upp app and logging
  Logger logger = Logger("main");
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    logger.severe("Unhandled error in root isolate!", exception, stackTrace);
    return false;
  };

  // FileDatabase fileDatabase = FileDatabase();
  // await fileDatabase.addDirectoryContentsToFile(
  //     Directory(r'C:\Users\jeffb\Desktop\dev\flutter\file_manager\'));
  // fileDatabase.dispose();

  runApp(
    MultiProvider(
      builder: (context, child) {
        return const FileManagerApp();
      },
      providers: [
        ChangeNotifierProvider(create: (_) => TitleProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
    ),
  );
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      routerConfig: AppRouter.goRouter,
    );
  }
}
