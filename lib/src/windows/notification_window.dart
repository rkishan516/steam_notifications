// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

/// An OS-level window that hosts the notification stack.
///
/// The entire stack of active notifications shares this single window;
/// the [child] is typically a `StackView` supplied by
/// `SteamNotifications.buildNotificationViews`.
class NotificationWindow extends RegularWindow {
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
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
