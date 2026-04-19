import 'package:flutter/material.dart';

import '../config/notification_config.dart';
import '../models/notification.dart';
import 'achievement_view.dart';
import 'custom_view.dart';
import 'message_view.dart';

/// Per-notification content widget rendered inside the stack window.
///
/// The outer surface (radius, shadow, border) is owned by the stack
/// window via [SteamNotificationConfig.stackDecorationBuilder], so this
/// widget renders only the notification's inner content plus a subtle
/// hover scale and click-to-fire-onTap.
class NotificationContainer extends StatefulWidget {
  const NotificationContainer({
    required this.notification,
    required this.config,
    required this.onDismiss,
    this.customBuilder,
    super.key,
  });

  final SteamNotification notification;
  final SteamNotificationConfig config;
  final VoidCallback onDismiss;
  final Widget Function(
    BuildContext context,
    SteamNotification notification,
    VoidCallback onDismiss,
  )?
  customBuilder;

  @override
  State<NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer> {
  bool _isHovered = false;

  void _handleTap() {
    widget.notification.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.transparent,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final customBuilder = widget.customBuilder;
    if (customBuilder != null) {
      return customBuilder(context, widget.notification, widget.onDismiss);
    }
    return switch (widget.notification) {
      AchievementNotification() => AchievementView(
        notification: widget.notification as AchievementNotification,
        onClose: widget.onDismiss,
      ),
      MessageNotification() => MessageView(
        notification: widget.notification as MessageNotification,
        onClose: widget.onDismiss,
      ),
      CustomNotification() => CustomView(
        notification: widget.notification as CustomNotification,
        onClose: widget.onDismiss,
      ),
    };
  }
}
