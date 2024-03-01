import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/singletons/file_database.dart';
import 'package:file_manager/utils/db_scan_path.dart';
import 'package:file_manager/utils/static_dynamic_listview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Iterable<DbScanPath> _scanPaths = [];

  final FileDatabase _fileDatabase = FileDatabase();

  bool _fabAdded = false;

  bool isLoading = false;

  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _scanPaths = _fileDatabase.getAllPaths();
  }

  @override
  Widget build(BuildContext context) {
    if (!_fabAdded) {
      Future.delayed(Duration.zero, () {
        // context.read<TitleProvider>().fab = FloatingActionButton(
        //   onPressed: () {},
        //   child: const Icon(Icons.search),
        // );

        context.read<TitleProvider>().bottomBarChild = SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textEditingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  // setState(() {
                  context.read<TitleProvider>().bottomBarChild = const SizedBox(
                    height: 56,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  // });
                  await _fileDatabase
                      .insertPath(_textEditingController.value.text);
                  // final String searchString =
                  //     _textEditingController.value.text.toString();
                  // await compute<String, void>(
                  //   (String message) async {
                  //     await _fileDatabase.insertPath(message.toString());
                  //     // print(message);
                  //   },
                  //   "$searchString",
                  //   debugLabel: 'InsertDirIntoDbCompute',
                  // );
                  context.pushReplacement('/settings');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add path'),
              ),
            ],
          ),
        );
      });
    }

    return StaticDynamicListView(
      children: _scanPaths.map<ListTile>(
        (e) => ListTile(
          title: Text(e.path),
          subtitle: Text(
            "Last scanned at ${e.timeLastScannedAt.toLocal().toString()}",
          ),
          trailing: IconButton(
            onPressed: () {
              setState(() {
                _fileDatabase.removePath(e.id);
              });
              context.pushReplacement('/settings');
            },
            icon: const Icon(Icons.delete),
          ),
          leading: IconButton(
            onPressed: () async {
              String? newPath = await showDialog<String>(
                context: context,
                builder: (context) {
                  final TextEditingController _controller =
                      TextEditingController(text: e.path);
                  return SimpleDialog(
                    title: const Text('Enter new path'),
                    children: [
                      TextField(
                        controller: _controller,
                      ),
                      FilledButton(
                        onPressed: () {
                          context.pop<String>(_controller.value.text);
                        },
                        child: const Text("Apply and Rescan"),
                      ),
                    ],
                  );
                },
              );
              if (newPath != null) {
                await _fileDatabase.updatePath(e.id, newPath);
              }
              context.pushReplacement('/settings');
            },
            icon: const Icon(Icons.edit),
          ),
        ),
      ),
    );
  }
}
