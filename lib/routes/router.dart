import 'package:file_manager/routes/route_shell.dart';
import 'package:go_router/go_router.dart';

class Router {
  static final Router _singleton = Router._internal();

  factory Router() {
    return _singleton;
  }

  Router._internal() {}

  static final GoRouter goRouter = GoRouter(
    routes: [
      ShellRoute(
        routes: [],
        builder: (_, state, child) => RouteShell(
          state: state,
          child: child,
        ),
      ),
    ],
  );
}
