import 'dart:io';

import 'package:file_manager/providers/file_entity_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class DirectoryViewer extends StatelessWidget {
  const DirectoryViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileEntityProvider>(
      builder: (
        BuildContext context,
        FileEntityProvider provider,
        Widget? child,
      ) {
        debugPrint("Printing ${provider.fileEntities.length} items");
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            actions: [
              IconButton(
                onPressed: () {
                  provider.scanDirectory(true);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: provider.fileEntities.length,
            itemBuilder: (BuildContext context, int index) {
              FileSystemEntity entity = provider.fileEntities[index];
              return ListTile(
                title: Text(basename(entity.path)),
                subtitle: Text(entity.path),
                onTap: (FileSystemEntity.isDirectorySync(entity.path))
                    ? () {
                        context.push("/view", extra: entity.path);
                      }
                    : () {
                        Process.run(entity.path, []);
                      },
              );
            },
          ),
        );
      },
    );
  }
}
