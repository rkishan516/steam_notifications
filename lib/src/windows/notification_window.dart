// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

import '../theme/steam_theme.dart';

/// A notification window that extends RegularWindow
///
/// Each notification is displayed in its own OS window for a true
/// Steam-like notification experience.
class NotificationWindow extends RegularWindow {
  /// Creates a notification window with the given controller and content
  NotificationWindow({
    required super.controller,
    required super.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? widget) {
        return WindowScope(
          controller: controller,
          child: View(
            view: controller.rootView,
            child: MediaQuery.fromView(
              view: controller.rootView,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Theme(
                  data: steamNotificationTheme(),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
