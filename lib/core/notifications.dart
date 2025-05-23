import 'package:flutter/foundation.dart';

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
    final notification = Notification(message, noQueue: noQueue);
    
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
