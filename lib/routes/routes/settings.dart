import 'package:file_manager/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed("home");
            },
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, value, child) {
          return const Center(
            child: Text("Settings Page"),
          );
        },
      ),
    );
  }
}
