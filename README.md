# Steam Notifications

A Flutter package that provides Steam-inspired desktop notifications using Flutter's multi-window APIs. Each notification appears as a separate native window, providing an authentic gaming notification experience.

## Features

- **Multi-window notifications**: Each notification is a separate OS window
- **Steam-inspired design**: Dark theme with gradients, glow effects, and smooth animations
- **Three notification types**:
  - Achievement notifications with icons and progress bars
  - Message notifications with avatars
  - Custom notifications with arbitrary widgets
- **Configurable positioning**: Top-left, top-right, bottom-left, bottom-right
- **Automatic stacking**: Multiple notifications stack vertically
- **Queue system**: Excess notifications are queued when max visible is reached
- **Smooth animations**: Slide-in/slide-out with configurable curves
- **Hover effects**: Visual feedback on mouse hover
- **Auto-dismiss**: Configurable duration with manual dismiss support

## Requirements

- Flutter 3.24.0 or higher
- Dart 3.5.0 or higher
- Desktop platform (Windows, macOS, Linux)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  steam_notifications:
    git:
      url: https://github.com/your-repo/steam_notifications.git
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:steam_notifications/steam_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification system
  await SteamNotifications.initialize();

  runApp(MyApp());
}

// Show an achievement notification
SteamNotifications.showAchievement(
  title: 'First Blood',
  description: 'Get your first elimination',
  progress: 1.0,
);

// Show a message notification
SteamNotifications.showMessage(
  senderName: 'John Doe',
  message: 'Want to play a match?',
);

// Show a custom notification
SteamNotifications.showCustom(
  child: MyCustomWidget(),
);
```

## Configuration

Configure the notification system during initialization or at runtime:

```dart
await SteamNotifications.initialize(
  config: SteamNotificationConfig(
    position: NotificationPosition.bottomRight,
    maxVisibleNotifications: 5,
    defaultDuration: Duration(seconds: 5),
    animationDuration: Duration(milliseconds: 300),
    animationCurve: Curves.easeOutCubic,
    margin: EdgeInsets.all(16),
    spacing: 12.0,
    defaultWidth: 340.0,
    achievementHeight: 100.0,
    messageHeight: 80.0,
  ),
);

// Update configuration at runtime
SteamNotifications.configure(
  SteamNotificationConfig(
    position: NotificationPosition.topRight,
  ),
);
```

## API Reference

### SteamNotifications

Main static class for the notification system.

| Method | Description |
|--------|-------------|
| `initialize({config})` | Initialize the system (required before use) |
| `show(notification)` | Show any notification type |
| `showAchievement({...})` | Show an achievement notification |
| `showMessage({...})` | Show a message notification |
| `showCustom({...})` | Show a custom notification |
| `configure(config)` | Update configuration |
| `dismiss(id)` | Dismiss a specific notification |
| `dismissAll()` | Dismiss all notifications |
| `activeCount` | Number of visible notifications |
| `queuedCount` | Number of queued notifications |

### Achievement Notification

```dart
SteamNotifications.showAchievement(
  title: 'Achievement Title',           // Required
  description: 'Achievement description', // Required
  icon: Icon(Icons.star),               // Custom widget
  iconUrl: 'assets/icon.png',           // Or URL/asset path
  progress: 0.75,                       // 0.0 to 1.0
  showUnlockedHeader: true,             // Show "ACHIEVEMENT UNLOCKED"
  duration: Duration(seconds: 5),       // Auto-dismiss duration
  onTap: () => print('Tapped'),        // Tap callback
  onDismiss: () => print('Dismissed'), // Dismiss callback
);
```

### Message Notification

```dart
SteamNotifications.showMessage(
  message: 'Hello!',                    // Required
  senderName: 'John Doe',               // Optional sender name
  avatar: CircleAvatar(...),            // Custom widget
  avatarUrl: 'https://...',            // Or URL/asset path
  duration: Duration(seconds: 5),
  onTap: () => print('Tapped'),
  onDismiss: () => print('Dismissed'),
);
```

### Custom Notification

```dart
SteamNotifications.showCustom(
  child: MyCustomWidget(),              // Required
  width: 400,                           // Optional custom width
  height: 120,                          // Optional custom height
  showCloseButton: true,                // Show close button
  backgroundColor: Colors.blue,         // Custom background
  duration: Duration(seconds: 5),
  onTap: () => print('Tapped'),
  onDismiss: () => print('Dismissed'),
);
```

## Notification Position

```dart
enum NotificationPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,  // Default (Steam-like)
}
```

## Theming

The package includes a Steam-inspired dark theme. You can access the colors:

```dart
import 'package:steam_notifications/steam_notifications.dart';

// Use Steam colors
Container(
  color: SteamColors.backgroundPrimary,
  child: Text(
    'Hello',
    style: TextStyle(color: SteamColors.textPrimary),
  ),
);

// Available colors
SteamColors.backgroundPrimary    // #1B2838
SteamColors.backgroundSecondary  // #171A21
SteamColors.accentGreen          // #5BB32F (achievements)
SteamColors.accentBlue           // #66C0F4 (messages)
SteamColors.accentGold           // #D4AF37 (premium)
SteamColors.textPrimary          // #FFFFFF
SteamColors.textSecondary        // #C7D5E0
// ... and more
```

## Example

See the [example](example/) directory for a complete demo application.

```bash
cd example
flutter run -d macos  # or windows, linux
```

## Technical Notes

- Uses Flutter's `RegularWindow` and `RegularWindowController` APIs
- Each notification runs in its own window via `runWidget()`
- Notifications don't steal focus from the main application
- Window positions are calculated based on screen size and stack index
- Queue system handles overflow when max visible notifications is reached

## License

MIT License - see [LICENSE](LICENSE) for details.
