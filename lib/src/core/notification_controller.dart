// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';

import '../config/notification_config.dart';
import '../models/active_notification.dart';
import '../models/notification.dart';
import '../presentation/notification_container.dart';
import '../windows/notification_delegate.dart';
import '../windows/notification_window.dart';
import 'notification_queue.dart';
import 'position_calculator.dart';

/// Controller that manages the notification system
///
/// Handles showing, dismissing, and queuing notifications.
/// Uses Flutter's multi-window APIs to display each notification
/// in its own separate window.
class NotificationController {
  /// Creates a notification controller with the given configuration
  NotificationController(this._config);

  SteamNotificationConfig _config;
  final List<ActiveNotification> _activeNotifications = [];
  final NotificationQueue _pendingQueue = NotificationQueue();

  /// Current configuration
  SteamNotificationConfig get config => _config;

  /// Number of currently visible notifications
  int get activeCount => _activeNotifications.length;

  /// Number of queued notifications
  int get queuedCount => _pendingQueue.length;

  /// Updates the configuration
  void configure(SteamNotificationConfig config) {
    _config = config;
  }

  /// Shows a notification
  ///
  /// If the maximum number of visible notifications is reached,
  /// the notification is queued and shown when a slot becomes available.
  Future<void> show(SteamNotification notification) async {
    if (_activeNotifications.length >= _config.maxVisibleNotifications) {
      _pendingQueue.enqueue(notification);
      return;
    }

    await _displayNotification(notification);
  }

  /// Dismisses a notification by ID
  void dismiss(String id) {
    final index = _activeNotifications.indexWhere(
      (n) => n.notification.id == id,
    );

    if (index == -1) {
      _pendingQueue.remove(id);
      return;
    }

    final active = _activeNotifications.removeAt(index);
    active.cancelTimer();
    active.notification.onDismiss?.call();

    final controller = active.controller as RegularWindowController;
    controller.destroy();

    _processQueue();
  }

  /// Dismisses all visible and queued notifications
  void dismissAll() {
    _pendingQueue.clear();

    for (final active in _activeNotifications.toList()) {
      active.cancelTimer();
      active.notification.onDismiss?.call();

      final controller = active.controller as RegularWindowController;
      controller.destroy();
    }

    _activeNotifications.clear();
  }

  Future<void> _displayNotification(SteamNotification notification) async {
    final size = _getNotificationSize(notification);
    final screenSize = PositionCalculator.getScreenSize();
    final position = PositionCalculator.calculatePosition(
      config: _config,
      windowSize: size,
      stackIndex: _activeNotifications.length,
      screenSize: screenSize,
    );

    final controller = RegularWindowController(
      preferredSize: size,
      title: '',
      delegate: NotificationWindowDelegate(
        onDestroyed: () => _handleWindowDestroyed(notification.id),
      ),
    );

    final activeNotification = ActiveNotification(
      notification: notification,
      controller: controller,
      position: position,
      size: size,
      dismissCallback: dismiss,
    );

    _activeNotifications.add(activeNotification);

    // Create and run the notification widget
    runWidget(
      NotificationWindow(
        controller: controller,
        child: NotificationContainer(
          notification: notification,
          config: _config,
          onDismiss: () => dismiss(notification.id),
        ),
      ),
    );

    // Schedule auto-dismiss
    _scheduleAutoDismiss(activeNotification);
  }

  void _scheduleAutoDismiss(ActiveNotification active) {
    final duration = active.notification.duration ?? _config.defaultDuration;

    active.dismissTimer = Timer(duration, () {
      dismiss(active.notification.id);
    });
  }

  void _handleWindowDestroyed(String id) {
    final index = _activeNotifications.indexWhere(
      (n) => n.notification.id == id,
    );

    if (index != -1) {
      final active = _activeNotifications[index];
      active.cancelTimer();
      _activeNotifications.removeAt(index);
      _processQueue();
    }
  }

  void _processQueue() {
    if (_pendingQueue.isEmpty) return;
    if (_activeNotifications.length >= _config.maxVisibleNotifications) return;

    final next = _pendingQueue.dequeue();
    if (next != null) {
      _displayNotification(next);
    }
  }

  Size _getNotificationSize(SteamNotification notification) {
    final width = switch (notification) {
      CustomNotification(width: final w?) => w,
      _ => _config.defaultWidth,
    };

    final height = switch (notification) {
      AchievementNotification() => _config.achievementHeight,
      MessageNotification() => _config.messageHeight,
      CustomNotification(height: final h?) => h,
      CustomNotification() => _config.achievementHeight,
    };

    return Size(width, height);
  }
}
