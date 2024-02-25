import 'package:file_manager/providers/database_provider.dart';
import 'package:file_manager/providers/file_entity_provider.dart';
import 'package:file_manager/router/routes/directory_viewer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DirectoryView extends StatelessWidget {
  final String? pathEncoded;

  const DirectoryView({super.key, required this.pathEncoded});

  @override
  Widget build(BuildContext context) {
    if (pathEncoded == null) {
      return const Center(
        child: Text("Path null!"),
      );
    }
    String path = Uri.decodeComponent(pathEncoded!);
    debugPrint("Using $path");
    try {
      return ChangeNotifierProvider(
        create: (_) =>
            FileEntityProvider(path, context.read<DatabaseProvider>().db),
        builder: (context, child) => const DirectoryViewer(),
      );
    } on FileNotFoundException {
      return Center(child: Text("$path not found!"));
    } on UnimplementedFileTypeException {
      return Center(
        child: Text("$path is not a file, directory, or link!"),
      );
    } on Exception catch (e, s) {
      debugPrint(s.toString());
      return Center(
        child: Text(
          e.toString(),
        ),
      );
    }
  }
}
