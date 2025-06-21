import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/notifications.dart';
import '../core/responsive_layout.dart';

/// NotificationDisplay 显示游戏通知给玩家
class NotificationDisplay extends StatelessWidget {
  const NotificationDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Consumer<NotificationManager>(
      builder: (context, notificationManager, child) {
        final notifications = notificationManager.getAllNotifications();

        return Container(
          width: layoutParams.notificationWidth,
          height: layoutParams.notificationHeight,
          padding: const EdgeInsets.all(0), // 原游戏没有内边距
          child: Stack(
            children: [
              // 通知列表 - 最新的在顶部
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知列表
                  Expanded(
                    child: ListView.builder(
                      reverse: false, // 最新的通知在顶部
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        // getAllNotifications() 已经返回了反转的列表，所以直接使用index
                        final notification = notifications[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: layoutParams.useVerticalLayout ? 6 : 10, // 移动端使用更小的间距
                          ),
                          child: Text(
                            notification.message,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: layoutParams.fontSize, // 使用响应式字体大小
                              fontFamily: 'Times New Roman',
                            ),
                            maxLines: layoutParams.useVerticalLayout ? 2 : null, // 移动端限制行数
                            overflow: layoutParams.useVerticalLayout ? TextOverflow.ellipsis : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 渐变遮罩 - 模拟原游戏的notifyGradient效果
              if (!layoutParams.useVerticalLayout) // 只在桌面端显示渐变遮罩
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0), // 透明
                          Color.fromRGBO(255, 255, 255, 1), // 白色
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
