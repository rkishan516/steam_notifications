// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';
import 'package:window_decoration/window_decoration.dart';

import '../config/notification_config.dart';
import '../config/notification_position.dart';
import '../models/notification.dart';
import '../theme/steam_colors.dart';
import '../windows/notification_delegate.dart';
import 'notification_manager.dart' show NotificationBuilder;
import 'work_area.dart';

/// Runtime entry for a single live notification in the stack.
class ActiveNotificationEntry {
  ActiveNotificationEntry({
    required this.notification,
  });

  final SteamNotification notification;
  Timer? dismissTimer;

  void cancelTimer() {
    dismissTimer?.cancel();
    dismissTimer = null;
  }
}

/// Singleton that owns notification state for the whole app lifecycle.
///
/// All active notifications share a single OS window that grows/shrinks
/// based on [SteamNotificationConfig.stackCapacity]. The window is
/// positioned inside the work area (excluding the Windows taskbar).
///
/// Render the stack either by keeping a [NotificationManager] in the
/// tree, or by placing `SteamNotifications.buildNotificationViews()`
/// into a root-level [ViewCollection].
class SteamNotificationService extends ChangeNotifier {
  SteamNotificationService._();

  static final SteamNotificationService instance =
      SteamNotificationService._();

  SteamNotificationConfig _config = const SteamNotificationConfig();
  final List<ActiveNotificationEntry> _activeNotifications = [];
  RegularWindowController? _stackController;
  NotificationBuilder? _notificationBuilder;

  SteamNotificationConfig get config => _config;

  NotificationBuilder? get notificationBuilder => _notificationBuilder;

  List<ActiveNotificationEntry> get activeNotifications =>
      List.unmodifiable(_activeNotifications);

  int get activeCount => _activeNotifications.length;

  /// Controller of the stack window, or `null` when no notifications
  /// are currently visible. Exposed so the root [ViewCollection]
  /// builder can render the window.
  RegularWindowController? get stackController => _stackController;

  void configure(SteamNotificationConfig config) {
    _config = config;
    notifyListeners();
  }

  void setNotificationBuilder(NotificationBuilder? builder) {
    _notificationBuilder = builder;
    notifyListeners();
  }

  Future<void> show(SteamNotification notification) async {
    final isFirst = _activeNotifications.isEmpty;

    if (_activeNotifications.length >= _config.stackCapacity) {
      final dropped = _activeNotifications.removeAt(0);
      dropped.cancelTimer();
      dropped.notification.onDismiss?.call();
    }

    final entry = ActiveNotificationEntry(notification: notification);
    _activeNotifications.add(entry);
    _scheduleAutoDismiss(entry);

    notifyListeners();

    if (isFirst) {
      await _createStackWindow();
    } else {
      await _updateStackWindow();
    }
  }

  void dismiss(String id) {
    final index = _activeNotifications.indexWhere(
      (n) => n.notification.id == id,
    );
    if (index == -1) return;

    final active = _activeNotifications.removeAt(index);
    active.cancelTimer();
    active.notification.onDismiss?.call();

    notifyListeners();

    if (_activeNotifications.isEmpty) {
      _destroyStackWindow();
    } else {
      _updateStackWindow();
    }
  }

  void dismissAll() {
    for (final active in _activeNotifications) {
      active.cancelTimer();
      active.notification.onDismiss?.call();
    }
    _activeNotifications.clear();
    _destroyStackWindow();
    notifyListeners();
  }

