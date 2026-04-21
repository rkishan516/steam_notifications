import 'package:flutter/material.dart';

import '../config/notification_config.dart';
import '../core/steam_notification_service.dart';
import '../models/notification.dart';
import '../theme/steam_colors.dart';
import '../theme/steam_theme.dart';
import 'notification_container.dart';

/// Default outer decoration of the stack window.
BoxDecoration _defaultStackDecoration() {
  return BoxDecoration(
    color: SteamColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: SteamColors.border),
    boxShadow: const [
      BoxShadow(
        color: SteamColors.shadowStrong,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: SteamColors.shadow,
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );
}

/// Renders the entire notification stack inside a single OS window.
///
/// Layout:
///   - Outer box uses [SteamNotificationConfig.stackDecorationBuilder]
///     (radius, border, shadow, surface color).
///   - Background layer uses [SteamNotificationConfig.stackBackgroundBuilder]
///     laid out across the full capacity × slot area. Slots that fall
///     outside the resized window are clipped, producing the partial-logo
///     effect when the stack isn't full.
///   - Foreground is a Column of notification content, flush-stacked with
///     no inter-slot spacing.
class StackView extends StatelessWidget {
  const StackView({
    required this.entries,
    required this.config,
    this.notificationBuilder,
    this.onDismiss,
    super.key,
  });

  final List<ActiveNotificationEntry> entries;
  final SteamNotificationConfig config;
  final Widget Function(
    BuildContext context,
    SteamNotification notification,
    VoidCallback onDismiss,
  )?
  notificationBuilder;
  final void Function(String id)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    final capacity = config.stackCapacity;
    final slotSize = Size(config.defaultWidth, config.messageHeight);
    final slots = SteamNotificationService.slotsForCount(
      count,
      capacity,
      config.position,
    );
    final minSlot = slots.isEmpty ? 0 : slots.first;

    final decoration =
        config.stackDecorationBuilder?.call(context, count) ??
        _defaultStackDecoration();
    final borderRadius = _extractRadius(decoration);

    final background = config.stackBackgroundBuilder?.call(
      context,
      StackBackgroundContext(
        activeCount: count,
        capacity: capacity,
        slotSize: slotSize,
      ),
    );

    return Theme(
      data: config.themeData ?? steamNotificationTheme(),
      child: Container(
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: _StackContent(
          entries: entries,
          config: config,
          slotSize: slotSize,
          capacity: capacity,
          slotMinIndex: minSlot,
          background: background,
          borderRadius: borderRadius,
          notificationBuilder: notificationBuilder,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  BorderRadius _extractRadius(BoxDecoration decoration) {
    final radius = decoration.borderRadius;
    if (radius is BorderRadius) return radius;
    return BorderRadius.zero;
  }
}

class _StackContent extends StatelessWidget {
  const _StackContent({
    required this.entries,
    required this.config,
    required this.slotSize,
    required this.capacity,
    required this.slotMinIndex,
    required this.background,
    required this.borderRadius,
    required this.notificationBuilder,
    required this.onDismiss,
  });

  final List<ActiveNotificationEntry> entries;
  final SteamNotificationConfig config;
  final Size slotSize;
  final int capacity;
  final int slotMinIndex;
  final Widget? background;
  final BorderRadius borderRadius;
  final Widget Function(
    BuildContext,
    SteamNotification,
    VoidCallback,
  )?
  notificationBuilder;
  final void Function(String id)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final visibleCount = entries.length.clamp(0, capacity);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hairline dividers between adjacent visible slots. Drawn behind
        // the background artwork and notification content.
        for (var i = 1; i < visibleCount; i++)
          Positioned(
            left: 12,
            right: 12,
            top: i * slotSize.height - 0.5,
            height: 1,
            child: const IgnorePointer(
              child: ColoredBox(color: SteamColors.backgroundSecondary),
            ),
          ),
        if (background != null)
          Positioned(
            left: 0,
            top: -slotMinIndex * slotSize.height,
            width: slotSize.width,
            height: slotSize.height * capacity,
            child: IgnorePointer(child: background),
          ),
        _AnimatedStackItems(
          entries: entries,
          slotSize: slotSize,
          capacity: capacity,
          minSlot: slotMinIndex,
          insertDuration: config.animationDuration,
          removeDuration: Duration(
            milliseconds: (config.animationDuration.inMilliseconds * 0.7)
                .round(),
          ),
          curve: config.animationCurve,
          itemBuilder: (entry) => NotificationContainer(
            notification: entry.notification,
            config: config,
            onDismiss: () => onDismiss?.call(entry.notification.id),
            customBuilder: notificationBuilder,
          ),
        ),
      ],
    );
  }
}

/// Lays out notifications as animated [Positioned] children:
///
/// - Enter: new items slide up from below their rest slot and fade in.
/// - Exit: removed items fade out while sliding slightly down.
/// - Shift: when the stack overflows and remaining items move up a
///   slot, their `top` animates via implicit [AnimatedPositioned].
class _AnimatedStackItems extends StatefulWidget {
  const _AnimatedStackItems({
    required this.entries,
    required this.slotSize,
    required this.capacity,
    required this.minSlot,
    required this.insertDuration,
    required this.removeDuration,
    required this.curve,
    required this.itemBuilder,
  });

  final List<ActiveNotificationEntry> entries;
  final Size slotSize;
  final int capacity;
  final int minSlot;
  final Duration insertDuration;
  final Duration removeDuration;
  final Curve curve;
  final Widget Function(ActiveNotificationEntry entry) itemBuilder;

  @override
  State<_AnimatedStackItems> createState() => _AnimatedStackItemsState();
}

class _AnimatedStackItemsState extends State<_AnimatedStackItems>
    with TickerProviderStateMixin {
  final Map<String, _AnimatedSlot> _slots = {};

  @override
  void initState() {
    super.initState();
    _syncEntries();
  }

  @override
  void didUpdateWidget(covariant _AnimatedStackItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEntries();
  }

  void _syncEntries() {
    final currentIds = <String>{
      for (final e in widget.entries) e.notification.id,
    };

    for (final id in _slots.keys.toList()) {
      final slot = _slots[id]!;
      if (currentIds.contains(id) || slot.exitController != null) continue;
      final exitController = AnimationController(
        vsync: this,
        duration: widget.removeDuration,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            slot.enterController.dispose();
            slot.exitController?.dispose();
            _slots.remove(id);
          });
        }
      });
      slot.exitController = exitController;
      exitController.forward();
    }

    for (var i = 0; i < widget.entries.length; i++) {
      final entry = widget.entries[i];
      final id = entry.notification.id;
      final existing = _slots[id];
      final worldSlot = widget.minSlot + i;
      if (existing == null) {
        final enterController = AnimationController(
          vsync: this,
          duration: widget.insertDuration,
        );
        _slots[id] = _AnimatedSlot(
          entry: entry,
          index: i,
          worldSlot: worldSlot,
          enterController: enterController,
        );
        enterController.forward();
      } else {
        existing.entry = entry;
        existing.index = i;
        existing.worldSlot = worldSlot;
      }
    }
  }

  @override
  void dispose() {
    for (final slot in _slots.values) {
      slot.enterController.dispose();
      slot.exitController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotHeight = widget.slotSize.height;
    final fullStackHeight = slotHeight * widget.capacity;
    // Outer layer is anchored in WORLD coordinates: when minSlot changes
    // (the window grows or shrinks) its translation snaps instantly so
    // child items keep their absolute screen position. That way an exit
    // elsewhere in the stack doesn't cause surviving items to re-run
    // their enter animation just because the window resized.
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -widget.minSlot * slotHeight,
          height: fullStackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final slot in _slots.values)
                AnimatedPositioned(
                  key: ValueKey(slot.entry.notification.id),
                  duration: widget.insertDuration,
                  curve: widget.curve,
                  left: 0,
                  right: 0,
                  top: slot.worldSlot * slotHeight,
                  height: slotHeight,
                  child: _AnimatedSlotView(
                    slot: slot,
                    slotHeight: slotHeight,
                    curve: widget.curve,
                    child: widget.itemBuilder(slot.entry),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedSlotView extends StatelessWidget {
  const _AnimatedSlotView({
    required this.slot,
    required this.slotHeight,
    required this.curve,
    required this.child,
  });

  final _AnimatedSlot slot;
  final double slotHeight;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final exit = slot.exitController;
    final animation = exit == null
        ? slot.enterController
        : Listenable.merge([slot.enterController, exit]);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, innerChild) {
        final enterT = curve.transform(slot.enterController.value);
        final exitT = exit == null ? 0.0 : curve.transform(exit.value);
        // Enter slides up from below (y=slotH → 0). Exit continues the
        // same direction, sliding up and out (y=0 → -slotH).
        final translateY = (1 - enterT - exitT) * slotHeight;
        final opacity = (enterT * (1 - exitT)).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: innerChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _AnimatedSlot {
  _AnimatedSlot({
    required this.entry,
    required this.index,
    required this.worldSlot,
    required this.enterController,
  });

  ActiveNotificationEntry entry;
  int index;

  /// Absolute slot index within the conceptual full stack (0..capacity-1).
  /// Stable when siblings exit and the window shrinks — only changes when
  /// this item itself actually moves between slots (e.g. overflow shift).
  int worldSlot;

  final AnimationController enterController;
  AnimationController? exitController;
}
