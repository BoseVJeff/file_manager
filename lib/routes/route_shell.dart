import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const RouteShell({
    super.key,
    required this.state,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
