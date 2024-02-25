import 'package:file_manager/providers/title_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<TitleProvider>().title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: child,
    );
  }
}
