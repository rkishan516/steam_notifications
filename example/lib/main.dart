// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:steam_notifications/steam_notifications.dart';

class MainWindowDelegate extends RegularWindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    // Exit application when main window is closed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create main window
  final controller = RegularWindowController(
    preferredSize: const Size(800, 600),
    title: 'Steam Notifications Demo',
    delegate: MainWindowDelegate(),
  );

  runWidget(
    RegularWindow(
      controller: controller,
      // Wrap the app with NotificationManager to enable notifications
      child: NotificationManager(
        key: SteamNotifications.managerKey,
        config: const SteamNotificationConfig(
          position: NotificationPosition.bottomRight,
          maxVisibleNotifications: 3,
          defaultDuration: Duration(seconds: 5),
        ),
        child: const ExampleApp(),
      ),
    ),
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steam Notifications Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1B2838),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF66C0F4),
        ),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  NotificationPosition _position = NotificationPosition.bottomRight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steam Notifications Demo'),
        backgroundColor: const Color(0xFF171A21),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Position selector
            _buildSection(
              title: 'Position',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: NotificationPosition.values.map((pos) {
                  return ChoiceChip(
                    label: Text(pos.name),
                    selected: _position == pos,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _position = pos);
                        SteamNotifications.configure(
                          SteamNotificationConfig(position: pos),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Achievement notifications
            _buildSection(
              title: 'Achievement Notifications',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAchievement,
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('Show Achievement'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAchievementWithProgress,
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Achievement with Progress'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAchievementNoHeader,
                    icon: const Icon(Icons.star),
                    label: const Text('Achievement (No Header)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Message notifications
            _buildSection(
              title: 'Message Notifications',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Show Message'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showMessageNoSender,
                    icon: const Icon(Icons.chat_bubble),
                    label: const Text('Message (No Sender)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Custom notifications
            _buildSection(
              title: 'Custom Notifications',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCustom,
                    icon: const Icon(Icons.widgets),
                    label: const Text('Show Custom'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            _buildSection(
              title: 'Controls',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showMultiple,
                    icon: const Icon(Icons.queue),
                    label: const Text('Show Multiple (Test Queue)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: SteamNotifications.dismissAll,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Dismiss All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF66C0F4),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  void _showAchievement() {
    SteamNotifications.showAchievement(
      title: 'First Blood',
      description: 'Get your first elimination in a match',
      onTap: () => debugPrint('Achievement tapped!'),
    );
  }

  void _showAchievementWithProgress() {
    SteamNotifications.showAchievement(
      title: 'Sharpshooter',
      description: 'Win 10 matches with 80% headshot accuracy',
      progress: 0.7,
      onTap: () => debugPrint('Achievement with progress tapped!'),
    );
  }

  void _showAchievementNoHeader() {
    SteamNotifications.showAchievement(
      title: 'Veteran Player',
      description: 'Complete 100 matches',
      showUnlockedHeader: false,
      progress: 1.0,
    );
  }

  void _showMessage() {
    SteamNotifications.showMessage(
      senderName: 'John Doe',
      message: 'Hey! Want to play a match?',
      onTap: () => debugPrint('Message tapped!'),
    );
  }

  void _showMessageNoSender() {
    SteamNotifications.showMessage(
      message: 'Your friend is now online.',
    );
  }

  void _showCustom() {
    SteamNotifications.showCustom(
      height: 100,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 48,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Special Offer!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Get 50% off on all items today!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC7D5E0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiple() {
    SteamNotifications.showAchievement(
      title: 'First Achievement',
      description: 'This is the first notification',
    );
    SteamNotifications.showAchievement(
      title: 'Second Achievement',
      description: 'This is the second notification',
    );
    SteamNotifications.showAchievement(
      title: 'Third Achievement',
      description: 'This is the third notification',
    );
    SteamNotifications.showMessage(
      senderName: 'System',
      message: 'This one should be queued!',
    );
  }
}
