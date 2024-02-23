import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/router/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final TextEditingController _textEditingController = TextEditingController();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Consumer<TitleProvider>(builder: (context, provider, child) {
          return Text(provider.title);
        }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _textEditingController,
            ),
            FilledButton.icon(
              onPressed: () async {
                var uri = Uri(path: "/view", queryParameters: {
                  "path": _textEditingController.value.text
                });
                debugPrint("Pushing ${uri.toString()}");
                await goRouter.push(
                  uri.toString(),
                  extra: _textEditingController.value.text,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Open Directory"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
