import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../theme/steam_colors.dart';
import 'widgets/close_button.dart';
import 'widgets/notification_icon.dart';

/// Message notification view
///
/// Displays a Steam-style message notification with:
/// - Avatar on the left
/// - Sender name (optional)
/// - Message content
/// - Close button
class MessageView extends StatelessWidget {
  /// Creates a message view
  const MessageView({
    required this.notification,
    required this.onClose,
    super.key,
  });

  /// The message notification data
  final MessageNotification notification;

  /// Callback to close the notification
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          NotificationAvatar(
            avatar: notification.avatar,
            avatarUrl: notification.avatarUrl,
            size: 40,
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sender name
                if (notification.senderName != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.senderName!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: SteamColors.accentBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Online indicator dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SteamColors.accentGreen,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  SteamColors.accentGreen.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Message
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium,
                  maxLines: notification.senderName != null ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Close button
          NotificationCloseButton(
            onPressed: onClose,
            size: 20,
          ),
        ],
      ),
    );
  }
}
