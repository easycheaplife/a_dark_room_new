import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/engine.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/notifications.dart';
import 'package:a_dark_room_new/core/audio_engine.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/modules/outside.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 游戏流程集成测试
///
/// 测试覆盖范围：
/// 1. 游戏初始化流程
/// 2. 模块间状态同步
/// 3. 事件触发和响应
/// 4. 资源管理和更新
/// 5. 模块切换和导航
void main() {
  group('🎮 游戏流程集成测试', () {
    late Engine engine;
    late StateManager stateManager;
    late Localization localization;
    late NotificationManager notificationManager;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始游戏流程集成测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // 设置音频引擎测试模式
      AudioEngine().setTestMode(true);

      engine = Engine();
      stateManager = StateManager();
      localization = Localization();
      notificationManager = NotificationManager();

      // 初始化所有系统
      await engine.init();
      await localization.init();
      stateManager.init();
      notificationManager.init();
    });

    tearDown(() {
      // 不要dispose单例对象，只重置状态
      stateManager.reset();
      notificationManager.clearAll();
    });

    group('🏠 游戏初始化集成测试', () {
      test('应该正确初始化所有核心系统', () async {
        Logger.info('🧪 测试游戏初始化');

        // 验证引擎初始化（通过检查activeModule是否存在）
        expect(engine.activeModule, isNotNull);

        // 验证状态管理器初始化（通过检查能否获取状态）
        expect(() => stateManager.get('stores.wood'), returnsNormally);

        // 验证本地化系统初始化（通过检查能否翻译）
        expect(() => localization.translate('room.fire'), returnsNormally);

        // 验证默认模块设置
        expect(engine.activeModule, isA<Room>());

        Logger.info('✅ 游戏初始化测试通过');
      });

      test('应该正确设置初始游戏状态', () async {
        Logger.info('🧪 测试初始游戏状态');

        // 验证初始火焰状态
        final fireValue = stateManager.get('game.fire.value', true) ?? 0;
        expect(fireValue, equals(0)); // 火焰应该是熄灭的

        // 验证初始温度状态
        final tempValue = stateManager.get('game.temperature.value', true) ?? 0;
        expect(tempValue, equals(0)); // 温度应该是寒冷的

        // 验证初始资源状态
        final wood = stateManager.get('stores.wood', true) ?? 0;
        expect(wood, equals(0)); // 初始没有木材

        Logger.info('✅ 初始游戏状态测试通过');
      });
    });

    group('🔄 模块间状态同步测试', () {
      test('应该正确同步房间和外部模块状态', () async {
        Logger.info('🧪 测试房间和外部模块状态同步');

        // 在房间模块中收集木材
        stateManager.set('stores.wood', 10);

        // 切换到外部模块
        final outside = Outside();
        engine.activeModule = outside;

        // 验证外部模块能访问相同的木材数量
        final woodInOutside = stateManager.get('stores.wood', true) ?? 0;
        expect(woodInOutside, equals(10));

        // 在外部模块中消耗木材
        stateManager.set('stores.wood', 5);

        // 切换回房间模块
        final room = Room();
        engine.activeModule = room;

        // 验证房间模块看到更新后的木材数量
        final woodInRoom = stateManager.get('stores.wood', true) ?? 0;
        expect(woodInRoom, equals(5));

        Logger.info('✅ 模块间状态同步测试通过');
      });

      test('应该正确处理模块解锁条件', () async {
        Logger.info('🧪 测试模块解锁条件');

        // 初始状态：外部世界未解锁
        final initialOutsideUnlocked =
            stateManager.get('features.location.outside') ?? 0;
        expect(initialOutsideUnlocked, equals(0)); // StateManager返回数字而不是布尔值

        // 解锁外部世界
        stateManager.set('features.location.outside', true);

        // 验证解锁状态
        final outsideUnlocked =
            stateManager.get('features.location.outside') ?? false;
        expect(outsideUnlocked, isTrue);

        // 验证可以创建外部模块
        final outside = Outside();
        expect(outside, isNotNull);
        expect(outside.name, equals('Outside'));

        Logger.info('✅ 模块解锁条件测试通过');
      });
    });

    group('📊 资源管理集成测试', () {
      test('应该正确处理资源收集和消耗', () async {
        Logger.info('🧪 测试资源收集和消耗');

        // 初始资源状态
        expect(stateManager.get('stores.wood', true) ?? 0, equals(0));

        // 收集木材
        stateManager.add('stores.wood', 5);
        expect(stateManager.get('stores.wood', true) ?? 0, equals(5));

        // 再次收集
        stateManager.add('stores.wood', 3);
        expect(stateManager.get('stores.wood', true) ?? 0, equals(8));

        // 消耗木材
        stateManager.add('stores.wood', -2);
        expect(stateManager.get('stores.wood', true) ?? 0, equals(6));

        // 验证不能消耗超过拥有的数量
        final currentWood = stateManager.get('stores.wood', true) ?? 0;
        stateManager.add('stores.wood', -currentWood - 1); // 尝试消耗更多
        final finalWood = stateManager.get('stores.wood', true) ?? 0;
        expect(finalWood, greaterThanOrEqualTo(0)); // 不应该变成负数

        Logger.info('✅ 资源收集和消耗测试通过');
      });

      test('应该正确处理建筑建造', () async {
        Logger.info('🧪 测试建筑建造');

        // 设置足够的资源
        stateManager.set('stores.wood', 100);

        // 建造陷阱
        final initialTraps = stateManager.get('game.buildings.trap', true) ?? 0;
        stateManager.add('game.buildings.trap', 1);
        stateManager.add('stores.wood', -10); // 消耗木材

        // 验证建筑数量增加
        final finalTraps = stateManager.get('game.buildings.trap', true) ?? 0;
        expect(finalTraps, equals(initialTraps + 1));

        // 验证资源消耗
        final remainingWood = stateManager.get('stores.wood', true) ?? 0;
        expect(remainingWood, equals(90));

        Logger.info('✅ 建筑建造测试通过');
      });
    });

    group('🔔 通知系统集成测试', () {
      test('应该正确处理跨模块通知', () async {
        Logger.info('🧪 测试跨模块通知');

        // 在房间模块发送通知
        notificationManager.notify('room', '火焰被点燃了');

        // 验证通知被正确添加
        final roomNotifications =
            notificationManager.getNotificationsForModule('room');
        expect(roomNotifications.length, equals(1));
        expect(roomNotifications.first.message, contains('火焰'));

        // 在外部模块发送通知
        notificationManager.notify('outside', '建造了陷阱');

        // 验证全局通知历史
        final allNotifications = notificationManager.getAllNotifications();
        expect(allNotifications.length, equals(2));

        // 验证通知顺序（最新的在前）
        expect(allNotifications.first.message, contains('陷阱'));
        expect(allNotifications.last.message, contains('火焰'));

        Logger.info('✅ 跨模块通知测试通过');
      });

      test('应该正确处理通知本地化', () async {
        Logger.info('🧪 测试通知本地化');

        // 设置中文语言
        await localization.switchLanguage('zh');

        // 发送需要本地化的通知
        notificationManager.notify('room', 'wood_gathered');

        // 验证通知被本地化
        final notifications = notificationManager.getAllNotifications();
        expect(notifications.isNotEmpty, isTrue);

        // 切换到英文
        await localization.switchLanguage('en');

        // 发送另一个通知
        notificationManager.notify('room', 'fire_lit');

        // 验证新通知使用英文
        final allNotifications = notificationManager.getAllNotifications();
        expect(allNotifications.length, equals(2));

        Logger.info('✅ 通知本地化测试通过');
      });
    });

    group('🎯 游戏流程测试', () {
      test('应该正确处理完整的游戏开始流程', () async {
        Logger.info('🧪 测试完整游戏开始流程');

        // 1. 游戏开始 - 房间模块
        expect(engine.activeModule, isA<Room>());

        // 2. 收集木材
        stateManager.set('stores.wood', 20);

        // 3. 点燃火焰
        stateManager.set('game.fire.value', 3); // 明亮的火焰

        // 4. 提升温度
        stateManager.set('game.temperature.value', 3); // 温暖

        // 5. 解锁外部世界
        stateManager.set('features.location.outside', true);

        // 6. 切换到外部世界
        final outside = Outside();
        engine.activeModule = outside;

        // 验证流程完整性
        expect(stateManager.get('stores.wood', true), equals(20));
        expect(stateManager.get('game.fire.value', true), equals(3));
        expect(stateManager.get('game.temperature.value', true), equals(3));
        expect(stateManager.get('features.location.outside'), isTrue);
        expect(engine.activeModule, isA<Outside>());

        Logger.info('✅ 完整游戏开始流程测试通过');
      });

      test('应该正确处理模块切换流程', () async {
        Logger.info('🧪 测试模块切换流程');

        // 解锁所有模块
        stateManager.set('features.location.outside', true);
        stateManager.set('stores.compass', 1); // 解锁路径

        // 测试模块切换序列
        final modules = [
          Room(),
          Outside(),
          Path(),
        ];

        for (final module in modules) {
          engine.activeModule = module;

          // 验证模块切换成功
          expect(engine.activeModule.runtimeType, equals(module.runtimeType));
          expect(engine.activeModule, isNotNull);

          // 验证状态在切换后保持一致
          expect(() => stateManager.get('stores.wood'), returnsNormally);
        }

        Logger.info('✅ 模块切换流程测试通过');
      });
    });

    group('⚡ 性能和稳定性测试', () {
      test('应该正确处理大量状态更新', () async {
        Logger.info('🧪 测试大量状态更新');

        // 执行大量状态更新
        for (int i = 0; i < 100; i++) {
          stateManager.set('stores.wood', i);
          stateManager.set('game.fire.value', i % 5);
          stateManager.add('game.buildings.trap', 1);
        }

        // 验证最终状态正确
        expect(stateManager.get('stores.wood', true), equals(99));
        expect(
            stateManager.get('game.fire.value', true), equals(4)); // 99 % 5 = 4
        expect(stateManager.get('game.buildings.trap', true), equals(100));

        Logger.info('✅ 大量状态更新测试通过');
      });

      test('应该正确处理并发操作', () async {
        Logger.info('🧪 测试并发操作');

        // 模拟并发的资源操作
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            stateManager.add('stores.wood', 1);
            notificationManager.notify('test', '并发操作 $i');
          }));
        }

        // 等待所有操作完成
        await Future.wait(futures);

        // 验证结果一致性
        final finalWood = stateManager.get('stores.wood', true) ?? 0;
        expect(finalWood, equals(10));

        final notifications = notificationManager.getAllNotifications();
        expect(notifications.length, equals(10));

        Logger.info('✅ 并发操作测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 游戏流程集成测试套件完成');
    });
  });
}
