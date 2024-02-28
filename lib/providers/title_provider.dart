import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class TitleProvider extends ChangeNotifier {
  Widget _title = const Text("");

  Widget? _fab;

  Widget? get fab => _fab;

  set fab(Widget? value) {
    _fab = value;
    notifyListeners();
  }

  Widget? _bottomBarChild;

  Widget? get bottomBarChild => _bottomBarChild;

  set bottomBarChild(Widget? value) {
    _bottomBarChild = value;
    notifyListeners();
  }

  List<(Icon routeIcon, String route, String? routeName)> actionsList = [
    (const Icon(Icons.settings), '/settings', 'Settings'),
    (const Icon(Icons.search), '/search', 'Search'),
  ];

  List<Widget> appbarActions(BuildContext context) {
    List<Widget> list = [];
    for (var element in actionsList) {
      list.add(
        IconButton(
          onPressed: () async {
            context.pushReplacement(element.$2);
          },
          icon: element.$1,
          tooltip: element.$3,
        ),
      );
    }
    return list;
  }

  final Logger _logger = Logger("TitleProvider");

  TitleProvider() {
    title = const Text("File Manager");
  }

  Widget get title => _title;

  set title(Widget newTitle) {
    _title = newTitle;
    _logger.config("Changed title");
    notifyListeners();
  }

  set titleString(String newTitle) {
    _title = Text(newTitle);
    _logger.config("Changed title to '$newTitle'");
    notifyListeners();
  }
}
