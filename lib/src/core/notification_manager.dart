// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:window_decoration/window_decoration.dart';

import '../config/notification_config.dart';
import '../config/notification_position.dart';
import '../models/notification.dart';
import '../presentation/notification_container.dart';
import '../theme/steam_theme.dart';
import 'notification_queue.dart';

/// Builder function for custom notification UI
typedef NotificationBuilder = Widget Function(
  BuildContext context,
  SteamNotification notification,
  VoidCallback onDismiss,
);

/// Internal state for tracking an active notification
class _ActiveNotificationState {
  _ActiveNotificationState({
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

/// Delegate for handling notification window lifecycle events
class _NotificationWindowDelegate extends RegularWindowControllerDelegate {
  _NotificationWindowDelegate({
    required this.onDestroyed,
    required this.onCreated,
  });

  final VoidCallback onDestroyed;
  final VoidCallback onCreated;

  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    onDestroyed();
  }
}

/// Widget that manages all notification windows
///
/// This widget must be placed in the widget tree (typically wrapping the main app)
/// to enable notification windows to be created as part of the widget tree
/// rather than via separate runWidget calls.
///
/// Example:
/// ```dart
/// runWidget(
///   RegularWindow(
///     controller: controller,
///     child: NotificationManager(
///       key: SteamNotifications.managerKey,
///       config: const SteamNotificationConfig(
///         position: NotificationPosition.bottomRight,
///       ),
///       child: const MyApp(),
///     ),
///   ),
/// );
/// ```
class NotificationManager extends StatefulWidget {
  /// Creates a notification manager
  const NotificationManager({
    required this.child,
    this.config,
    this.notificationBuilder,
    super.key,
  });

  /// The child widget (usually the main app)
  final Widget child;

  /// Initial configuration for notifications
  final SteamNotificationConfig? config;

  /// Optional custom builder for notification UI
  ///
  /// If provided, this builder will be used instead of the default
  /// Steam-style notification UI. This allows full customization
  /// of the notification appearance.
  final NotificationBuilder? notificationBuilder;

  /// Gets the notification manager state from context
  static NotificationManagerState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<NotificationManagerState>();
  }

  /// Gets the notification manager state from context, throwing if not found
  static NotificationManagerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No NotificationManager found in context');
    return state!;
  }

  @override
  State<NotificationManager> createState() => NotificationManagerState();
}

