import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/notifications.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// NotificationManager 通知系统测试
///
/// 测试覆盖范围：
/// 1. 通知系统初始化
/// 2. 通知添加和管理
/// 3. 通知队列处理
/// 4. 通知本地化
/// 5. 通知历史管理
void main() {
  group('📢 NotificationManager 通知系统测试', () {
    late NotificationManager notificationManager;
    late Localization localization;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 NotificationManager 测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notificationManager = NotificationManager();
      localization = Localization();

      // 设置mock本地化
      const String mockTranslationJson = '''
      {
        "notifications": {
          "wood_gathered": "收集了木材",
          "fire_lit": "火焰点燃了",
          "stranger_arrives": "一个陌生人到达了村庄"
        },
        "ui": {
          "test_message": "测试消息"
        }
      }
      ''';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/lang/zh.json') {
          return utf8.encode(mockTranslationJson).buffer.asByteData();
        }
        return null;
      });

      await localization.init();
      notificationManager.init();
    });

    tearDown(() {
      // 不要dispose单例对象，只清理状态
      notificationManager.clearAll();
    });

    group('🔧 通知系统初始化测试', () {
      test('应该正确初始化通知系统', () {
        Logger.info('🧪 测试通知系统初始化');

        // 验证初始化状态
        expect(notificationManager.getAllNotifications(), isEmpty);
        expect(notificationManager.getNotificationsForModule('room'), isEmpty);
        expect(
            notificationManager.getNotificationsForModule('outside'), isEmpty);

        Logger.info('✅ 通知系统初始化测试通过');
      });

      test('应该正确清理之前的通知', () {
        Logger.info('🧪 测试通知清理');

        // 添加一些通知
        notificationManager.notify('room', 'test message 1');
        notificationManager.notify('outside', 'test message 2');

        // 重新初始化
        notificationManager.init();

        // 验证通知被清理
        expect(notificationManager.getAllNotifications(), isEmpty);
        expect(notificationManager.getNotificationsForModule('room'), isEmpty);
        expect(
            notificationManager.getNotificationsForModule('outside'), isEmpty);

        Logger.info('✅ 通知清理测试通过');
      });
    });

    group('📝 通知添加和管理测试', () {
      test('应该正确添加通知到队列', () {
        Logger.info('🧪 测试通知添加');

        // 添加通知
        notificationManager.notify('room', 'wood_gathered');
        notificationManager.notify('room', 'fire_lit');
        notificationManager.notify('outside', 'stranger_arrives');

        // 验证通知被添加
        expect(notificationManager.getAllNotifications().length, equals(3));
        expect(notificationManager.getNotificationsForModule('room').length,
            equals(2));
        expect(notificationManager.getNotificationsForModule('outside').length,
            equals(1));

        // 验证通知内容
        final roomQueue = notificationManager.getNotificationsForModule('room');
        expect(roomQueue[0].message, equals('收集了木材'));
        expect(roomQueue[1].message, equals('火焰点燃了'));

        final outsideQueue =
            notificationManager.getNotificationsForModule('outside');
        expect(outsideQueue[0].message, equals('一个陌生人到达了村庄')); // 已本地化

        Logger.info('✅ 通知添加测试通过');
      });

      test('应该正确处理noQueue标志', () {
        Logger.info('🧪 测试noQueue标志处理');

        // 添加普通通知
        notificationManager.notify('room', 'wood_gathered');

        // 添加noQueue通知
        notificationManager.notify('room', 'fire_lit', noQueue: true);

        // 验证队列状态
        expect(notificationManager.getAllNotifications().length, equals(2));
        expect(notificationManager.getNotificationsForModule('room').length,
            equals(1)); // 只有一个在队列中

        // 验证noQueue通知不在模块队列中
        final roomQueue = notificationManager.getNotificationsForModule('room');
        expect(roomQueue[0].message, equals('收集了木材'));

        Logger.info('✅ noQueue标志处理测试通过');
      });

      test('应该正确限制通知历史数量', () {
        Logger.info('🧪 测试通知历史数量限制');

        // 添加超过最大数量的通知
        for (int i = 0; i < 150; i++) {
          notificationManager.notify('room', 'test_message', noQueue: true);
        }

        // 验证通知数量被限制
        expect(notificationManager.getAllNotifications().length,
            equals(100)); // 最大100个

        Logger.info('✅ 通知历史数量限制测试通过');
      });
    });

    group('🌐 通知本地化测试', () {
      test('应该正确本地化通知消息', () {
        Logger.info('🧪 测试通知本地化');

        // 添加需要本地化的通知
        notificationManager.notify('room', 'wood_gathered');
        notificationManager.notify('room', 'fire_lit');

        // 验证消息被正确本地化
        final roomQueue = notificationManager.getNotificationsForModule('room');
        expect(roomQueue[0].message, equals('收集了木材'));
        expect(roomQueue[1].message, equals('火焰点燃了'));

        Logger.info('✅ 通知本地化测试通过');
      });

      test('应该正确处理未翻译的消息', () {
        Logger.info('🧪 测试未翻译消息处理');

        // 添加未翻译的消息
        notificationManager.notify('room', 'untranslated_message');

        // 验证原始消息被保留
        final roomQueue = notificationManager.getNotificationsForModule('room');
        expect(roomQueue[0].message, equals('untranslated_message'));

        Logger.info('✅ 未翻译消息处理测试通过');
      });

      test('应该正确处理复杂本地化键', () {
        Logger.info('🧪 测试复杂本地化键处理');

        // 添加带前缀的本地化键
        notificationManager.notify('room', 'notifications.wood_gathered');
        notificationManager.notify('room', 'ui.test_message');

        // 验证消息被正确本地化
        final roomQueue = notificationManager.getNotificationsForModule('room');
        expect(roomQueue[0].message, equals('收集了木材'));
        expect(roomQueue[1].message, equals('测试消息'));

        Logger.info('✅ 复杂本地化键处理测试通过');
      });
    });

    group('📋 通知队列管理测试', () {
      setUp(() {
        // 为每个测试添加一些通知
        notificationManager.notify('room', 'wood_gathered');
        notificationManager.notify('room', 'fire_lit');
        notificationManager.notify('outside', 'stranger_arrives');
      });

      test('应该正确获取模块队列', () {
        Logger.info('🧪 测试模块队列获取');

        // 获取队列
        final roomQueue = notificationManager.getNotificationsForModule('room');
        final outsideQueue =
            notificationManager.getNotificationsForModule('outside');
        final emptyQueue =
            notificationManager.getNotificationsForModule('nonexistent');

        // 验证队列内容
        expect(roomQueue.length, equals(2));
        expect(outsideQueue.length, equals(1));
        expect(emptyQueue.length, equals(0));

        Logger.info('✅ 模块队列获取测试通过');
      });

      test('应该正确打印队列', () {
        Logger.info('🧪 测试队列打印');

        // 打印队列
        notificationManager.printQueue('room');

        // 验证队列被清空
        expect(notificationManager.getNotificationsForModule('room'), isEmpty);

        // 验证其他队列不受影响
        expect(notificationManager.getNotificationsForModule('outside').length,
            equals(1));

        Logger.info('✅ 队列打印测试通过');
      });

      test('应该正确清空队列', () {
        Logger.info('🧪 测试队列清空');

        // 清空特定模块队列
        notificationManager.clearQueue('room');

        // 验证队列被清空
        expect(notificationManager.getNotificationsForModule('room'), isEmpty);

        // 验证其他队列不受影响
        expect(notificationManager.getNotificationsForModule('outside').length,
            equals(1));

        Logger.info('✅ 队列清空测试通过');
      });

      test('应该正确处理空队列操作', () {
        Logger.info('🧪 测试空队列操作');

        // 对空队列执行操作
        notificationManager.printQueue('empty_module');
        notificationManager.clearQueue('empty_module');

        // 验证不会崩溃
        expect(notificationManager.getNotificationsForModule('empty_module'),
            isEmpty);

        Logger.info('✅ 空队列操作测试通过');
      });
    });

    group('📊 通知历史管理测试', () {
      test('应该正确维护通知历史', () {
        Logger.info('🧪 测试通知历史维护');

        // 添加通知
        notificationManager.notify('room', 'wood_gathered');
        notificationManager.notify('outside', 'stranger_arrives');

        // 验证历史记录
        final allNotifications = notificationManager.getAllNotifications();
        expect(allNotifications.length, equals(2));
        expect(allNotifications[0].message, equals('一个陌生人到达了村庄')); // 最新的在前
        expect(allNotifications[1].message, equals('收集了木材'));

        Logger.info('✅ 通知历史维护测试通过');
      });

      test('应该正确处理通知时间戳', () {
        Logger.info('🧪 测试通知时间戳');

        final beforeTime = DateTime.now();

        // 添加通知
        notificationManager.notify('room', 'wood_gathered');

        final afterTime = DateTime.now();

        // 验证时间戳
        final notification = notificationManager.getAllNotifications().first;
        expect(
            notification.time.isAfter(beforeTime) ||
                notification.time.isAtSameMomentAs(beforeTime),
            isTrue);
        expect(
            notification.time.isBefore(afterTime) ||
                notification.time.isAtSameMomentAs(afterTime),
            isTrue);

        Logger.info('✅ 通知时间戳测试通过');
      });

      test('应该正确获取最近通知', () {
        Logger.info('🧪 测试最近通知获取');

        // 添加多个通知
        notificationManager.notify('room', 'wood_gathered');
        notificationManager.notify('room', 'fire_lit');
        notificationManager.notify('outside', 'stranger_arrives');

        // 获取所有通知（已按时间倒序排列）
        final allNotifications = notificationManager.getAllNotifications();

        // 验证获取到正确数量的通知
        expect(allNotifications.length, equals(3));
        expect(allNotifications[0].message, equals('一个陌生人到达了村庄')); // 最新的
        expect(allNotifications[1].message, equals('火焰点燃了')); // 第二新的
        expect(allNotifications[2].message, equals('收集了木材')); // 最旧的

        Logger.info('✅ 最近通知获取测试通过');
      });
    });

    group('🔄 通知状态管理测试', () {
      test('应该正确处理通知状态变化', () {
        Logger.info('🧪 测试通知状态变化');

        bool notified = false;

        // 监听通知变化
        notificationManager.addListener(() {
          notified = true;
        });

        // 添加通知
        notificationManager.notify('room', 'wood_gathered');

        // 验证监听器被触发
        expect(notified, isTrue);

        Logger.info('✅ 通知状态变化测试通过');
      });

      test('应该正确处理批量通知', () {
        Logger.info('🧪 测试批量通知处理');

        // 批量添加通知
        final messages = ['wood_gathered', 'fire_lit', 'stranger_arrives'];
        for (final message in messages) {
          notificationManager.notify('room', message);
        }

        // 验证所有通知被正确添加
        expect(notificationManager.getNotificationsForModule('room').length,
            equals(3));
        expect(notificationManager.getAllNotifications().length, equals(3));

        Logger.info('✅ 批量通知处理测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 NotificationManager 测试套件完成');
      // 清理mock消息处理器
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });
  });
}
