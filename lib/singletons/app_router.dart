import 'package:file_manager/routes/app_shell.dart';
import 'package:file_manager/routes/home.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final AppRouter _appRouter = AppRouter._init();

  factory AppRouter() => _appRouter;

  AppRouter._init();

  static GoRouter goRouter = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MyHomePage(),
          )
        ],
        builder: (context, state, child) => AppShell(child: child),
      ),
    ],
  );
}
