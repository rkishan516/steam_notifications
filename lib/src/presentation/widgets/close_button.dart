import 'package:flutter/material.dart';

import '../../theme/steam_colors.dart';

/// Close button widget for notifications
class NotificationCloseButton extends StatefulWidget {
  /// Creates a close button
  const NotificationCloseButton({
    required this.onPressed,
    this.size = 20.0,
    super.key,
  });

  /// Callback when the button is pressed
  final VoidCallback onPressed;

  /// Size of the button
  final double size;

  @override
  State<NotificationCloseButton> createState() =>
      _NotificationCloseButtonState();
}

class _NotificationCloseButtonState extends State<NotificationCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered
                ? SteamColors.textMuted.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.close,
            size: widget.size * 0.7,
            color: _isHovered
                ? SteamColors.textPrimary
                : SteamColors.textMuted,
          ),
        ),
      ),
    );
  }
}
