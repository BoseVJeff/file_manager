import 'package:file_manager/providers/app_settings_provider.dart';
import 'package:file_manager/providers/file_database_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RouteShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const RouteShell({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(),
        ),
        ChangeNotifierProvider<FileDatabaseProvider>(
          create: (_) => FileDatabaseProvider(),
          lazy: false,
        ),
      ],
      child: child,
    );
  }
}
