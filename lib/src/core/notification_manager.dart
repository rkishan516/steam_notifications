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
  _NotificationWindowDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

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

    // Calculate position in physical pixels (setBounds uses physical coords)
    final position = _calculatePosition(size, stackIndex);

    // Get physical size for setBounds
    final dpr = WidgetsBinding
        .instance.platformDispatcher.displays.first.devicePixelRatio;
    final physicalSize = size * dpr;

    final controller = RegularWindowController(
      preferredSize: size,
      title: '',
      delegate: _NotificationWindowDelegate(
        onDestroyed: () => _handleWindowDestroyed(notification.id),
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

    // Configure the window after the first frame so the controller's
    // view is initialized. The window starts hidden and is only shown
    // after positioning via service.show() in _configureNotificationWindow.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _configureNotificationWindow(controller, position, physicalSize);
    });

    // Schedule auto-dismiss
    _scheduleAutoDismiss(activeNotification);
  }

  /// Configure the notification window to be borderless, positioned correctly,
  /// and hidden from taskbar.
  ///
  /// [position] and [physicalSize] must be in physical pixel coordinates
  /// since [WindowDecorationService.setBounds] maps directly to
  /// Win32 SetWindowPos.
  Future<void> _configureNotificationWindow(
    RegularWindowController controller,
    Offset position,
    Size physicalSize,
  ) async {
    final service = WindowDecorationService(controller);

    // Hide title bar first
    await service.setTitleBarStyle(TitleBarStyle.hidden);

    // Set window position and size in physical pixels
    await service.setBounds(WindowBounds(
      x: position.dx,
      y: position.dy,
      width: physicalSize.width,
      height: physicalSize.height,
    ));

    // Prevent user from resizing the notification window
    await service.setSizeConstraints(
      minWidth: physicalSize.width,
      minHeight: physicalSize.height,
      maxWidth: physicalSize.width,
      maxHeight: physicalSize.height,
    );

    // Set background color to match notification theme
    await service.setBackgroundColor(const Color(0xFF1B2838));

    // Hide from taskbar
    await service.setSkipTaskbar(skip: true);

    // Keep notifications on top
    await service.setAlwaysOnTop(alwaysOnTop: true);

    // Show the window
    await service.show();
  }

  /// Calculate the position for a notification based on config and stack index.
  ///
  /// Returns position in physical pixel coordinates because
  /// [WindowDecorationService.setBounds] passes values directly to
  /// Win32 SetWindowPos which operates in physical screen coordinates.
  Offset _calculatePosition(Size notificationSize, int stackIndex) {
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    final dpr = display.devicePixelRatio;
    // Use physical pixel screen size since setBounds uses physical coordinates
    final screenSize = display.size;

    final margin = _config.margin;
    final spacing = _config.spacing;

    // Scale notification size and layout values to physical pixels
    final physicalWidth = notificationSize.width * dpr;
    final physicalHeight = notificationSize.height * dpr;
    final physicalSpacing = spacing * dpr;
    final stackOffset = stackIndex * (physicalHeight + physicalSpacing);

    double left, top;

    switch (_config.position) {
      case NotificationPosition.topLeft:
        left = margin.left * dpr;
        top = margin.top * dpr + stackOffset;
      case NotificationPosition.topRight:
        left = screenSize.width - margin.right * dpr - physicalWidth;
        top = margin.top * dpr + stackOffset;
      case NotificationPosition.bottomLeft:
        left = margin.left * dpr;
        top = screenSize.height -
            margin.bottom * dpr -
            physicalHeight -
            stackOffset;
      case NotificationPosition.bottomRight:
        left = screenSize.width - margin.right * dpr - physicalWidth;
        top = screenSize.height -
            margin.bottom * dpr -
            physicalHeight -
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
