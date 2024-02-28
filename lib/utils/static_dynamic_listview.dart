import 'package:flutter/widgets.dart';

class StaticDynamicListView extends StatelessWidget {
  final Iterable<Widget> children;

  const StaticDynamicListView({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (_, index) {
        return children.elementAt(index);
      },
    );
  }
}
