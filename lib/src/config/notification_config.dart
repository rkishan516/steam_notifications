import 'package:flutter/material.dart';

import '../core/work_area.dart';
import 'notification_position.dart';

/// Context passed to [StackBackgroundBuilder] describing the notification
/// stack layout.
///
/// The builder renders a widget that spans the full [capacity] × slot
/// area. The visible portion is whatever intersects the currently
/// resized window. This lets a host paint a single logo/artwork across
/// the whole stack so a partial stack shows a partial image.
class StackBackgroundContext {
  const StackBackgroundContext({
    required this.activeCount,
    required this.capacity,
    required this.slotSize,
  });

  /// Number of currently visible notifications (1..capacity).
  final int activeCount;

  /// Maximum number of visible notifications at once.
  final int capacity;

  /// Logical size of a single notification slot.
  final Size slotSize;

  /// Total logical size the background widget is laid out in
  /// (width = slot width, height = capacity × slot height).
  Size get fullStackSize =>
      Size(slotSize.width, slotSize.height * capacity);
}

/// Builds the background widget drawn behind the notification stack.
///
/// Return `null` to skip rendering a background for the current
/// [StackBackgroundContext].
typedef StackBackgroundBuilder =
    Widget? Function(BuildContext context, StackBackgroundContext info);

/// Builds the outer decoration of the notification stack window
/// (radius, border, shadow, surface color).
typedef StackDecorationBuilder =
    BoxDecoration Function(BuildContext context, int activeCount);

/// Configuration for the Steam notification system
class SteamNotificationConfig {
  /// Creates a notification configuration with the specified options
  const SteamNotificationConfig({
    this.position = NotificationPosition.bottomRight,
    this.defaultDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.stackCapacity = 3,
    this.margin = const EdgeInsets.all(16),
    this.defaultWidth = 340.0,
    this.achievementHeight = 100.0,
    this.messageHeight = 80.0,
    this.playSound = false,
    this.soundAssetPath,
    this.themeData,
    this.stackDecorationBuilder,
    this.stackBorderInsets = const EdgeInsets.all(1),
    this.stackBackgroundBuilder,
    this.workAreaResolver,
  });

  /// Position on screen where the notification stack appears.
  final NotificationPosition position;

  /// Default duration before auto-dismiss (can be overridden per notification).
  final Duration defaultDuration;

  /// Duration of slide-in/slide-out animations.
  final Duration animationDuration;

  /// Animation curve for enter/exit transitions.
  final Curve animationCurve;

  /// Maximum number of notifications visible at once. When exceeded, the
  /// oldest notification is dropped and the stack shifts up.
  final int stackCapacity;

  /// Margin from work-area edges.
  final EdgeInsets margin;

  /// Width of the notification stack window.
  final double defaultWidth;

  /// Height of achievement notifications (one slot).
  final double achievementHeight;

  /// Height of message notifications (one slot). All slots share the
  /// same height for flush stacking.
  final double messageHeight;

  /// Whether to play a sound when showing notifications.
  final bool playSound;

  /// Path to custom sound asset (uses system sound if null).
  final String? soundAssetPath;

  /// Optional theme applied to the notification window. When `null` the
  /// built-in Steam theme is used.
  final ThemeData? themeData;

  /// Optional decoration applied to the stack window (radius, border,
  /// shadow). When `null` the built-in Steam decoration is used.
  final StackDecorationBuilder? stackDecorationBuilder;

  /// Border insets of the stack decoration. The window is grown by these
  /// insets so the notification content keeps a slot-aligned size and
  /// does not overflow under the decoration border. Must match the
  /// border widths used in [stackDecorationBuilder].
  final EdgeInsets stackBorderInsets;

  /// Optional background builder. Receives stack layout metadata and
  /// must return a widget laid out across the full stack capacity area
  /// so a partial stack naturally shows a partial artwork.
  final StackBackgroundBuilder? stackBackgroundBuilder;

  /// Resolver used to compute the usable screen rect. Defaults to a
  /// platform-native resolver that excludes the Windows taskbar.
  final WorkAreaResolver? workAreaResolver;

  /// Creates a copy with the specified fields replaced
  SteamNotificationConfig copyWith({
    NotificationPosition? position,
    Duration? defaultDuration,
    Duration? animationDuration,
    Curve? animationCurve,
    int? stackCapacity,
    EdgeInsets? margin,
    double? defaultWidth,
    double? achievementHeight,
    double? messageHeight,
    bool? playSound,
    String? soundAssetPath,
    ThemeData? themeData,
    StackDecorationBuilder? stackDecorationBuilder,
    EdgeInsets? stackBorderInsets,
    StackBackgroundBuilder? stackBackgroundBuilder,
    WorkAreaResolver? workAreaResolver,
  }) {
    return SteamNotificationConfig(
      position: position ?? this.position,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      stackCapacity: stackCapacity ?? this.stackCapacity,
      margin: margin ?? this.margin,
      defaultWidth: defaultWidth ?? this.defaultWidth,
      achievementHeight: achievementHeight ?? this.achievementHeight,
      messageHeight: messageHeight ?? this.messageHeight,
      playSound: playSound ?? this.playSound,
      soundAssetPath: soundAssetPath ?? this.soundAssetPath,
      themeData: themeData ?? this.themeData,
      stackDecorationBuilder:
          stackDecorationBuilder ?? this.stackDecorationBuilder,
      stackBorderInsets: stackBorderInsets ?? this.stackBorderInsets,
      stackBackgroundBuilder:
          stackBackgroundBuilder ?? this.stackBackgroundBuilder,
      workAreaResolver: workAreaResolver ?? this.workAreaResolver,
    );
  }
}
