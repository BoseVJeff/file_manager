import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed("settings");
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Center(
        child: const Text("Hello World!"),
      ),
    );
  }
}
