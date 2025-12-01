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
import 'src/core/notification_manager.dart';
import 'src/models/notification.dart';

// Export Flutter's internal window APIs for multi-window support
export 'package:flutter/src/widgets/_window.dart';

// Export public API
export 'src/config/notification_config.dart';
export 'src/config/notification_position.dart';
export 'src/core/notification_manager.dart'
    show NotificationManager, NotificationBuilder;
export 'src/models/notification.dart';
export 'src/theme/steam_colors.dart';
export 'src/theme/steam_theme.dart';

/// Main entry point for the Steam notification system
///
/// Use this class to initialize the notification system and show notifications.
///
/// ## Usage
///
/// Wrap your main window widget with [NotificationManager]:
///
/// ```dart
/// void main() {
///   runWidget(
///     RegularWindow(
///       controller: RegularWindowController(...),
///       child: NotificationManager(
///         child: MaterialApp(...),
///       ),
///     ),
///   );
/// }
/// ```
///
/// Then show notifications:
/// ```dart
/// SteamNotifications.showAchievement(
///   title: 'Achievement Unlocked!',
///   description: 'You completed the tutorial',
/// );
/// ```
class SteamNotifications {
  SteamNotifications._();

  static final GlobalKey<NotificationManagerState> _managerKey =
      GlobalKey<NotificationManagerState>();

  /// Global key for the NotificationManager widget
  ///
  /// Use this when creating the NotificationManager:
  /// ```dart
  /// NotificationManager(
  ///   key: SteamNotifications.managerKey,
  ///   child: YourApp(),
  /// )
  /// ```
  static GlobalKey<NotificationManagerState> get managerKey => _managerKey;

  /// Whether the notification system has been initialized
  static bool get isInitialized => _managerKey.currentState != null;

  /// Initialize the notification system
  ///
  /// Optionally provide a custom [config] for notification behavior.
  /// Note: The [NotificationManager] widget must be in the widget tree
  /// for notifications to work.
  static Future<void> initialize({SteamNotificationConfig? config}) async {
    if (config != null && _managerKey.currentState != null) {
      _managerKey.currentState!.configure(config);
    }
  }

  /// Show any type of notification
  ///
  /// For convenience, use [showAchievement], [showMessage], or [showCustom]
  /// instead.
  static Future<void> show(SteamNotification notification) async {
    _ensureInitialized();
    await _managerKey.currentState!.show(notification);
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
    _managerKey.currentState!.configure(config);
  }

  /// Dismiss a specific notification by ID
  static void dismiss(String id) {
    _ensureInitialized();
    _managerKey.currentState!.dismiss(id);
  }

  /// Dismiss all visible and queued notifications
  static void dismissAll() {
    _ensureInitialized();
    _managerKey.currentState!.dismissAll();
  }

  /// Get the number of currently visible notifications
  static int get activeCount {
    _ensureInitialized();
    return _managerKey.currentState!.activeCount;
  }

  /// Get the number of queued notifications
  static int get queuedCount {
    _ensureInitialized();
    return _managerKey.currentState!.queuedCount;
  }

  static void _ensureInitialized() {
    assert(
      _managerKey.currentState != null,
      'SteamNotifications: NotificationManager widget not found in widget tree. '
      'Wrap your app with NotificationManager(key: SteamNotifications.managerKey, child: YourApp()).',
    );
  }
}
