// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';

/// Delegate for handling notification window lifecycle events
class NotificationWindowDelegate extends RegularWindowControllerDelegate {
  /// Creates a delegate with the specified callbacks
  NotificationWindowDelegate({required this.onDestroyed});

  /// Callback when the window is destroyed
  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    onDestroyed();
  }
}
