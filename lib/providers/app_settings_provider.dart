import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppSettingsProvider extends ChangeNotifier {
  final Logger _logger = Logger("AppSettingsProvider");

  String? _databasePath;

  String? get databasePath => _databasePath;

  AppSettingsProvider({String? databasePath}) {
    _databasePath = databasePath;
  }

  set databasePath(String? value) {
    _logger.finest("CHanging database path from $_databasePath to $value");
    _databasePath = value;
    notifyListeners();
  }
}
