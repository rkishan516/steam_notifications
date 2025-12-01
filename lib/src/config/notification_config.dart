import 'package:flutter/widgets.dart';

import 'notification_position.dart';

/// Configuration for the Steam notification system
class SteamNotificationConfig {
  /// Creates a notification configuration with the specified options
  const SteamNotificationConfig({
    this.position = NotificationPosition.bottomRight,
    this.defaultDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.maxVisibleNotifications = 5,
    this.margin = const EdgeInsets.all(16),
    this.spacing = 12.0,
    this.defaultWidth = 340.0,
    this.achievementHeight = 100.0,
    this.messageHeight = 80.0,
    this.playSound = false,
    this.soundAssetPath,
  });

  /// Position on screen where notifications appear
  final NotificationPosition position;

  /// Default duration before auto-dismiss (can be overridden per notification)
  final Duration defaultDuration;

  /// Duration of slide-in/slide-out animations
  final Duration animationDuration;

  /// Animation curve for enter/exit transitions
  final Curve animationCurve;

  /// Maximum number of notifications visible at once
  /// Additional notifications are queued
  final int maxVisibleNotifications;

  /// Margin from screen edges
  final EdgeInsets margin;

  /// Vertical spacing between stacked notifications
  final double spacing;

  /// Default width for notification windows
  final double defaultWidth;

  /// Default height for achievement notifications
  final double achievementHeight;

  /// Default height for message notifications
  final double messageHeight;

  /// Whether to play a sound when showing notifications
  final bool playSound;

  /// Path to custom sound asset (uses system sound if null)
  final String? soundAssetPath;

  /// Creates a copy with the specified fields replaced
  SteamNotificationConfig copyWith({
    NotificationPosition? position,
    Duration? defaultDuration,
    Duration? animationDuration,
    Curve? animationCurve,
    int? maxVisibleNotifications,
    EdgeInsets? margin,
    double? spacing,
    double? defaultWidth,
    double? achievementHeight,
    double? messageHeight,
    bool? playSound,
    String? soundAssetPath,
  }) {
    return SteamNotificationConfig(
      position: position ?? this.position,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      maxVisibleNotifications:
          maxVisibleNotifications ?? this.maxVisibleNotifications,
      margin: margin ?? this.margin,
      spacing: spacing ?? this.spacing,
      defaultWidth: defaultWidth ?? this.defaultWidth,
      achievementHeight: achievementHeight ?? this.achievementHeight,
      messageHeight: messageHeight ?? this.messageHeight,
      playSound: playSound ?? this.playSound,
      soundAssetPath: soundAssetPath ?? this.soundAssetPath,
    );
  }
}
