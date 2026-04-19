// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';

import '../config/notification_config.dart';
import '../models/notification.dart';
import '../presentation/stack_view.dart';
import '../windows/notification_window.dart';
import 'steam_notification_service.dart';

/// Builder function for custom notification UI (per-notification content).
typedef NotificationBuilder =
    Widget Function(
      BuildContext context,
      SteamNotification notification,
      VoidCallback onDismiss,
    );

/// Widget that renders the active notification stack as a [ViewAnchor]
/// child of [child].
///
/// This is the legacy integration: notifications disappear when the
/// host widget tree unmounts. For apps that close their main window to
/// a tray, prefer rendering the stack at the root level via
/// `SteamNotifications.buildNotificationViews()` inside a
/// [ViewCollection].
class NotificationManager extends StatefulWidget {
  const NotificationManager({
    required this.child,
    this.config,
    this.notificationBuilder,
    super.key,
  });

  final Widget child;
  final SteamNotificationConfig? config;
  final NotificationBuilder? notificationBuilder;

  static NotificationManagerState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<NotificationManagerState>();
  }

  static NotificationManagerState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No NotificationManager found in context');
    return state!;
  }

  @override
  State<NotificationManager> createState() => NotificationManagerState();
}

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
        final controller = _service.stackController;
        final entries = _service.activeNotifications;
        if (controller == null || entries.isEmpty) {
          return widget.child;
        }
        return ViewAnchor(
          view: NotificationWindow(
            key: const ValueKey('steam-notification-stack'),
            controller: controller,
            child: StackView(
              entries: entries,
              config: _service.config,
              notificationBuilder: _service.notificationBuilder,
              onDismiss: _service.dismiss,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
