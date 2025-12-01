import 'package:flutter/material.dart';

import '../models/notification.dart';
import 'widgets/close_button.dart';

/// Custom notification view
///
/// Displays a custom widget provided by the user with:
/// - Custom content
/// - Optional close button
class CustomView extends StatelessWidget {
  /// Creates a custom view
  const CustomView({
    required this.notification,
    required this.onClose,
    super.key,
  });

  /// The custom notification data
  final CustomNotification notification;

  /// Callback to close the notification
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!notification.showCloseButton) {
      return notification.child;
    }

    return Stack(
      children: [
        // Custom content
        Positioned.fill(
          child: notification.child,
        ),

        // Close button overlay
        Positioned(
          top: 8,
          right: 8,
          child: NotificationCloseButton(
            onPressed: onClose,
            size: 20,
          ),
        ),
      ],
    );
  }
}
