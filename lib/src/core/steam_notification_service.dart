// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';
import 'package:window_decoration/window_decoration.dart';

import '../config/notification_config.dart';
import '../config/notification_position.dart';
import '../models/notification.dart';
import '../theme/steam_colors.dart';
import '../windows/notification_delegate.dart';
import 'notification_manager.dart' show NotificationBuilder;
import 'notification_queue.dart';

/// Runtime entry for a single live notification managed by
/// [SteamNotificationService].
class ActiveNotificationEntry {
  ActiveNotificationEntry({
    required this.notification,
    required this.controller,
    required this.size,
    required this.stackIndex,
  });

  final SteamNotification notification;
  final RegularWindowController controller;
  final Size size;
  final int stackIndex;
  Timer? dismissTimer;

  void cancelTimer() {
    dismissTimer?.cancel();
    dismissTimer = null;
  }
}

/// Singleton that owns notification state for the whole app lifecycle.
///
/// The state lives outside any widget, so notifications keep working
/// when the host window is torn down (e.g. minimised to a system tray).
/// Render the active notifications either by keeping a
/// [NotificationManager] in the tree, or by placing
/// `SteamNotifications.buildNotificationViews()` into a root-level
/// [ViewCollection].
class SteamNotificationService extends ChangeNotifier {
  SteamNotificationService._();

  static final SteamNotificationService instance =
      SteamNotificationService._();

  SteamNotificationConfig _config = const SteamNotificationConfig();
  final List<ActiveNotificationEntry> _activeNotifications = [];
  final NotificationQueue _pendingQueue = NotificationQueue();
  NotificationBuilder? _notificationBuilder;

  SteamNotificationConfig get config => _config;

  NotificationBuilder? get notificationBuilder => _notificationBuilder;

  List<ActiveNotificationEntry> get activeNotifications =>
      List.unmodifiable(_activeNotifications);

  int get activeCount => _activeNotifications.length;

  int get queuedCount => _pendingQueue.length;

  void configure(SteamNotificationConfig config) {
    _config = config;
    notifyListeners();
  }

  void setNotificationBuilder(NotificationBuilder? builder) {
    _notificationBuilder = builder;
    notifyListeners();
  }

  Future<void> show(SteamNotification notification) async {
    if (_activeNotifications.length >= _config.maxVisibleNotifications) {
      _pendingQueue.enqueue(notification);
      return;
    }
    await _displayNotification(notification);
  }

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
    active.controller.destroy();

    notifyListeners();
    _processQueue();
  }

  void dismissAll() {
    _pendingQueue.clear();

    for (final active in _activeNotifications.toList()) {
      active.cancelTimer();
      active.notification.onDismiss?.call();
      active.controller.destroy();
    }

    _activeNotifications.clear();
    notifyListeners();
  }

  Future<void> _displayNotification(SteamNotification notification) async {
    final size = _getNotificationSize(notification);
    final stackIndex = _activeNotifications.length;

    final position = _calculatePosition(size, stackIndex);

    final dpr = WidgetsBinding
        .instance
        .platformDispatcher
        .displays
        .first
        .devicePixelRatio;
    final physicalSize = size * dpr;

    final controller = RegularWindowController(
      preferredSize: size,
      title: '',
      delegate: NotificationWindowDelegate(
        onDestroyed: () => _handleWindowDestroyed(notification.id),
      ),
    );

    final entry = ActiveNotificationEntry(
      notification: notification,
      controller: controller,
      size: size,
      stackIndex: stackIndex,
    );

    _activeNotifications.add(entry);
    notifyListeners();

    // Defer native Win32 calls to the next event loop turn so they don't
    // re-enter the scheduler during a post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.run(() async {
        await _configureNotificationWindow(controller, position, physicalSize);
      });
    });

    _scheduleAutoDismiss(entry);
  }

  Future<void> _configureNotificationWindow(
    RegularWindowController controller,
    Offset position,
    Size physicalSize,
  ) async {
    controller.enableDecoratedWindow();
    controller.setSize(Size(physicalSize.width, physicalSize.height));
    final window = DecoratedWindow.forController(controller);
    window?.setPosition(Offset(position.dx, position.dy));

    controller.setConstraints(
      BoxConstraints(
        minWidth: physicalSize.width,
        minHeight: physicalSize.height,
        maxWidth: physicalSize.width,
        maxHeight: physicalSize.height,
      ),
    );

    await window?.setBackgroundColor(SteamColors.surface);
    await window?.setSkipTaskbar(skip: true);
    await window?.setAlwaysOnTop(alwaysOnTop: true);
    await window?.show();
  }

  Offset _calculatePosition(Size notificationSize, int stackIndex) {
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    final dpr = display.devicePixelRatio;
    final screenSize = display.size;

    final margin = _config.margin;
    final spacing = _config.spacing;

    final physicalWidth = notificationSize.width * dpr;
    final physicalHeight = notificationSize.height * dpr;
    final physicalSpacing = spacing * dpr;
    final stackOffset = stackIndex * (physicalHeight + physicalSpacing);

    double left;
    double top;

    switch (_config.position) {
      case NotificationPosition.topLeft:
        left = margin.left * dpr;
        top = margin.top * dpr + stackOffset;
      case NotificationPosition.topRight:
        left = screenSize.width - margin.right * dpr - physicalWidth;
        top = margin.top * dpr + stackOffset;
      case NotificationPosition.bottomLeft:
        left = margin.left * dpr;
        top =
            screenSize.height -
            margin.bottom * dpr -
            physicalHeight -
            stackOffset;
      case NotificationPosition.bottomRight:
        left = screenSize.width - margin.right * dpr - physicalWidth;
        top =
            screenSize.height -
            margin.bottom * dpr -
            physicalHeight -
            stackOffset;
    }

    return Offset(left, top);
  }

  void _scheduleAutoDismiss(ActiveNotificationEntry active) {
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
      final active = _activeNotifications.removeAt(index);
      active.cancelTimer();
      notifyListeners();
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
