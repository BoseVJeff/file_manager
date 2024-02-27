import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/singletons/file_database.dart';
import 'package:file_manager/utils/db_file.dart';
import 'package:file_manager/utils/static_dynamic_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final Logger _logger = Logger("Search");

  final FileDatabase _fileDatabase = FileDatabase();

  final TextEditingController _textEditingController = TextEditingController();

  Iterable<DbFile> _files = [];

  bool isFabSet = false;

  @override
  void initState() {
    super.initState();
    searchFiles("");
    _textEditingController.addListener(() {
      searchFiles(_textEditingController.value.text);
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void searchFiles(String str) {
    // _logger.fine("Searching for $str");
    setState(() {
      _files = _fileDatabase.getFileByName(str);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isFabSet) {
      Future.delayed(Duration.zero, () {
        context.read<TitleProvider>().fab = FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.search),
        );

        context.read<TitleProvider>().bottomBarChild = SizedBox(
          height: 56,
          child: TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchFiles(value);
            },
          ),
        );
      });
    }

    return StaticDynamicListView(
      children: _files.map<ListTile>(
        (e) => ListTile(
          title: Text(e.filePath),
          subtitle: Text(e.fileDriveRoot),
        ),
      ),
    );
  }
}
