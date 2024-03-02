import 'package:file_manager/routes/route_shell.dart';
import 'package:file_manager/routes/routes/home.dart';
import 'package:file_manager/routes/routes/settings.dart';
import 'package:file_manager/utils/parsed_args.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final ParsedArgs parsedArgs;

  AppRouter(this.parsedArgs);

  final GoRouter goRouter = GoRouter(
    routes: [
      ShellRoute(
        routes: [
          GoRoute(
            path: '/',
            name: "home",
            builder: (context, state) => const Home(),
          ),
          GoRoute(
            path: '/settings',
            name: "settings",
            builder: (context, state) => const Settings(),
          ),
        ],
        builder: (_, state, child) => RouteShell(
          state: state,
          child: child,
        ),
      ),
    ],
  );
}
