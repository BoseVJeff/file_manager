import 'package:file_manager/providers/settings_provider.dart';
import 'package:file_manager/utils/static_dynamic_listview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, value, child) {
        return StaticDynamicListView(
          children: [
            const ListTile(
              title: Text('Paths'),
            ),
            ...List<Widget>.generate(
                value.paths.length, (index) => Text(value.paths[index]))
          ],
        );
      },
    );
  }
}
