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

      // 定义通知消息的本地化映射
      final notificationMessages = {
        'zh': {
          // 房间相关
          'the room is freezing': '房间冰冷',
          'the room is cold': '房间寒冷',
          'the room is mild': '房间温和',
          'the room is warm': '房间温暖',
          'the room is hot': '房间炎热',
          'the fire is dead': '火焰熄灭',
          'the fire is smoldering': '火焰闷烧',
          'the fire is flickering': '火焰摇曳',
          'the fire is burning': '火焰燃烧',
          'the fire is roaring': '火焰熊熊燃烧',

          // 外部相关
          'the sky is grey and the wind blows relentlessly': '天空是灰色的，风无情地吹着',
          'dry brush and dead branches litter the forest floor':
              '干燥的灌木和枯枝散落在森林地面上',
          'the traps are empty': '陷阱里什么都没有',
          'gained wood': '获得了木材',
          'gained meat': '获得了肉类',
          'gained fur': '获得了毛皮',

          // 事件相关
          'a ragged stranger stumbles through the door and collapses in the corner':
              '一个衣衫褴褛的陌生人跌跌撞撞地走进门，倒在角落里',
          'the stranger shivers, and mumbles quietly. her words are unintelligible.':
              '陌生人颤抖着，轻声嘟囔。她的话听不清楚。',
          'the stranger in the corner stops shivering. her breathing calms.':
              '角落里的陌生人停止了颤抖。她的呼吸平静下来。',
          'the stranger stands by the fire. she says she can help. says she builds things.':
              '陌生人站在火边。她说她可以帮忙。说她会建造东西。',
          'the builder just shivers': '建造者只是颤抖',
          'the builder stokes the fire': '建造者添了柴',
          'not enough wood to get the fire going': '木材不够点火',
          'the wood is running out': '木材快用完了',
          'the fire is out': '火焰熄灭了',
          'light from the fire spills from the windows, out into the dark':
              '火光从窗户洒出，照进黑暗',
          'the wind howls outside': '外面风声呼啸',

          // 资源不足
          'not enough': '不够',
          'insufficient resources': '资源不足',

          // 世界相关
          'found a mysterious device': '发现了一个神秘的装置',
          'the world fades': '世界渐渐消失了',
          'returned to the dark room': '返回小黑屋',
          'it is safer here': '这里更安全',
          'it is dangerous to be this far from the village without proper protection':
              '离村庄这么远而没有适当保护是危险的',
        },
        'en': {
          // 中文到英文的映射
          '房间冰冷': 'the room is freezing',
          '房间寒冷': 'the room is cold',
          '房间温和': 'the room is mild',
          '房间温暖': 'the room is warm',
          '房间炎热': 'the room is hot',
          '火焰熄灭': 'the fire is dead',
          '火焰闷烧': 'the fire is smoldering',
          '火焰摇曳': 'the fire is flickering',
          '火焰燃烧': 'the fire is burning',
          '火焰熊熊燃烧': 'the fire is roaring',

          '天空是灰色的，风无情地吹着': 'the sky is grey and the wind blows relentlessly',
          '干燥的灌木和枯枝散落在森林地面上':
              'dry brush and dead branches litter the forest floor',
          '陷阱里什么都没有': 'the traps are empty',
          '获得了木材': 'gained wood',
          '获得了肉类': 'gained meat',
          '获得了毛皮': 'gained fur',

          '一个衣衫褴褛的陌生人跌跌撞撞地走进门，倒在角落里':
              'a ragged stranger stumbles through the door and collapses in the corner',
          '陌生人颤抖着，轻声嘟囔。她的话听不清楚。':
              'the stranger shivers, and mumbles quietly. her words are unintelligible.',
          '角落里的陌生人停止了颤抖。她的呼吸平静下来。':
              'the stranger in the corner stops shivering. her breathing calms.',
          '陌生人站在火边。她说她可以帮忙。说她会建造东西。':
              'the stranger stands by the fire. she says she can help. says she builds things.',
          '建造者只是颤抖': 'the builder just shivers',
          '建造者添了柴': 'the builder stokes the fire',
          '木材不够点火': 'not enough wood to get the fire going',
          '木材快用完了': 'the wood is running out',
          '火焰熄灭了': 'the fire is out',
          '火光从窗户洒出，照进黑暗':
              'light from the fire spills from the windows, out into the dark',
          '外面风声呼啸': 'the wind howls outside',

          '不够': 'not enough',
          '资源不足': 'insufficient resources',

          '发现了一个神秘的装置': 'found a mysterious device',
          '世界渐渐消失了': 'the world fades',
          '返回小黑屋': 'returned to the dark room',
          '这里更安全': 'it is safer here',
          '离村庄这么远而没有适当保护是危险的':
              'it is dangerous to be this far from the village without proper protection',
        }
      };

      final currentLang = localization.currentLanguage;
      final currentLangMessages = notificationMessages[currentLang] ?? {};

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