/// State for [NotificationManager]
class NotificationManagerState extends State<NotificationManager> {
  late SteamNotificationConfig _config;
  final List<_ActiveNotificationState> _activeNotifications = [];
  final NotificationQueue _pendingQueue = NotificationQueue();
  NotificationBuilder? _notificationBuilder;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? const SteamNotificationConfig();
    _notificationBuilder = widget.notificationBuilder;
  }

  /// Current configuration
  SteamNotificationConfig get config => _config;

  /// Number of currently visible notifications
  int get activeCount => _activeNotifications.length;

  /// Number of queued notifications
  int get queuedCount => _pendingQueue.length;

  /// Updates the configuration
  void configure(SteamNotificationConfig config) {
    setState(() {
      _config = config;
    });
  }

  /// Sets a custom notification builder
  void setNotificationBuilder(NotificationBuilder? builder) {
    setState(() {
      _notificationBuilder = builder;
    });
  }

  /// Shows a notification
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
    active.controller.destroy();

    setState(() {});
    _processQueue();
  }

  /// Dismisses all visible and queued notifications
  void dismissAll() {
    _pendingQueue.clear();

    for (final active in _activeNotifications.toList()) {
      active.cancelTimer();
      active.notification.onDismiss?.call();
      active.controller.destroy();
    }

    setState(() {
      _activeNotifications.clear();
    });
  }

  Future<void> _displayNotification(SteamNotification notification) async {
    final size = _getNotificationSize(notification);
    final stackIndex = _activeNotifications.length;

    // Calculate position for the notification
    final position = _calculatePosition(size, stackIndex);

    final controller = RegularWindowController(
      preferredSize: size,
      title: '',
      delegate: _NotificationWindowDelegate(
        onDestroyed: () => _handleWindowDestroyed(notification.id),
        onCreated: () {},
      ),
    );

    final activeNotification = _ActiveNotificationState(
      notification: notification,
      controller: controller,
      size: size,
      stackIndex: stackIndex,
    );

    setState(() {
      _activeNotifications.add(activeNotification);
    });

    // Configure the window after it's created using window_decoration
    // We need to wait a frame for the window to be created
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _configureNotificationWindow(controller, position, size);
    });

    // Schedule auto-dismiss
    _scheduleAutoDismiss(activeNotification);
  }

  /// Configure the notification window to be borderless, positioned correctly,
  /// and hidden from taskbar
  Future<void> _configureNotificationWindow(
    RegularWindowController controller,
    Offset position,
    Size size,
  ) async {
    final service = WindowDecorationService(controller);

    // Hide title bar first
    await service.setTitleBarStyle(TitleBarStyle.hidden);

    // Set window position and size
    await service.setBounds(WindowBounds(
      x: position.dx,
      y: position.dy,
      width: size.width,
      height: size.height,
    ));

    // Hide from taskbar
    await service.setSkipTaskbar(skip: true);

    // Keep notifications on top
    await service.setAlwaysOnTop(alwaysOnTop: true);

    // Show the window
    await service.show();
  }

  /// Calculate the position for a notification based on config and stack index
  Offset _calculatePosition(Size notificationSize, int stackIndex) {
    // Get the actual screen/display size from the platform dispatcher
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    final screenSize = display.size / display.devicePixelRatio;

    final margin = _config.margin;
    final spacing = _config.spacing;

    // Calculate the vertical offset for stacking
    final stackOffset = stackIndex * (notificationSize.height + spacing);

    double left, top;

    switch (_config.position) {
      case NotificationPosition.topLeft:
        left = margin.left;
        top = margin.top + stackOffset;
      case NotificationPosition.topRight:
        left = screenSize.width - margin.right - notificationSize.width;
        top = margin.top + stackOffset;
      case NotificationPosition.bottomLeft:
        left = margin.left;
        top = screenSize.height -
            margin.bottom -
            notificationSize.height -
            stackOffset;
      case NotificationPosition.bottomRight:
        left = screenSize.width - margin.right - notificationSize.width;
        top = screenSize.height -
            margin.bottom -
            notificationSize.height -
            stackOffset;
    }

    return Offset(left, top);
  }

  void _scheduleAutoDismiss(_ActiveNotificationState active) {
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
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    // Each notification window renders in its own OS window with an independent
    // render tree. We use ViewAnchor to attach these independent views to the
    // widget tree without making them children of the main render tree.
    Widget result = widget.child;

    // Wrap the child with ViewAnchors for each active notification
    for (final active in _activeNotifications) {
      result = ViewAnchor(
        view: _NotificationWindowWidget(
          key: ValueKey(active.notification.id),
          controller: active.controller,
          notification: active.notification,
          config: _config,
          onDismiss: () => dismiss(active.notification.id),
          customBuilder: _notificationBuilder,
        ),
        child: result,
      );
    }

    return result;
  }
}

/// Widget that renders a single notification window
class _NotificationWindowWidget extends StatelessWidget {
  const _NotificationWindowWidget({
    required this.controller,
    required this.notification,
    required this.config,
    required this.onDismiss,
    this.customBuilder,
    super.key,
  });

  final RegularWindowController controller;
  final SteamNotification notification;
  final SteamNotificationConfig config;
  final VoidCallback onDismiss;
  final NotificationBuilder? customBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) {
        return WindowScope(
          controller: controller,
          child: View(
            view: controller.rootView,
            child: MediaQuery.fromView(
              view: controller.rootView,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Theme(
                  data: steamNotificationTheme(),
                  child: _buildContent(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget content;
    if (customBuilder != null) {
      content = customBuilder!(context, notification, onDismiss);
    } else {
      content = NotificationContainer(
        notification: notification,
        config: config,
        onDismiss: onDismiss,
      );
    }

    // Ensure the content fills the entire window with a transparent background
    // to avoid any black areas from the window frame
    return ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: content,
      ),
    );
  }
}
