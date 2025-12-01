import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Base class for all Steam notifications using sealed class pattern
sealed class SteamNotification {
  /// Creates a notification with the specified parameters
  SteamNotification({
    String? id,
    this.duration,
    this.onTap,
    this.onDismiss,
  }) : id = id ?? _uuid.v4();

  /// Unique identifier for this notification
  final String id;

  /// Custom duration for this notification (overrides config default)
  final Duration? duration;

  /// Callback when the notification is tapped
  final VoidCallback? onTap;

  /// Callback when the notification is dismissed
  final VoidCallback? onDismiss;
}

/// Achievement-style notification with icon, title, description and optional progress
class AchievementNotification extends SteamNotification {
  /// Creates an achievement notification
  AchievementNotification({
    required this.title,
    required this.description,
    this.icon,
    this.iconUrl,
    this.progress,
    this.showUnlockedHeader = true,
    super.id,
    super.duration,
    super.onTap,
    super.onDismiss,
  });

  /// Title of the achievement
  final String title;

  /// Description of the achievement
  final String description;

  /// Custom icon widget (takes precedence over iconUrl)
  final Widget? icon;

  /// URL or asset path for the icon
  final String? iconUrl;

  /// Progress value from 0.0 to 1.0 (null for no progress bar)
  final double? progress;

  /// Whether to show the "ACHIEVEMENT UNLOCKED" header
  final bool showUnlockedHeader;
}

/// Message-style notification with optional avatar and sender name
class MessageNotification extends SteamNotification {
  /// Creates a message notification
  MessageNotification({
    required this.message,
    this.senderName,
    this.avatar,
    this.avatarUrl,
    super.id,
    super.duration,
    super.onTap,
    super.onDismiss,
  });

  /// The message content
  final String message;

  /// Name of the sender (displayed as header)
  final String? senderName;

  /// Custom avatar widget (takes precedence over avatarUrl)
  final Widget? avatar;

  /// URL or asset path for the avatar
  final String? avatarUrl;
}

/// Custom notification with arbitrary widget content
class CustomNotification extends SteamNotification {
  /// Creates a custom notification with the given widget
  CustomNotification({
    required this.child,
    this.width,
    this.height,
    this.showCloseButton = true,
    this.backgroundColor,
    super.id,
    super.duration,
    super.onTap,
    super.onDismiss,
  });

  /// The custom widget to display
  final Widget child;

  /// Custom width (overrides config default)
  final double? width;

  /// Custom height (overrides config default)
  final double? height;

  /// Whether to show the close button
  final bool showCloseButton;

  /// Custom background color
  final Color? backgroundColor;
}
