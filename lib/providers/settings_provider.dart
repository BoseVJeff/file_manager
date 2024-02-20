import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  String? _dbRelativePath;

  String? get dbRelativePath => _dbRelativePath;

  set dbRelativePath(String? newValue) {
    _dbRelativePath = newValue;
    notifyListeners();
  }
}
