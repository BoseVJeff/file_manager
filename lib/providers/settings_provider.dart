import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  /// List of paths to scan
  List<String> paths = [
    r'C:\Users\jeffb\Desktop\dev\flutter\file_manager\',
  ];

  void addPath(String newPath) => paths.add(newPath);
}
