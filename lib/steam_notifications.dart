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
import 'src/core/steam_notification_service.dart';
import 'src/models/notification.dart';
import 'src/presentation/stack_view.dart';
import 'src/windows/notification_window.dart';

// Export Flutter's internal window APIs for multi-window support
export 'package:flutter/src/widgets/_window.dart';

// Export public API
export 'src/config/notification_config.dart';
export 'src/config/notification_position.dart';
export 'src/core/notification_manager.dart'
    show NotificationManager, NotificationBuilder;
export 'src/core/steam_notification_service.dart'
    show SteamNotificationService, ActiveNotificationEntry;
export 'src/core/work_area.dart' show WorkAreaRect, WorkAreaResolver;
export 'src/models/notification.dart';
export 'src/theme/steam_colors.dart';
export 'src/theme/steam_theme.dart';

/// Main entry point for the Steam notification system
///
/// Use this class to initialize the notification system and show notifications.
///
/// ## Integration options
///
/// Place notifications at the root of the app so they persist across
/// main-window teardown (e.g. when the app minimises to a system tray):
///
/// ```dart
/// ListenableBuilder(
///   listenable: SteamNotificationService.instance,
///   builder: (context, _) => ViewCollection(
///     views: [
///       if (mainController != null)
///         RegularWindow(controller: mainController, child: MyApp()),
///       ...SteamNotifications.buildNotificationViews(),
///     ],
///   ),
/// );
/// ```
///
/// Or wrap your app with [NotificationManager] (notifications disappear
/// when the host widget tree unmounts):
///
/// ```dart
/// NotificationManager(
///   child: MaterialApp(...),
/// );
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

  /// Global key for the (optional) [NotificationManager] widget.
  ///
  /// Kept for backwards compatibility. Notification state now lives in
  /// [SteamNotificationService] and does not require a manager widget
  /// to be mounted.
  static GlobalKey<NotificationManagerState> get managerKey => _managerKey;

  static SteamNotificationService get _service =>
      SteamNotificationService.instance;

  /// Exposes the singleton service as a [Listenable] so host apps can
  /// drive rebuilds (e.g. inside a [ListenableBuilder]) without having
  /// to import [SteamNotificationService] directly.
  static Listenable get listenable => SteamNotificationService.instance;

  /// Whether the notification system is ready to accept notifications.
  ///
  /// Always `true` now that state lives in a singleton service; kept for
  /// backwards compatibility with callers that gate on it.
  static bool get isInitialized => true;

  /// Initialize the notification system.
  ///
  /// Optionally provide a custom [config] for notification behavior.
  static Future<void> initialize({SteamNotificationConfig? config}) async {
    if (config != null) {
      _service.configure(config);
    }
  }

  /// Show any type of notification.
  static Future<void> show(SteamNotification notification) =>
      _service.show(notification);

  /// Show an achievement notification.
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

  /// Show a message notification.
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

  /// Show a custom notification with any widget content.
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

  /// Update the notification configuration.
  static void configure(SteamNotificationConfig config) =>
      _service.configure(config);

  /// Dismiss a specific notification by ID.
  static void dismiss(String id) => _service.dismiss(id);

  /// Dismiss all visible and queued notifications.
  static void dismissAll() => _service.dismissAll();

  /// Number of currently visible notifications.
  static int get activeCount => _service.activeCount;

  /// Builds the stack window, suitable for placement at the root level
  /// inside a [ViewCollection].
  ///
  /// Returns a single-element list containing the shared stack window
  /// when any notification is active, or an empty list otherwise. Wrap
  /// the [ViewCollection] builder in a [ListenableBuilder] listening to
  /// [SteamNotifications.listenable] so the list rebuilds whenever
  /// notifications appear or dismiss.
  ///
  /// This integration keeps the stack alive across host-window
  /// lifecycle transitions (e.g. minimising the app to a system tray).
  static List<Widget> buildNotificationViews() {
    final controller = _service.stackController;
    final entries = _service.activeNotifications;
    if (controller == null || entries.isEmpty) return const [];
    return [
      NotificationWindow(
        key: const ValueKey('steam-notification-stack'),
        controller: controller,
        child: StackView(
          entries: entries,
          config: _service.config,
          notificationBuilder: _service.notificationBuilder,
          onDismiss: _service.dismiss,
        ),
      ),
    ];
  }
}
