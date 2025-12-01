import 'package:flutter/material.dart';

import '../../theme/steam_colors.dart';

/// Progress bar widget for achievement notifications
class NotificationProgressBar extends StatelessWidget {
  /// Creates a progress bar
  const NotificationProgressBar({
    required this.progress,
    this.height = 4.0,
    super.key,
  });

  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Height of the progress bar
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: SteamColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * clampedProgress,
                decoration: BoxDecoration(
                  gradient: SteamGradients.progressBar,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: SteamColors.accentGreen.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
