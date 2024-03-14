import 'dart:io';

import 'package:file_manager/utils/database_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

class Search extends StatefulWidget {
  final String? initialSearchTerm;
  const Search({super.key, this.initialSearchTerm});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  // Controller for the search box
  late TextEditingController editingController;
  // The files returned as a result of the search query
  Iterable<DatabaseFile> files = [];
  // If the widget is searching
  bool isSearching = false;
  // Default drive letter
  static final defaultDriveLetter = rootPrefix(Platform.executable);
  // Logger
  static final Logger _logger = Logger("Search");

  @override
  void initState() {
    super.initState();
    // Populating the search field with the search box
    editingController = TextEditingController(text: widget.initialSearchTerm);
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: editingController,
        ),
        leading: Center(
          child: (isSearching)
              ? const CircularProgressIndicator()
              : const Icon(Icons.search),
        ),
      ),
      body: (files.isEmpty)
          ? const Center(child: Text("Enter some text to start searching!"))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                DatabaseFile file = files.elementAt(index);
                return Card(
                  child: ListTile(
                    title: Text(basename(file.path)),
                    subtitle: Text(
                      join(file.driveRoot ?? defaultDriveLetter, file.path),
                    ),
                    onTap: () async {
                      try {
                        await launchUrl(
                          Uri(
                            host: file.driveRoot ?? defaultDriveLetter,
                            path: file.path,
                          ),
                        );
                      } on PlatformException catch (_) {
                        _logger.warning(
                          "Failed to launch ${file.path} on drive ${file.driveRoot ?? defaultDriveLetter}",
                        );
                      } catch (e, s) {
                        _logger.severe("Unknown error", e, s);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
