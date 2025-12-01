import 'package:flutter/material.dart';

import '../config/notification_config.dart';
import '../core/position_calculator.dart';
import '../models/notification.dart';
import '../theme/steam_colors.dart';
import '../theme/steam_theme.dart';
import 'achievement_view.dart';
import 'custom_view.dart';
import 'message_view.dart';

/// Container widget for notifications with animation support
///
/// Handles the slide-in/slide-out animations and delegates
/// to the appropriate notification view based on type.
class NotificationContainer extends StatefulWidget {
  /// Creates a notification container
  const NotificationContainer({
    required this.notification,
    required this.config,
    required this.onDismiss,
    super.key,
  });

  /// The notification to display
  final SteamNotification notification;

  /// Configuration for animations and styling
  final SteamNotificationConfig config;

  /// Callback when the notification should be dismissed
  final VoidCallback onDismiss;

  @override
  State<NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    final slideDirection = PositionCalculator.getSlideDirection(
      widget.config.position,
    );

    _slideAnimation = Tween<Offset>(
      begin: slideDirection,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.config.animationCurve,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.config.animationCurve,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  void _handleTap() {
    widget.notification.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: _isHovered
                  ? (Matrix4.identity()..setEntry(0, 0, 1.02)..setEntry(1, 1, 1.02))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: _buildDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    final gradient = switch (widget.notification) {
      AchievementNotification() => SteamGradients.achievementBackground,
      MessageNotification() => SteamGradients.messageBackground,
      CustomNotification(backgroundColor: final bg) when bg != null => null,
      CustomNotification() => SteamGradients.defaultBackground,
    };

    final backgroundColor = switch (widget.notification) {
      CustomNotification(backgroundColor: final bg) => bg,
      _ => null,
    };

    return steamNotificationDecoration(
      gradient: gradient,
      backgroundColor: backgroundColor,
      showBorder: true,
      showShadow: true,
    ).copyWith(
      border: _isHovered
          ? Border.all(color: SteamColors.borderHighlight, width: 1)
          : Border.all(color: SteamColors.border, width: 1),
    );
  }

  Widget _buildContent() {
    return switch (widget.notification) {
      AchievementNotification() => AchievementView(
          notification: widget.notification as AchievementNotification,
          onClose: _dismiss,
        ),
      MessageNotification() => MessageView(
          notification: widget.notification as MessageNotification,
          onClose: _dismiss,
        ),
      CustomNotification() => CustomView(
          notification: widget.notification as CustomNotification,
          onClose: _dismiss,
        ),
    };
  }
}
