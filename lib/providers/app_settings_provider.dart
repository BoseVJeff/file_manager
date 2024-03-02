import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class AppSettingsProvider extends ChangeNotifier {
  final Logger _logger = Logger("AppSettingsProvider");

  AppSettingsProvider({String? databasePath}) {}
}
