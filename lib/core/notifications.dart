import 'package:flutter/foundation.dart';
import 'localization.dart';

/// Notification represents a single game notification message
class Notification {
  final String message;
  final DateTime time;
  final bool noQueue;

  Notification(this.message, {this.noQueue = false}) : time = DateTime.now();
}

/// NotificationManager handles game notifications and messages
class NotificationManager with ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  // Notification queues for each module
  final Map<String, List<Notification>> _moduleQueues = {};

  // Global notification list (for history)
  final List<Notification> _notifications = [];

  // Maximum number of notifications to keep in history
  static const int _maxNotifications = 100;

  // Initialize the notification system
  void init() {
    _moduleQueues.clear();
    _notifications.clear();
  }

  // Add a notification
  void notify(String module, String message, {bool noQueue = false}) {
    final localizedMessage = _localizeMessage(message);
    final notification = Notification(localizedMessage, noQueue: noQueue);

    // Add to global history
    _notifications.add(notification);
    if (_notifications.length > _maxNotifications) {
      _notifications.removeAt(0);
    }

    // Add to module queue if not noQueue
    if (!noQueue) {
      if (!_moduleQueues.containsKey(module)) {
        _moduleQueues[module] = [];
      }
      _moduleQueues[module]!.add(notification);
    }

    notifyListeners();
  }

  // 本地化消息
  String _localizeMessage(String message) {
    try {
      final localization = Localization();

      // 检查是否是组合消息格式（如 "notifications.the_room_is temperature.cold"）
      if (message.contains(' ')) {
        final parts = message.split(' ');
        if (parts.length == 2) {
          final prefix = parts[0];
          final suffix = parts[1];

          // 尝试翻译每个部分
          String translatedPrefix = localization.translate(prefix);
          String translatedSuffix = localization.translate(suffix);

          // 如果两个部分都翻译成功，组合结果（中文不需要空格）
          if (translatedPrefix != prefix && translatedSuffix != suffix) {
            return '$translatedPrefix$translatedSuffix';
          }

          // 如果只有一个部分翻译成功，也尝试组合
          if (translatedPrefix != prefix || translatedSuffix != suffix) {
            // 对于中文，不添加空格；对于英文，添加空格
            final currentLang = localization.currentLanguage;
            return currentLang == 'zh'
                ? '$translatedPrefix$translatedSuffix'
                : '$translatedPrefix $translatedSuffix';
          }
        }
      }

      // 尝试直接翻译整个消息
      String directTranslation = localization.translate(message);
      if (directTranslation != message) {
        return directTranslation;
      }

      // 尝试使用通知专用的本地化键
      String notificationKey = 'notifications.$message';
      String notificationTranslation = localization.translate(notificationKey);
      if (notificationTranslation != notificationKey) {
        return notificationTranslation;
      }

      // 定义关键通知消息的后备映射（仅保留最重要的）
      final fallbackMessages = {
        'zh': {
          // 基础资源消息
          'not enough': '不够',
          'insufficient resources': '资源不足',
        },
        'en': {
          // 中文到英文的基础映射
          '不够': 'not enough',
          '资源不足': 'insufficient resources',
        }
      };

      final currentLang = localization.currentLanguage;
      final currentLangMessages = fallbackMessages[currentLang] ?? {};

      // 查找本地化消息
      if (currentLangMessages.containsKey(message)) {
        return currentLangMessages[message]!;
      }

      // 如果没有找到直接匹配，尝试部分匹配
      for (final entry in currentLangMessages.entries) {
        if (message.contains(entry.key)) {
          return message.replaceAll(entry.key, entry.value);
        }
      }

      return message; // 如果没有找到翻译，返回原始消息
    } catch (e) {
      return message; // 如果本地化失败，返回原始消息
    }
  }

  // Get notifications for a specific module
  List<Notification> getNotificationsForModule(String module) {
    return _moduleQueues[module] ?? [];
  }

  // Get all notifications (for history view)
  List<Notification> getAllNotifications() {
    return List.from(_notifications.reversed);
  }

  // Print the notification queue for a module
  void printQueue(String module) {
    if (!_moduleQueues.containsKey(module)) return;

    final queue = _moduleQueues[module]!;
    if (queue.isEmpty) return;

    // In the original game, this would display notifications in the UI
    // For now, we'll just log them in debug mode
    if (kDebugMode) {
      for (final notification in queue) {
        print('[$module] ${notification.message}');
      }
    }

    // Clear the queue after printing
    _moduleQueues[module] = [];
    notifyListeners();
  }

  // Clear all notifications for a module
  void clearQueue(String module) {
    if (_moduleQueues.containsKey(module)) {
      _moduleQueues[module] = [];
      notifyListeners();
    }
  }

  // Clear all notifications
  void clearAll() {
    _moduleQueues.clear();
    _notifications.clear();
    notifyListeners();
  }
}
