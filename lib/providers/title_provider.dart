import 'package:flutter/foundation.dart';

class TitleProvider extends ChangeNotifier {
  String _title = "File Manager";

  String get title => _title;

  set title(String newTitle) {
    _title = newTitle;
    notifyListeners();
  }
}
