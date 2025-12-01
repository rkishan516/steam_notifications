import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../theme/steam_colors.dart';
import 'widgets/close_button.dart';
import 'widgets/notification_icon.dart';
import 'widgets/progress_bar.dart';

/// Achievement notification view
///
/// Displays a Steam-style achievement notification with:
/// - Icon on the left with glow effect
/// - "ACHIEVEMENT UNLOCKED" header
/// - Title and description
/// - Optional progress bar
/// - Close button
class AchievementView extends StatelessWidget {
  /// Creates an achievement view
  const AchievementView({
    required this.notification,
    required this.onClose,
    super.key,
  });

  /// The achievement notification data
  final AchievementNotification notification;

  /// Callback to close the notification
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with glow
                NotificationIcon(
                  icon: notification.icon,
                  iconUrl: notification.iconUrl,
                  size: 56,
                  glowColor: SteamColors.accentGreen,
                  showGlow: true,
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      if (notification.showUnlockedHeader) ...[
                        Text(
                          'ACHIEVEMENT UNLOCKED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: SteamColors.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Title
                      Text(
                        notification.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Description
                      Text(
                        notification.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
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
          ),

          // Progress bar
          if (notification.progress != null) ...[
            const SizedBox(height: 8),
            NotificationProgressBar(
              progress: notification.progress!,
              height: 4,
            ),
          ],
        ],
      ),
    );
  }
}
