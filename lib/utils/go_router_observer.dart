import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

class GoRouterObeserver extends NavigatorObserver {
  final Logger _logger = Logger("GoRouterObserver");

  @override
  void didPop(Route route, Route? previousRoute) {
    _logger.fine(
        "Popped: ${previousRoute?.settings.name} --> ${route.settings.name}");
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _logger.fine(
        "Pushed: ${previousRoute?.settings.name} --> ${route.settings.name}");
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _logger.fine(
        "Removed: ${previousRoute?.settings.name} --> ${route.settings.name}");
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _logger.fine(
        "Replaced: ${oldRoute?.settings.name} --> ${newRoute?.settings.name}");
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _logger.fine(
        "User Gesture Started: ${previousRoute?.settings.name} --> ${route.settings.name}");
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    _logger.fine("User Gesture Stopped:");
    super.didStopUserGesture();
  }
}
