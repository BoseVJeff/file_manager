import 'package:file_manager/database/db.dart';
import 'package:flutter/foundation.dart';

class DatabaseProvider extends ChangeNotifier {
  late DB db;

  DatabaseProvider([String? path]) : db = DB(path) {
    db.init();
  }

  @override
  void dispose() {
    db.dispose();
    super.dispose();
  }
}
