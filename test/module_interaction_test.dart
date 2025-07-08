import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/engine.dart';
import '../lib/core/state_manager.dart';
import '../lib/core/localization.dart';
import '../lib/modules/room.dart';
import '../lib/modules/outside.dart';
import '../lib/modules/path.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// 模块交互测试
/// 
/// 测试覆盖范围：
/// 1. Room和Outside模块交互
/// 2. Outside和Path模块交互
/// 3. 资源在模块间的流动
/// 4. 状态变化的传播
/// 5. 模块间的依赖关系
void main() {
  group('🔗 模块交互测试', () {
    late Engine engine;
    late StateManager stateManager;
    late Localization localization;
    late Room room;
    late Outside outside;
    late Path path;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始模块交互测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      engine = Engine();
      stateManager = StateManager();
      localization = Localization();
      
      // 初始化系统
      await engine.init();
      await localization.init();
      stateManager.init();
      
      // 创建模块实例
      room = Room();
      outside = Outside();
      path = Path();
    });

    tearDown() {
      engine.dispose();
      localization.dispose();
    }

    group('🏠➡️🌲 Room-Outside 模块交互', () {
      test('应该正确处理从房间到外部的资源传递', () async {
        Logger.info('🧪 测试房间到外部的资源传递');

        // 在房间中收集木材
        stateManager.set('stores.wood', 50);
        
        // 切换到外部模块
        engine.activeModule = outside;
        
        // 验证外部模块能访问房间收集的木材
        final woodInOutside = stateManager.get('stores.wood', true) ?? 0;
        expect(woodInOutside, equals(50));
        
        // 在外部使用木材建造陷阱
        stateManager.add('stores.wood', -10);
        stateManager.add('game.buildings.trap', 1);
        
        // 切换回房间
        engine.activeModule = room;
        
        // 验证房间能看到资源变化
        final remainingWood = stateManager.get('stores.wood', true) ?? 0;
        expect(remainingWood, equals(40));
        
        Logger.info('✅ 房间到外部资源传递测试通过');
      });

      test('应该正确处理外部世界解锁条件', () async {
        Logger.info('🧪 测试外部世界解锁条件');

        // 初始状态：外部世界未解锁
        expect(stateManager.get('features.location.outside'), isNull);
        
        // 在房间中达到解锁条件（通常是建造足够的建筑）
        stateManager.set('game.buildings.cart', 1);
        stateManager.set('features.location.outside', true);
        
        // 验证外部世界已解锁
        expect(stateManager.get('features.location.outside'), isTrue);
        
        // 验证可以切换到外部模块
        engine.activeModule = outside;
        expect(engine.activeModule, isA<Outside>());
        
        Logger.info('✅ 外部世界解锁条件测试通过');
      });

      test('应该正确处理人口和建筑的关联', () async {
        Logger.info('🧪 测试人口和建筑关联');

        // 在房间中增加人口
        stateManager.set('game.population', 5);
        
        // 在外部建造小屋
        stateManager.set('game.buildings.hut', 3);
        
        // 切换模块验证状态同步
        engine.activeModule = outside;
        expect(stateManager.get('game.population', true), equals(5));
        expect(stateManager.get('game.buildings.hut', true), equals(3));
        
        engine.activeModule = room;
        expect(stateManager.get('game.population', true), equals(5));
        expect(stateManager.get('game.buildings.hut', true), equals(3));
        
        Logger.info('✅ 人口和建筑关联测试通过');
      });
    });

    group('🌲➡️🗺️ Outside-Path 模块交互', () {
      test('应该正确处理指南针制作和路径解锁', () async {
        Logger.info('🧪 测试指南针制作和路径解锁');

        // 在外部收集制作指南针的材料
        stateManager.set('stores.fur', 400);
        stateManager.set('stores.scales', 20);
        stateManager.set('stores.teeth', 10);
        stateManager.set('game.buildings["trading post"]', 1);
        
        // 制作指南针
        stateManager.set('stores.compass', 1);
        stateManager.add('stores.fur', -400);
        stateManager.add('stores.scales', -20);
        stateManager.add('stores.teeth', -10);
        
        // 验证路径模块可以访问
        engine.activeModule = path;
        expect(stateManager.get('stores.compass', true), equals(1));
        
        // 验证材料被正确消耗
        expect(stateManager.get('stores.fur', true), equals(0));
        expect(stateManager.get('stores.scales', true), equals(0));
        expect(stateManager.get('stores.teeth', true), equals(0));
        
        Logger.info('✅ 指南针制作和路径解锁测试通过');
      });

      test('应该正确处理装备管理', () async {
        Logger.info('🧪 测试装备管理');

        // 在外部收集装备物品
        stateManager.set('stores["cured meat"]', 10);
        stateManager.set('stores.water', 5);
        stateManager.set('stores["bone spear"]', 2);
        
        // 切换到路径模块
        engine.activeModule = path;
        
        // 验证装备可用
        expect(stateManager.get('stores["cured meat"]', true), equals(10));
        expect(stateManager.get('stores.water', true), equals(5));
        expect(stateManager.get('stores["bone spear"]', true), equals(2));
        
        // 模拟装备到背包
        stateManager.set('path.outfit["cured meat"]', 5);
        stateManager.add('stores["cured meat"]', -5);
        
        // 验证装备状态
        expect(stateManager.get('path.outfit["cured meat"]', true), equals(5));
        expect(stateManager.get('stores["cured meat"]', true), equals(5));
        
        Logger.info('✅ 装备管理测试通过');
      });
    });

    group('🔄 多模块状态同步', () {
      test('应该正确处理三个模块间的状态同步', () async {
        Logger.info('🧪 测试三模块状态同步');

        // 在房间设置初始状态
        engine.activeModule = room;
        stateManager.set('stores.wood', 100);
        stateManager.set('game.fire.value', 4);
        
        // 切换到外部，验证状态同步
        engine.activeModule = outside;
        expect(stateManager.get('stores.wood', true), equals(100));
        expect(stateManager.get('game.fire.value', true), equals(4));
        
        // 在外部修改状态
        stateManager.add('stores.wood', -20);
        stateManager.set('stores.fur', 50);
        
        // 切换到路径，验证状态同步
        engine.activeModule = path;
        expect(stateManager.get('stores.wood', true), equals(80));
        expect(stateManager.get('stores.fur', true), equals(50));
        
        // 在路径修改状态
        stateManager.set('stores.compass', 1);
        
        // 切换回房间，验证所有变化都同步
        engine.activeModule = room;
        expect(stateManager.get('stores.wood', true), equals(80));
        expect(stateManager.get('stores.fur', true), equals(50));
        expect(stateManager.get('stores.compass', true), equals(1));
        
        Logger.info('✅ 三模块状态同步测试通过');
      });

      test('应该正确处理模块特定状态', () async {
        Logger.info('🧪 测试模块特定状态');

        // 房间特定状态
        engine.activeModule = room;
        stateManager.set('game.fire.value', 3);
        stateManager.set('game.temperature.value', 2);
        
        // 外部特定状态
        engine.activeModule = outside;
        stateManager.set('game.buildings.trap', 5);
        stateManager.set('game.buildings.hut', 3);
        
        // 路径特定状态
        engine.activeModule = path;
        stateManager.set('path.outfit["cured meat"]', 10);
        stateManager.set('path.outfit.water', 5);
        
        // 验证每个模块都能访问所有状态
        engine.activeModule = room;
        expect(stateManager.get('game.buildings.trap', true), equals(5));
        expect(stateManager.get('path.outfit["cured meat"]', true), equals(10));
        
        engine.activeModule = outside;
        expect(stateManager.get('game.fire.value', true), equals(3));
        expect(stateManager.get('path.outfit.water', true), equals(5));
        
        engine.activeModule = path;
        expect(stateManager.get('game.temperature.value', true), equals(2));
        expect(stateManager.get('game.buildings.hut', true), equals(3));
        
        Logger.info('✅ 模块特定状态测试通过');
      });
    });

    group('⚡ 性能和一致性测试', () {
      test('应该正确处理频繁的模块切换', () async {
        Logger.info('🧪 测试频繁模块切换');

        final modules = [room, outside, path];
        
        // 执行大量模块切换
        for (int i = 0; i < 50; i++) {
          final module = modules[i % modules.length];
          engine.activeModule = module;
          
          // 在每次切换时修改状态
          stateManager.add('stores.wood', 1);
          
          // 验证模块切换成功
          expect(engine.activeModule.runtimeType, equals(module.runtimeType));
        }

        // 验证最终状态正确
        expect(stateManager.get('stores.wood', true), equals(50));
        
        Logger.info('✅ 频繁模块切换测试通过');
      });

      test('应该正确处理并发状态修改', () async {
        Logger.info('🧪 测试并发状态修改');

        // 模拟多个模块同时修改状态
        final futures = <Future>[];
        
        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            final module = [room, outside, path][i % 3];
            engine.activeModule = module;
            stateManager.add('stores.wood', 1);
            stateManager.add('stores.fur', 1);
          }));
        }

        await Future.wait(futures);

        // 验证最终状态一致
        expect(stateManager.get('stores.wood', true), equals(10));
        expect(stateManager.get('stores.fur', true), equals(10));
        
        Logger.info('✅ 并发状态修改测试通过');
      });
    });

    group('🎯 游戏逻辑验证', () {
      test('应该正确处理游戏进度依赖', () async {
        Logger.info('🧪 测试游戏进度依赖');

        // 模拟正常的游戏进度
        // 1. 房间阶段
        engine.activeModule = room;
        stateManager.set('stores.wood', 50);
        stateManager.set('game.fire.value', 4);
        stateManager.set('game.buildings.cart', 1);
        
        // 2. 解锁外部
        stateManager.set('features.location.outside', true);
        engine.activeModule = outside;
        
        // 3. 外部发展
        stateManager.set('game.buildings.hut', 5);
        stateManager.set('stores.fur', 400);
        stateManager.set('stores.scales', 20);
        stateManager.set('stores.teeth', 10);
        stateManager.set('game.buildings["trading post"]', 1);
        
        // 4. 制作指南针，解锁路径
        stateManager.set('stores.compass', 1);
        engine.activeModule = path;
        
        // 验证整个进度链条
        expect(stateManager.get('features.location.outside'), isTrue);
        expect(stateManager.get('stores.compass', true), equals(1));
        expect(engine.activeModule, isA<Path>());
        
        Logger.info('✅ 游戏进度依赖测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 模块交互测试套件完成');
    });
  });
}
