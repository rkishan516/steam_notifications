// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import '../config/notification_config.dart';
import '../models/notification.dart';
import '../presentation/notification_container.dart';
import '../theme/steam_theme.dart';
import 'steam_notification_service.dart';

/// Builder function for custom notification UI
typedef NotificationBuilder =
    Widget Function(
      BuildContext context,
      SteamNotification notification,
      VoidCallback onDismiss,
    );

/// Widget that renders all currently active notifications as nested
/// [ViewAnchor] children of [child].
///
/// This is the legacy integration: it ties the notification views to
/// the host widget tree, which means they disappear when the host
/// unmounts (e.g. when the main window is closed to a system tray).
///
/// For apps that close their main window to a tray, prefer rendering
/// notifications at the root level via
/// `SteamNotifications.buildNotificationViews()` inside a
/// [ViewCollection].
class NotificationManager extends StatefulWidget {
  /// Creates a notification manager.
  const NotificationManager({
    required this.child,
    this.config,
    this.notificationBuilder,
    super.key,
  });

  /// The child widget (usually the main app).
  final Widget child;

  /// Initial configuration for notifications. Applied once on mount.
  final SteamNotificationConfig? config;

  /// Optional custom builder for notification UI.
  final NotificationBuilder? notificationBuilder;

  /// Gets the notification manager state from context.
  static NotificationManagerState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<NotificationManagerState>();
  }

  /// Gets the notification manager state from context, asserting non-null.
  static NotificationManagerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No NotificationManager found in context');
    return state!;
  }

  @override
  State<NotificationManager> createState() => NotificationManagerState();
}

/// State for [NotificationManager]. All notification state lives in
/// [SteamNotificationService]; this class is a thin widget-layer view.
class NotificationManagerState extends State<NotificationManager> {
  SteamNotificationService get _service => SteamNotificationService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _service.configure(widget.config!);
    }
    if (widget.notificationBuilder != null) {
      _service.setNotificationBuilder(widget.notificationBuilder);
    }
  }

  SteamNotificationConfig get config => _service.config;

  int get activeCount => _service.activeCount;

  int get queuedCount => _service.queuedCount;

  void configure(SteamNotificationConfig config) => _service.configure(config);

  void setNotificationBuilder(NotificationBuilder? builder) =>
      _service.setNotificationBuilder(builder);

  Future<void> show(SteamNotification notification) =>
      _service.show(notification);

  void dismiss(String id) => _service.dismiss(id);

  void dismissAll() => _service.dismissAll();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        Widget result = widget.child;
        for (final active in _service.activeNotifications) {
          result = ViewAnchor(
            view: _NotificationWindowWidget(
              key: ValueKey(active.notification.id),
              controller: active.controller,
              notification: active.notification,
              config: _service.config,
              onDismiss: () => _service.dismiss(active.notification.id),
              customBuilder: _service.notificationBuilder,
            ),
            child: result,
          );
        }
        return result;
      },
    );
  }
}

/// Renders a single notification window as a [View] suitable for
/// nesting inside a [ViewAnchor].
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
      builder: (BuildContext context, Widget? _) {
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
                  child: NotificationContentHost(
                    notification: notification,
                    config: config,
                    onDismiss: onDismiss,
                    customBuilder: customBuilder,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Internal widget that resolves notification content (custom builder
/// or default [NotificationContainer]) and fills the window.
///
/// Exposed at library-internal level so the root-level renderer can
/// reuse it without duplicating logic.
class NotificationContentHost extends StatelessWidget {
  /// Creates a content host.
  const NotificationContentHost({
    required this.notification,
    required this.config,
    required this.onDismiss,
    this.customBuilder,
    super.key,
  });

  /// The notification to render.
  final SteamNotification notification;

  /// Active notification configuration.
  final SteamNotificationConfig config;

  /// Invoked when the notification should close.
  final VoidCallback onDismiss;

  /// Optional custom builder for notification UI.
  final NotificationBuilder? customBuilder;

  @override
  Widget build(BuildContext context) {
    final content = customBuilder != null
        ? customBuilder!(context, notification, onDismiss)
        : NotificationContainer(
            notification: notification,
            config: config,
            onDismiss: onDismiss,
          );

    return ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(child: content),
    );
  }
}
