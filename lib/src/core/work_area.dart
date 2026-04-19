import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

/// Usable region of a display in physical pixels.
///
/// On Windows this excludes the taskbar; on other platforms it currently
/// matches the full display rect.
class WorkAreaRect {
  const WorkAreaRect({
    required this.origin,
    required this.size,
    required this.devicePixelRatio,
  });

  final Offset origin;
  final Size size;
  final double devicePixelRatio;

  double get left => origin.dx;
  double get top => origin.dy;
  double get right => origin.dx + size.width;
  double get bottom => origin.dy + size.height;
}

/// Resolves the work-area rectangle of the primary display.
///
/// Hosts can inject a custom implementation via
/// [SteamNotificationConfig.workAreaResolver] — e.g. to anchor
/// notifications to a non-primary monitor.
abstract class WorkAreaResolver {
  const WorkAreaResolver();

  /// Default resolver for the current platform.
  factory WorkAreaResolver.defaultForPlatform() {
    if (Platform.isWindows) {
      return const _Win32WorkAreaResolver();
    }
    return const _DisplaySizeWorkAreaResolver();
  }

  WorkAreaRect resolve();
}

class _DisplaySizeWorkAreaResolver extends WorkAreaResolver {
  const _DisplaySizeWorkAreaResolver();

  @override
  WorkAreaRect resolve() {
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    return WorkAreaRect(
      origin: Offset.zero,
      size: display.size,
      devicePixelRatio: display.devicePixelRatio,
    );
  }
}

class _Win32WorkAreaResolver extends WorkAreaResolver {
  const _Win32WorkAreaResolver();

  @override
  WorkAreaRect resolve() {
    final display = WidgetsBinding.instance.platformDispatcher.displays.first;
    final rect = calloc<RECT>();
    try {
      final ok = SystemParametersInfo(
        SPI_GETWORKAREA,
        0,
        rect,
        const SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0),
      );
      if (!ok.value) {
        return WorkAreaRect(
          origin: Offset.zero,
          size: display.size,
          devicePixelRatio: display.devicePixelRatio,
        );
      }
      final r = rect.ref;
      return WorkAreaRect(
        origin: Offset(r.left.toDouble(), r.top.toDouble()),
        size: Size(
          (r.right - r.left).toDouble(),
          (r.bottom - r.top).toDouble(),
        ),
        devicePixelRatio: display.devicePixelRatio,
      );
    } finally {
      free(rect);
    }
  }
}
