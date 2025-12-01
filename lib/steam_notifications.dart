// ignore_for_file: invalid_export_of_internal_element

/// Steam-inspired desktop notifications for Flutter
///
/// This package provides Steam-style notification windows for Flutter desktop
/// applications using Flutter's multi-window APIs.
///
/// ## Usage
///
/// ```dart
/// import 'package:steam_notifications/steam_notifications.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await SteamNotifications.initialize();
///
///   runApp(MyApp());
/// }
///
/// // Show an achievement notification
/// SteamNotifications.showAchievement(
///   title: 'First Blood',
///   description: 'Get your first elimination',
///   progress: 1.0,
/// );
/// ```
library;

import 'package:flutter/widgets.dart';

import 'src/config/notification_config.dart';
import 'src/core/notification_controller.dart';
import 'src/models/notification.dart';

// Export Flutter's internal window APIs for multi-window support
export 'package:flutter/src/widgets/_window.dart';

// Export public API
export 'src/config/notification_config.dart';
export 'src/config/notification_position.dart';
export 'src/models/notification.dart';
export 'src/theme/steam_colors.dart';
export 'src/theme/steam_theme.dart';

/// Main entry point for the Steam notification system
///
/// Use this class to initialize the notification system and show notifications.
///
/// Example:
/// ```dart
/// await SteamNotifications.initialize();
/// SteamNotifications.showAchievement(
///   title: 'Achievement Unlocked!',
///   description: 'You completed the tutorial',
/// );
/// ```
class SteamNotifications {
  SteamNotifications._();

  static NotificationController? _controller;

  /// Whether the notification system has been initialized
  static bool get isInitialized => _controller != null;

  /// Initialize the notification system
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized].
  /// Optionally provide a custom [config] for notification behavior.
  static Future<void> initialize({SteamNotificationConfig? config}) async {
    if (_controller != null) {
      return;
    }

    _controller = NotificationController(
      config ?? const SteamNotificationConfig(),
    );
  }

  /// Show any type of notification
  ///
  /// For convenience, use [showAchievement], [showMessage], or [showCustom]
  /// instead.
  static Future<void> show(SteamNotification notification) async {
    _ensureInitialized();
    await _controller!.show(notification);
  }

  /// Show an achievement notification
  ///
  /// [title] - The achievement title
  /// [description] - The achievement description
  /// [icon] - Custom icon widget (optional)
  /// [iconUrl] - URL or asset path for the icon (optional)
  /// [progress] - Progress value from 0.0 to 1.0 (optional)
  /// [showUnlockedHeader] - Whether to show "ACHIEVEMENT UNLOCKED" header
  /// [duration] - Custom duration before auto-dismiss (optional)
  /// [onTap] - Callback when notification is tapped (optional)
  /// [onDismiss] - Callback when notification is dismissed (optional)
  static Future<void> showAchievement({
    required String title,
    required String description,
    Widget? icon,
    String? iconUrl,
    double? progress,
    bool showUnlockedHeader = true,
    Duration? duration,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return show(
      AchievementNotification(
        title: title,
        description: description,
        icon: icon,
        iconUrl: iconUrl,
        progress: progress,
        showUnlockedHeader: showUnlockedHeader,
        duration: duration,
        onTap: onTap,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Show a message notification
  ///
  /// [message] - The message content
  /// [senderName] - Name of the sender (optional)
  /// [avatar] - Custom avatar widget (optional)
  /// [avatarUrl] - URL or asset path for the avatar (optional)
  /// [duration] - Custom duration before auto-dismiss (optional)
  /// [onTap] - Callback when notification is tapped (optional)
  /// [onDismiss] - Callback when notification is dismissed (optional)
  static Future<void> showMessage({
    required String message,
    String? senderName,
    Widget? avatar,
    String? avatarUrl,
    Duration? duration,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return show(
      MessageNotification(
        message: message,
        senderName: senderName,
        avatar: avatar,
        avatarUrl: avatarUrl,
        duration: duration,
        onTap: onTap,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Show a custom notification with any widget content
  ///
  /// [child] - The custom widget to display
  /// [width] - Custom width (optional)
  /// [height] - Custom height (optional)
  /// [showCloseButton] - Whether to show the close button
  /// [backgroundColor] - Custom background color (optional)
  /// [duration] - Custom duration before auto-dismiss (optional)
  /// [onTap] - Callback when notification is tapped (optional)
  /// [onDismiss] - Callback when notification is dismissed (optional)
  static Future<void> showCustom({
    required Widget child,
    double? width,
    double? height,
    bool showCloseButton = true,
    Color? backgroundColor,
    Duration? duration,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return show(
      CustomNotification(
        child: child,
        width: width,
        height: height,
        showCloseButton: showCloseButton,
        backgroundColor: backgroundColor,
        duration: duration,
        onTap: onTap,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Update the notification configuration
  ///
  /// Changes will apply to future notifications.
  static void configure(SteamNotificationConfig config) {
    _ensureInitialized();
    _controller!.configure(config);
  }

  /// Dismiss a specific notification by ID
  static void dismiss(String id) {
    _ensureInitialized();
    _controller!.dismiss(id);
  }

  /// Dismiss all visible and queued notifications
  static void dismissAll() {
    _ensureInitialized();
    _controller!.dismissAll();
  }

  /// Get the number of currently visible notifications
  static int get activeCount {
    _ensureInitialized();
    return _controller!.activeCount;
  }

  /// Get the number of queued notifications
  static int get queuedCount {
    _ensureInitialized();
    return _controller!.queuedCount;
  }

  static void _ensureInitialized() {
    assert(
      _controller != null,
      'SteamNotifications has not been initialized. '
      'Call SteamNotifications.initialize() first.',
    );
  }
}
