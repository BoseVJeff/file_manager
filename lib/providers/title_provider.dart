import 'package:flutter/foundation.dart';

class TitleProvider extends ChangeNotifier {
  String title = "File Manager";

  void updateTitle(String newTitle) {
    title = newTitle;
    notifyListeners();
  }
}
