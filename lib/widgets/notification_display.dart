import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/notifications.dart';

/// NotificationDisplay 显示游戏通知给玩家
class NotificationDisplay extends StatelessWidget {
  const NotificationDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationManager>(
      builder: (context, notificationManager, child) {
        final notifications = notificationManager.getAllNotifications();

        return Container(
          width: 200,
          height: 700,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通知标题
              const Text(
                '通知',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // 通知列表
              Expanded(
                child: ListView.builder(
                  reverse: true, // 最新的通知在底部
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Times New Roman',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
