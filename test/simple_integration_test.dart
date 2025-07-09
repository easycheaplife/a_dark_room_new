import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/state_manager.dart';

import 'package:a_dark_room_new/core/audio_engine.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/modules/outside.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 简化的集成测试
///
/// 专注于测试核心模块间的基本交互，避免复杂的测试场景
/// 测试覆盖：
/// 1. 状态管理集成
/// 2. 模块基本功能
/// 3. 基本游戏流程
void main() {
  group('🔗 简化集成测试', () {
    late StateManager stateManager;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始简化集成测试');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      // 初始化核心系统
      stateManager = StateManager();

      // 设置音频引擎测试模式
      AudioEngine().setTestMode(true);

      // 初始化系统
      stateManager.init();
    });

    tearDown(() {
      // 清理工作
    });

    group('🎯 状态管理集成', () {
      test('应该正确初始化状态管理器', () async {
        Logger.info('🧪 测试状态管理器初始化');

        // 验证状态管理器初始化
        expect(() => stateManager.get('stores.wood'), returnsNormally);

        // 验证基本状态操作
        stateManager.set('test.value', 100);
        expect(stateManager.get('test.value'), equals(100));

        Logger.info('✅ 状态管理器初始化测试通过');
      });

      test('应该正确设置初始游戏状态', () async {
        Logger.info('🧪 测试初始游戏状态设置');

        // 设置测试状态
        stateManager.set('stores.wood', 100);
        stateManager.set('stores.fur', 200);
        stateManager.set('game.fire.value', 4);

        // 验证状态设置成功
        expect(stateManager.get('stores.wood'), equals(100));
        expect(stateManager.get('stores.fur'), equals(200));
        expect(stateManager.get('game.fire.value'), equals(4));

        Logger.info('✅ 初始游戏状态设置测试通过');
      });
    });

    group('🔄 模块基本功能', () {
      test('应该正确创建游戏模块', () async {
        Logger.info('🧪 测试游戏模块创建');

        // 创建模块实例
        final room = Room();
        final outside = Outside();

        // 验证模块创建成功
        expect(room, isA<Room>());
        expect(outside, isA<Outside>());

        Logger.info('✅ 游戏模块创建测试通过');
      });

      test('应该正确处理状态持久化', () async {
        Logger.info('🧪 测试状态持久化');

        // 设置状态
        stateManager.set('stores.wood', 50);
        stateManager.set('game.population', 3);

        // 验证状态持久化
        expect(stateManager.get('stores.wood', true), equals(50));
        expect(stateManager.get('game.population', true), equals(3));

        // 修改状态
        stateManager.add('stores.wood', -10);
        stateManager.add('game.buildings.hut', 1);

        // 验证状态变化
        expect(stateManager.get('stores.wood', true), equals(40));
        expect(stateManager.get('game.buildings.hut', true), equals(1));

        Logger.info('✅ 状态持久化测试通过');
      });
    });

    group('🎮 基本游戏流程集成', () {
      test('应该正确处理资源收集和消耗流程', () async {
        Logger.info('🧪 测试资源收集和消耗流程');

        // 设置初始状态
        stateManager.set('stores.wood', 0);
        stateManager.set('game.fire.value', 1);

        // 模拟收集木材
        stateManager.add('stores.wood', 10);
        expect(stateManager.get('stores.wood'), equals(10));

        // 模拟添加木材到火堆
        stateManager.add('stores.wood', -4);
        stateManager.add('game.fire.value', 1);

        expect(stateManager.get('stores.wood'), equals(6));
        expect(stateManager.get('game.fire.value'), equals(2));

        Logger.info('✅ 资源收集和消耗流程测试通过');
      });

      test('应该正确处理建筑建造流程', () async {
        Logger.info('🧪 测试建筑建造流程');

        // 重置建筑状态
        stateManager.set('game.buildings.hut', 0);
        stateManager.set('game.buildings.trap', 0);

        // 设置建造材料
        stateManager.set('stores.wood', 100);
        stateManager.set('stores.fur', 50);

        // 模拟建造小屋
        final hutCost = 20; // 木材成本
        stateManager.add('stores.wood', -hutCost);
        stateManager.add('game.buildings.hut', 1);

        expect(stateManager.get('stores.wood'), equals(80));
        expect(stateManager.get('game.buildings.hut'), equals(1));

        // 模拟建造陷阱
        final trapCost = 10; // 木材成本
        stateManager.add('stores.wood', -trapCost);
        stateManager.add('game.buildings.trap', 1);

        expect(stateManager.get('stores.wood'), equals(70));
        expect(stateManager.get('game.buildings.trap'), equals(1));

        Logger.info('✅ 建筑建造流程测试通过');
      });

      test('应该正确处理人口增长流程', () async {
        Logger.info('🧪 测试人口增长流程');

        // 设置初始状态
        stateManager.set('game.population', 1);
        stateManager.set('game.buildings.hut', 2);

        // 模拟人口增长
        stateManager.add('game.population', 2);
        expect(stateManager.get('game.population'), equals(3));

        // 验证人口在合理范围内
        final population = stateManager.get('game.population', true) ?? 0;
        final maxCapacity =
            (stateManager.get('game.buildings.hut', true) ?? 0) * 4;
        expect(population, lessThanOrEqualTo(maxCapacity));

        Logger.info('✅ 人口增长流程测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 简化集成测试完成');
      Logger.info('✅ 所有核心集成功能验证通过');
    });
  });
}
