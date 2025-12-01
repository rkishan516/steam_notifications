import 'package:flutter/material.dart';

import '../../theme/steam_colors.dart';

/// Icon widget for notifications with optional glow effect
class NotificationIcon extends StatelessWidget {
  /// Creates a notification icon
  const NotificationIcon({
    this.icon,
    this.iconUrl,
    this.size = 48.0,
    this.glowColor,
    this.showGlow = true,
    this.borderRadius = 8.0,
    super.key,
  });

  /// Custom icon widget (takes precedence over iconUrl)
  final Widget? icon;

  /// URL or asset path for the icon
  final String? iconUrl;

  /// Size of the icon container
  final double size;

  /// Color for the glow effect
  final Color? glowColor;

  /// Whether to show the glow effect
  final bool showGlow;

  /// Border radius of the icon container
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (icon != null) {
      iconWidget = icon!;
    } else if (iconUrl != null && iconUrl!.isNotEmpty) {
      iconWidget = _buildImageIcon();
    } else {
      iconWidget = _buildDefaultIcon();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: SteamColors.backgroundTertiary,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? SteamColors.accentGreen).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: iconWidget,
      ),
    );
  }

  Widget _buildImageIcon() {
    final url = iconUrl!;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultIcon(),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: SteamColors.backgroundTertiary,
      child: Icon(
        Icons.emoji_events,
        size: size * 0.5,
        color: glowColor ?? SteamColors.accentGreen,
      ),
    );
  }
}

/// Avatar widget for message notifications
class NotificationAvatar extends StatelessWidget {
  /// Creates a notification avatar
  const NotificationAvatar({
    this.avatar,
    this.avatarUrl,
    this.size = 40.0,
    super.key,
  });

  /// Custom avatar widget
  final Widget? avatar;

  /// URL or asset path for the avatar
  final String? avatarUrl;

  /// Size of the avatar
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatar != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(child: avatar!),
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return _buildImageAvatar();
    }

    return _buildDefaultAvatar();
  }

  Widget _buildImageAvatar() {
    final url = avatarUrl!;

    Widget image;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarContent(),
      );
    } else {
      image = Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarContent(),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: image),
    );
  }

  Widget _buildDefaultAvatar() {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: _buildDefaultAvatarContent()),
    );
  }

  Widget _buildDefaultAvatarContent() {
    return Container(
      color: SteamColors.backgroundTertiary,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: SteamColors.accentBlue,
      ),
    );
  }
}
