import 'package:file_manager/routes/app_shell.dart';
import 'package:file_manager/routes/home.dart';
import 'package:file_manager/routes/search.dart';
import 'package:file_manager/routes/settings.dart';
import 'package:file_manager/utils/go_router_observer.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final AppRouter _appRouter = AppRouter._init();

  factory AppRouter() => _appRouter;

  AppRouter._init();

  static GoRouter goRouter = GoRouter(
    observers: [
      GoRouterObeserver(),
    ],
    initialLocation: '/search',
    routes: [
      ShellRoute(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MyHomePage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Settings(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const Search(),
          ),
        ],
        builder: (context, state, child) => AppShell(child: child),
      ),
    ],
  );
}
