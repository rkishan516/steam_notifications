// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';
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
    // Capture before any window work, so the toast itself can't be the
    // sampled foreground.
    final foreground = _foregroundWindow();

    // Drop notifications while a fullscreen app is active: creating the
    // toast window would steal foreground and minimise an exclusive-
    // fullscreen game, and it can't be shown over one anyway.
    if (_isFullscreenActive(foreground)) return;

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
      await _createStackWindow(foreground);
    } else {
      await _updateStackWindow(foreground);
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
      _updateStackWindow(_foregroundWindow());
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

  Future<void> _createStackWindow(HWND? foreground) async {
    final geometry = _resolveGeometry();
    if (geometry == null) return;

    final controller = RegularWindowController(
      size: geometry.logicalSize,
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
        await _configureStackWindow(controller, geometry, foreground);
      });
    });
  }

  Future<void> _updateStackWindow(HWND? foreground) async {
    final controller = _stackController;
    if (controller == null) return;

    final geometry = _resolveGeometry();
    if (geometry == null) return;

    try {
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
      // Re-evaluate topmost against the live foreground so the stack stops
      // floating over a game that went fullscreen mid-stack (and starts
      // floating again once it exits).
      await _applyStackTopmost(window, foreground);
    } on StateError {
      // Window was destroyed concurrently; nothing to update.
    }
  }

  Future<void> _configureStackWindow(
    RegularWindowController controller,
    _StackGeometry geometry,
    HWND? foreground,
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
      await _applyStackTopmost(window, foreground);
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

  /// The current foreground window, or `null` off Windows.
  HWND? _foregroundWindow() =>
      Platform.isWindows ? GetForegroundWindow() : null;

  /// Brings the stack above normal windows so it isn't occluded by the
  /// foreground app. Skips topmost while a fullscreen app is active to
  /// avoid forcing an exclusive-fullscreen game out of fullscreen — a
  /// safety net now that [show] suppresses notifications during
  /// fullscreen, still re-checked on dismiss.
  Future<void> _applyStackTopmost(
    DecoratedWindow? window,
    HWND? foreground,
  ) async {
    await window?.setAlwaysOnTop(alwaysOnTop: !_isFullscreenActive(foreground));
  }

  /// Whether a fullscreen app is active — shell state (exclusive-mode /
  /// presentation) or a foreground window-rect (borderless) check.
  bool _isFullscreenActive(HWND? foreground) =>
      _isShellInFullscreenState() || _isWindowFullscreen(foreground);

  /// Whether the Windows shell reports a state where a topmost toast
  /// would be disruptive (fullscreen app, exclusive-mode Direct3D game,
  /// presentation mode, or a full-screen Store app) via
  /// `SHQueryUserNotificationState`. This is the authoritative way to
  /// detect legacy exclusive-mode Direct3D fullscreen and presentation
  /// mode, which a window-rect comparison cannot see reliably.
  ///
  /// Returns `false` off Windows or if the query fails — callers also run
  /// the rect-based [_isWindowFullscreen] as a fallback.
  bool _isShellInFullscreenState() {
    if (!Platform.isWindows) return false;

    final statePtr = calloc<Int32>();
    try {
      // Non-zero HRESULT means the query failed; treat as "not fullscreen"
      // and let the rect fallback decide.
      if (_shQueryUserNotificationState(statePtr) != 0) return false;
      final state = statePtr.value;
      return state == _qunsBusy ||
          state == _qunsRunningD3dFullScreen ||
          state == _qunsPresentationMode ||
          state == _qunsApp;
    } on Object {
      // shell32 binding/look-up failure must never break notifications;
      // degrade to the rect-based fallback instead.
      return false;
    } finally {
      calloc.free(statePtr);
    }
  }

  /// Whether [hwnd] covers its entire monitor — our proxy for a
  /// fullscreen app (exclusive or borderless). Used to suppress
  /// always-on-top so the notification stack never forces a
  /// fullscreen game to minimise or drop out of exclusive mode.
  ///
  /// Returns `false` off Windows, for a null/zero handle, and for the
  /// shell/desktop (which legitimately span the monitor when nothing
  /// is fullscreen).
  bool _isWindowFullscreen(HWND? hwnd) {
    if (!Platform.isWindows || hwnd == null || hwnd.address == 0) return false;
    if (hwnd == GetShellWindow() || hwnd == GetDesktopWindow()) return false;

    final windowRect = calloc<RECT>();
    final monitorInfo = calloc<MONITORINFO>();
    try {
      if (!GetWindowRect(hwnd, windowRect).value) return false;
      final monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
      monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();
      if (!GetMonitorInfo(monitor, monitorInfo)) return false;

      final w = windowRect.ref;
      final m = monitorInfo.ref.rcMonitor;
      return w.left <= m.left &&
          w.top <= m.top &&
          w.right >= m.right &&
          w.bottom >= m.bottom;
    } finally {
      calloc
        ..free(windowRect)
        ..free(monitorInfo);
    }
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

// `SHQueryUserNotificationState` reports the shell's global notification
// state (including legacy exclusive-mode Direct3D fullscreen). It lives in
// shell32.dll but isn't exposed by package:win32, so we bind it directly.
// Lazily initialised — never touched off Windows.
final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');

final int Function(Pointer<Int32>) _shQueryUserNotificationState =
    _shell32.lookupFunction<Int32 Function(Pointer<Int32>),
        int Function(Pointer<Int32>)>('SHQueryUserNotificationState');

// QUERY_USER_NOTIFICATION_STATE values where a topmost toast would be
// disruptive, so we don't float the stack over them: a full-screen app,
// an exclusive-mode Direct3D game, Windows presentation mode, or a
// full-screen Store app.
const int _qunsBusy = 2; // a full-screen application is running
const int _qunsRunningD3dFullScreen = 3; // exclusive-mode Direct3D fullscreen
const int _qunsPresentationMode = 4; // presentation settings turned on
const int _qunsApp = 7; // Windows Store app running full-screen
