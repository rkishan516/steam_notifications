import 'dart:async';
import 'dart:ui';

import 'notification.dart';

/// Represents a currently active notification with its runtime state
class ActiveNotification {
  /// Creates an active notification tracker
  ActiveNotification({
    required this.notification,
    required this.controller,
    required this.position,
    required this.size,
    this.dismissTimer,
    this.dismissCallback,
  });

  /// The notification data
  final SteamNotification notification;

  /// The window controller managing this notification's window
  final dynamic controller;

  /// Current position on screen
  Offset position;

  /// Size of the notification window
  final Size size;

  /// Timer for auto-dismiss
  Timer? dismissTimer;

  /// Callback to trigger dismissal from within the notification
  final void Function(String id)? dismissCallback;

  /// Cancel any pending auto-dismiss timer
  void cancelTimer() {
    dismissTimer?.cancel();
    dismissTimer = null;
  }
}
