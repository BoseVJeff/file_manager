import 'package:file_manager/providers/title_provider.dart';
import 'package:file_manager/singletons/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  static final Logger _logger = Logger("AppShell");

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<TitleProvider>(
      builder: (context, provider, child) {
        _logger.finest(AppRouter.goRouter.canPop());
        return Scaffold(
          appBar: AppBar(
            title: provider.title,
            actions: provider.appbarActions(context),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            // leading: IconButton(
            //   onPressed: () {
            //     try {
            //       context.pop(context);
            //     } on Exception catch (e, s) {
            //       _logger.warning("Exception: There is nothing to pop!", e, s);
            //     } on Error catch (e, s) {
            //       _logger.warning("Error: There is nothing to pop!", e, s);
            //     }
            //   },
            //   icon: const Icon(Icons.arrow_back),
            // ),
            // leading: (AppRouter.goRouter.canPop())
            //     ? IconButton(
            //         onPressed: () {
            //           context.pop();
            //         },
            //         icon: const Icon(Icons.arrow_back),
            //       )
            //     : null,
          ),
          body: child,
          floatingActionButton: provider.fab,
          bottomNavigationBar: provider.bottomBarChild,
        );
      },
      child: child,
    );
  }
}
