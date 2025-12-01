import 'dart:collection';

import '../models/notification.dart';

/// Manages a queue of pending notifications
///
/// When the maximum number of visible notifications is reached,
/// new notifications are queued and displayed as slots become available.
class NotificationQueue {
  final Queue<SteamNotification> _queue = Queue<SteamNotification>();

  /// Number of notifications currently in the queue
  int get length => _queue.length;

  /// Whether the queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Whether the queue has notifications
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Adds a notification to the end of the queue
  void enqueue(SteamNotification notification) {
    _queue.add(notification);
  }

  /// Removes and returns the notification at the front of the queue
  /// Returns null if the queue is empty
  SteamNotification? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  /// Returns the notification at the front without removing it
  /// Returns null if the queue is empty
  SteamNotification? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  /// Removes a specific notification from the queue by ID
  /// Returns true if the notification was found and removed
  bool remove(String id) {
    final initialLength = _queue.length;
    _queue.removeWhere((n) => n.id == id);
    return _queue.length < initialLength;
  }

  /// Clears all notifications from the queue
  void clear() {
    _queue.clear();
  }

  /// Returns all queued notifications as a list
  List<SteamNotification> toList() {
    return _queue.toList();
  }
}
