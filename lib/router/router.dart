import 'package:file_manager/router/routes/directory_view.dart';
import 'package:file_manager/router/routes/home.dart';
import 'package:go_router/go_router.dart';

final GoRouter goRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: '/view',
      builder: (context, state) {
        print(state.fullPath);
        print(state.extra);
        return DirectoryView(
          pathEncoded: state.extra as String,
        );
      },
    ),
  ],
);
