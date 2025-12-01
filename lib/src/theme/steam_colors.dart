import 'package:flutter/painting.dart';

/// Steam-inspired color palette for notifications
class SteamColors {
  const SteamColors._();

  // Background colors (Steam dark theme)
  /// Primary background color
  static const Color backgroundPrimary = Color(0xFF1B2838);

  /// Secondary/darker background color
  static const Color backgroundSecondary = Color(0xFF171A21);

  /// Tertiary/lighter background for contrast
  static const Color backgroundTertiary = Color(0xFF2A475E);

  /// Surface color for cards and elevated elements
  static const Color surface = Color(0xFF1E2A38);

  // Accent colors
  /// Green accent for achievements and success states
  static const Color accentGreen = Color(0xFF5BB32F);

  /// Lighter green for highlights
  static const Color accentGreenLight = Color(0xFF8BC34A);

  /// Blue accent for messages and info
  static const Color accentBlue = Color(0xFF66C0F4);

  /// Lighter blue for highlights
  static const Color accentBlueLight = Color(0xFF90CAF9);

  /// Gold accent for premium/special notifications
  static const Color accentGold = Color(0xFFD4AF37);

  /// Orange accent for warnings
  static const Color accentOrange = Color(0xFFCF6A32);

  // Text colors
  /// Primary text color (white)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text color (light gray)
  static const Color textSecondary = Color(0xFFC7D5E0);

  /// Muted text color (gray)
  static const Color textMuted = Color(0xFF8F98A0);

  /// Disabled text color
  static const Color textDisabled = Color(0xFF5A6570);

  // Border and divider colors
  /// Default border color
  static const Color border = Color(0xFF3D4450);

  /// Highlighted border color
  static const Color borderHighlight = Color(0xFF4D5A6A);

  /// Divider color
  static const Color divider = Color(0xFF2A3441);

  // Shadow colors
  /// Shadow color for drop shadows
  static const Color shadow = Color(0x40000000);

  /// Stronger shadow color
  static const Color shadowStrong = Color(0x80000000);

  // Glow colors (with alpha)
  /// Green glow for achievements
  static Color glowGreen = const Color(0xFF5BB32F).withValues(alpha: 0.4);

  /// Blue glow for messages
  static Color glowBlue = const Color(0xFF66C0F4).withValues(alpha: 0.4);

  /// Gold glow for special items
  static Color glowGold = const Color(0xFFD4AF37).withValues(alpha: 0.4);
}

/// Gradients used in Steam-style notifications
class SteamGradients {
  const SteamGradients._();

  /// Background gradient for achievement notifications
  static const LinearGradient achievementBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B2838),
      Color(0xFF1E3A2F),
    ],
  );

  /// Background gradient for message notifications
  static const LinearGradient messageBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B2838),
      Color(0xFF1E2A3A),
    ],
  );

  /// Default notification background gradient
  static const LinearGradient defaultBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF232F3E),
      Color(0xFF1B2838),
    ],
  );

  /// Progress bar gradient
  static const LinearGradient progressBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF5BB32F),
      Color(0xFF8BC34A),
    ],
  );
}
