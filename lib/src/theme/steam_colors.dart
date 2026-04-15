import 'package:flutter/painting.dart';

/// Steam-inspired color palette for notifications.
///
/// Surface colors are aligned with a neutral FUSE-style gray scale so
/// notifications sit cleanly on any desktop background. Accent colors
/// preserve Steam's identity (green for achievements, blue for messages,
/// gold for premium highlights).
class SteamColors {
  const SteamColors._();

  // Background colors (neutral gray scale)
  /// Primary surface color for notification bodies (gray80).
  static const Color backgroundPrimary = Color(0xFF1D1D1D);

  /// Deeper background used behind progress tracks and chips (gray90).
  static const Color backgroundSecondary = Color(0xFF121212);

  /// Slightly lighter surface for icon wells and inset elements (gray70).
  static const Color backgroundTertiary = Color(0xFF242424);

  /// Alias for [backgroundPrimary] — the default notification surface.
  static const Color surface = backgroundPrimary;

  // Accent colors
  /// Green accent for achievements and success states.
  static const Color accentGreen = Color(0xFF32D35A);

  /// Lighter green for highlights and icon glow.
  static const Color accentGreenLight = Color(0xFF47E36E);

  /// Blue accent for messages and info.
  static const Color accentBlue = Color(0xFF00AAFF);

  /// Lighter blue for highlights.
  static const Color accentBlueLight = Color(0xFF20B9FF);

  /// Gold accent for premium/special notifications.
  static const Color accentGold = Color(0xFFD9A441);

  /// Orange accent for warnings and calls-to-action.
  static const Color accentOrange = Color(0xFFFF5500);

  // Text colors
  /// Primary text color for titles (gray0).
  static const Color textPrimary = Color(0xFFF1F1F1);

  /// Secondary text color for body copy (gray10).
  static const Color textSecondary = Color(0xFFCCCCCC);

  /// Muted text color for metadata (gray20).
  static const Color textMuted = Color(0xFFA7A7A7);

  /// Disabled text color (gray40).
  static const Color textDisabled = Color(0xFF5D5D5D);

  // Border and divider colors
  /// Default border color (gray60).
  static const Color border = Color(0xFF2E2E2E);

  /// Highlighted border color used on hover (gray50).
  static const Color borderHighlight = Color(0xFF383838);

  /// Divider color (gray70).
  static const Color divider = Color(0xFF242424);

  // Shadow colors
  /// Shadow color for drop shadows.
  static const Color shadow = Color(0x66000000);

  /// Stronger shadow color for ambient depth.
  static const Color shadowStrong = Color(0x99000000);

  // Glow colors (with alpha)
  /// Green glow for achievements.
  static Color glowGreen = const Color(0xFF32D35A).withValues(alpha: 0.4);

  /// Blue glow for messages.
  static Color glowBlue = const Color(0xFF00AAFF).withValues(alpha: 0.4);

  /// Gold glow for special items.
  static Color glowGold = const Color(0xFFD9A441).withValues(alpha: 0.4);
}

/// Gradients used in Steam-style notifications.
///
/// Surfaces use a subtle top-to-bottom gray gradient for light elevation
/// without the busy color banding of the old Steam blue palette. Accent
/// gradients (e.g. progress bars) keep the Steam identity.
class SteamGradients {
  const SteamGradients._();

  /// Default notification surface gradient (gray70 → gray90).
  static const LinearGradient defaultBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF242424),
      Color(0xFF121212),
    ],
  );

  /// Background gradient for achievement notifications.
  static const LinearGradient achievementBackground = defaultBackground;

  /// Background gradient for message notifications.
  static const LinearGradient messageBackground = defaultBackground;

  /// Progress bar gradient.
  static const LinearGradient progressBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF23BF4A),
      Color(0xFF47E36E),
    ],
  );
}
