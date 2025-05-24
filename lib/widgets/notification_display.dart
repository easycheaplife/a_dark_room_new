import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/notifications.dart';

/// NotificationDisplay shows game notifications to the player
class NotificationDisplay extends StatelessWidget {
  const NotificationDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationManager>(
      builder: (context, notificationManager, child) {
        final notifications = notificationManager.getAllNotifications();

        return Container(
          height: 200,
          color: Colors.black,
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  notification.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