  Future<void> _createStackWindow() async {
    final geometry = _resolveGeometry();
    if (geometry == null) return;

    final controller = RegularWindowController(
      preferredSize: geometry.logicalSize,
      title: '',
      delegate: NotificationWindowDelegate(
        onDestroyed: _handleWindowDestroyed,
      ),
    );

    _stackController = controller;
    notifyListeners();

    // Defer native Win32 calls to the next event loop turn so they don't
    // re-enter the scheduler during a post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.run(() async {
        if (!identical(_stackController, controller)) return;
        await _configureStackWindow(controller, geometry);
      });
    });
  }

  Future<void> _updateStackWindow() async {
    final controller = _stackController;
    if (controller == null) return;

    final geometry = _resolveGeometry();
    if (geometry == null) return;

    final window = DecoratedWindow.forController(controller);
    controller.setSize(geometry.logicalSize);
    controller.setConstraints(
      BoxConstraints(
        minWidth: geometry.logicalSize.width,
        minHeight: geometry.logicalSize.height,
        maxWidth: geometry.logicalSize.width,
        maxHeight: geometry.logicalSize.height,
      ),
    );
    await window?.setPosition(geometry.physicalPosition);
  }

  Future<void> _configureStackWindow(
    RegularWindowController controller,
    _StackGeometry geometry,
  ) async {
    try {
      controller.enableDecoratedWindow();
      controller.setSize(geometry.logicalSize);
      final window = DecoratedWindow.forController(controller);
      // WS_EX_NOACTIVATE so clicks and z-order ops don't steal focus.
      await window?.setNoActivate(enabled: true);
      if (!identical(_stackController, controller)) return;
      await window?.setPosition(geometry.physicalPosition);
      if (!identical(_stackController, controller)) return;

      controller.setConstraints(
        BoxConstraints(
          minWidth: geometry.logicalSize.width,
          minHeight: geometry.logicalSize.height,
          maxWidth: geometry.logicalSize.width,
          maxHeight: geometry.logicalSize.height,
        ),
      );

      await window?.setBackgroundColor(SteamColors.surface);
      if (!identical(_stackController, controller)) return;
      await window?.setSkipTaskbar(skip: true);
      if (!identical(_stackController, controller)) return;
      await window?.show();
    } on StateError {
      // Window was destroyed concurrently; nothing to configure.
    }
  }

  void _destroyStackWindow() {
    _stackController?.destroy();
    _stackController = null;
    notifyListeners();
  }

  void _handleWindowDestroyed() {
    _stackController = null;
    for (final active in _activeNotifications) {
      active.cancelTimer();
    }
    _activeNotifications.clear();
    notifyListeners();
  }

  _StackGeometry? _resolveGeometry() {
    if (_activeNotifications.isEmpty) return null;

    final resolver =
        _config.workAreaResolver ?? WorkAreaResolver.defaultForPlatform();
    final workArea = resolver.resolve();
    final dpr = workArea.devicePixelRatio;

    final capacity = _config.stackCapacity;
    final k = _activeNotifications.length.clamp(1, capacity);
    final slotHeight = _slotHeight();
    final slotWidth = _config.defaultWidth;

    final slots = slotsForCount(k, capacity, _config.position);
    final minSlot = slots.first;
    final maxSlot = slots.last;
    final visibleSlots = maxSlot - minSlot + 1;

    final fullStackHeight = slotHeight * capacity;
    final marginRight = _config.margin.right;
    final marginBottom = _config.margin.bottom;
    final marginLeft = _config.margin.left;
    final marginTop = _config.margin.top;

    final workAreaLogical = Size(
      workArea.size.width / dpr,
      workArea.size.height / dpr,
    );

    final double anchorLeft;
    final double anchorTop;
    switch (_config.position) {
      case NotificationPosition.bottomRight:
        anchorLeft = workAreaLogical.width - marginRight - slotWidth;
        anchorTop = workAreaLogical.height - marginBottom - fullStackHeight;
      case NotificationPosition.bottomLeft:
        anchorLeft = marginLeft;
        anchorTop = workAreaLogical.height - marginBottom - fullStackHeight;
      case NotificationPosition.topRight:
        anchorLeft = workAreaLogical.width - marginRight - slotWidth;
        anchorTop = marginTop;
      case NotificationPosition.topLeft:
        anchorLeft = marginLeft;
        anchorTop = marginTop;
    }

    final borderInsets = _config.stackBorderInsets;
    final windowLogicalTop =
        anchorTop + minSlot * slotHeight - borderInsets.top;
    final windowLogicalLeft = anchorLeft - borderInsets.left;
    final windowLogicalSize = Size(
      slotWidth + borderInsets.horizontal,
      visibleSlots * slotHeight + borderInsets.vertical,
    );

    final physicalOrigin = Offset(
      workArea.origin.dx + windowLogicalLeft * dpr,
      workArea.origin.dy + windowLogicalTop * dpr,
    );
    final physicalSize = Size(
      windowLogicalSize.width * dpr,
      windowLogicalSize.height * dpr,
    );

    return _StackGeometry(
      logicalSize: windowLogicalSize,
      physicalSize: physicalSize,
      physicalPosition: physicalOrigin,
      slotMinIndex: minSlot,
    );
  }

  double _slotHeight() => _config.messageHeight;

  void _scheduleAutoDismiss(ActiveNotificationEntry active) {
    final duration = active.notification.duration ?? _config.defaultDuration;
    active.dismissTimer = Timer(duration, () {
      dismiss(active.notification.id);
    });
  }

  /// Resolves which slot indices are occupied for a given active count.
  ///
  /// Bottom-anchored positions grow upward (newest always at the
  /// bottom slot, existing shift up):
  ///   k=1, C=3 → [2]           (bottom only)
  ///   k=2, C=3 → [1, 2]        (middle + bottom)
  ///   k=3, C=3 → [0, 1, 2]     (full stack)
  ///
  /// Top-anchored positions grow downward (newest at the bottom of
  /// the current stack, anchor fixed at top):
  ///   k=1, C=3 → [0]
  ///   k=2, C=3 → [0, 1]
  ///   k=3, C=3 → [0, 1, 2]
  static List<int> slotsForCount(
    int k,
    int capacity,
    NotificationPosition position,
  ) {
    if (k <= 0) return const [];
    final visible = k >= capacity ? capacity : k;
    final start = switch (position) {
      NotificationPosition.bottomRight ||
      NotificationPosition.bottomLeft => capacity - visible,
      NotificationPosition.topRight || NotificationPosition.topLeft => 0,
    };
    return [for (var i = start; i < start + visible; i++) i];
  }
}

class _StackGeometry {
  const _StackGeometry({
    required this.logicalSize,
    required this.physicalSize,
    required this.physicalPosition,
    required this.slotMinIndex,
  });

  final Size logicalSize;
  final Size physicalSize;
  final Offset physicalPosition;

  /// Index of the first occupied slot within the conceptual full stack
  /// (0..capacity-1). Used to offset the background artwork.
  final int slotMinIndex;
}
