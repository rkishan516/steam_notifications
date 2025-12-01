import 'package:flutter/material.dart';

import 'steam_colors.dart';

/// Creates a ThemeData configured for Steam-style notifications
ThemeData steamNotificationTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: SteamColors.accentGreen,
      secondary: SteamColors.accentBlue,
      surface: SteamColors.surface,
      error: SteamColors.accentOrange,
    ),
    textTheme: const TextTheme(
      // Achievement title
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SteamColors.textPrimary,
        height: 1.3,
      ),
      // Achievement description / message text
      bodyMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SteamColors.textSecondary,
        height: 1.4,
      ),
      // "ACHIEVEMENT UNLOCKED" header
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: SteamColors.accentGreen,
        letterSpacing: 1.2,
        height: 1.2,
      ),
      // Sender name in messages
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SteamColors.textPrimary,
        height: 1.3,
      ),
    ),
    iconTheme: const IconThemeData(
      color: SteamColors.textPrimary,
      size: 20,
    ),
  );
}

/// Box decoration for notification containers
BoxDecoration steamNotificationDecoration({
  Gradient? gradient,
  Color? backgroundColor,
  double borderRadius = 8.0,
  bool showBorder = true,
  bool showShadow = true,
}) {
  return BoxDecoration(
    gradient: gradient ?? SteamGradients.defaultBackground,
    color: gradient == null ? backgroundColor : null,
    borderRadius: BorderRadius.circular(borderRadius),
    border: showBorder
        ? Border.all(
            color: SteamColors.border,
            width: 1,
          )
        : null,
    boxShadow: showShadow
        ? const [
            BoxShadow(
              color: SteamColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: SteamColors.shadowStrong,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ]
        : null,
  );
}

/// Icon glow decoration for achievement icons
BoxDecoration steamIconGlowDecoration({
  Color glowColor = const Color(0xFF5BB32F),
  double glowRadius = 8.0,
}) {
  return BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: glowColor.withValues(alpha: 0.4),
        blurRadius: glowRadius,
        spreadRadius: 2,
      ),
    ],
  );
}
