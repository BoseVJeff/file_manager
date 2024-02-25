import 'package:flutter/material.dart';
import 'package:path/path.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            onTap: () {
              controller.openView();
            },
            onSubmitted: (value) {
              setState(() {
                // searchResults=context.read
              });
            },
          );
        },
        suggestionsBuilder: (context, controller) {
          if (searchResults.isEmpty) {
            return [
              const ListTile(
                title: Text("No reults found!"),
              )
            ];
          }
          return List<ListTile>.generate(
            searchResults.length,
            (index) => ListTile(
              title: Text(basename(searchResults[index])),
              subtitle: Text(searchResults[index]),
            ),
          );
        },
      ),
    );
  }
}
