import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class TitleProvider extends ChangeNotifier {
  String _title = "";

  final Logger _logger = Logger("TitleProvider");

  TitleProvider() {
    title = "File Manager";
  }

  String get title => _title;

  set title(String newTitle) {
    _title = newTitle;
    _logger.config("Changed title to '$newTitle'");
    notifyListeners();
  }
}
