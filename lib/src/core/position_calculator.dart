import 'dart:ui';

import '../config/notification_config.dart';
import '../config/notification_position.dart';

/// Calculates screen positions for notification windows
class PositionCalculator {
  const PositionCalculator._();

  /// Calculates the position for a notification based on configuration
  /// and the current stack index
  static Offset calculatePosition({
    required SteamNotificationConfig config,
    required Size windowSize,
    required int stackIndex,
    required Size screenSize,
  }) {
    double x;
    double y;

    switch (config.position) {
      case NotificationPosition.topLeft:
        x = config.margin.left;
        y = config.margin.top +
            (stackIndex * (windowSize.height + config.spacing));

      case NotificationPosition.topRight:
        x = screenSize.width - windowSize.width - config.margin.right;
        y = config.margin.top +
            (stackIndex * (windowSize.height + config.spacing));

      case NotificationPosition.bottomLeft:
        x = config.margin.left;
        y = screenSize.height -
            windowSize.height -
            config.margin.bottom -
            (stackIndex * (windowSize.height + config.spacing));

      case NotificationPosition.bottomRight:
        x = screenSize.width - windowSize.width - config.margin.right;
        y = screenSize.height -
            windowSize.height -
            config.margin.bottom -
            (stackIndex * (windowSize.height + config.spacing));
    }

    return Offset(x, y);
  }

  /// Gets the current screen size from the primary display
  static Size getScreenSize() {
    final view = PlatformDispatcher.instance.views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;

    return Size(
      physicalSize.width / devicePixelRatio,
      physicalSize.height / devicePixelRatio,
    );
  }

  /// Determines the slide direction based on notification position
  static Offset getSlideDirection(NotificationPosition position) {
    switch (position) {
      case NotificationPosition.topLeft:
      case NotificationPosition.bottomLeft:
        return const Offset(-1.0, 0.0); // Slide from left
      case NotificationPosition.topRight:
      case NotificationPosition.bottomRight:
        return const Offset(1.0, 0.0); // Slide from right
    }
  }
}
