import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// StateManager 核心状态管理系统测试
///
/// 测试覆盖范围：
/// 1. 状态初始化和管理
/// 2. 状态设置和获取
/// 3. 状态持久化和加载
/// 4. 收入计算和自动保存
/// 5. 状态迁移和验证
void main() {
  group('🎮 StateManager 核心状态管理测试', () {
    late StateManager stateManager;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 StateManager 测试套件');
    });

    setUp(() {
      // 每个测试前重置SharedPreferences
      SharedPreferences.setMockInitialValues({});
      stateManager = StateManager();
      // 注意：由于StateManager是单例，我们无法直接重置内部状态
      // 但可以通过重新初始化来测试
    });

    tearDown(() {
      // StateManager是单例，不需要dispose
    });

    group('📊 状态初始化测试', () {
      test('应该正确初始化新游戏状态', () {
        Logger.info('🧪 测试新游戏状态初始化');

        // 执行初始化
        stateManager.init();

        // 验证基础状态结构
        expect(stateManager.state, isNotEmpty);
        expect(stateManager.state['version'], equals(1.3));
        expect(stateManager.state['stores'], isA<Map>());
        expect(stateManager.state['stores']['wood'], equals(0));
        expect(stateManager.state['game'], isA<Map>());
        expect(stateManager.state['game']['fire'], isA<Map>());
        expect(stateManager.state['game']['fire']['value'], equals(0));
        expect(stateManager.state['features'], isA<Map>());
        expect(
            stateManager.state['features']['location']['room'], equals(true));

        Logger.info('✅ 新游戏状态初始化测试通过');
      });

      test('应该正确设置初始建筑和工人状态', () {
        Logger.info('🧪 测试初始建筑和工人状态');

        stateManager.init();

        // 验证建筑状态
        expect(stateManager.state['game']['buildings'], isA<Map>());
        expect(stateManager.state['game']['workers'], isA<Map>());
        expect(stateManager.state['game']['population'], equals(0));
        expect(stateManager.state['game']['thieves'], equals(false));
        expect(stateManager.state['game']['stokeCount'], equals(0));

        Logger.info('✅ 初始建筑和工人状态测试通过');
      });

      test('应该正确设置初始配置', () {
        Logger.info('🧪 测试初始配置设置');

        stateManager.init();

        // 验证配置状态
        expect(stateManager.state['config'], isA<Map>());
        expect(stateManager.state['config']['lightsOff'], equals(false));
        expect(stateManager.state['config']['hyperMode'], equals(false));
        expect(stateManager.state['config']['soundOn'], equals(true));

        Logger.info('✅ 初始配置设置测试通过');
      });
    });

    group('🔧 状态设置和获取测试', () {
      setUp(() {
        stateManager.init();
      });

      test('应该正确设置和获取简单路径', () {
        Logger.info('🧪 测试简单路径设置和获取');

        // 设置简单值
        stateManager.set('stores.wood', 100);
        stateManager.set('game.population', 5);

        // 验证获取
        expect(stateManager.get('stores.wood'), equals(100));
        expect(stateManager.get('game.population'), equals(5));

        Logger.info('✅ 简单路径设置和获取测试通过');
      });

      test('应该正确处理复杂嵌套路径', () {
        Logger.info('🧪 测试复杂嵌套路径');

        // 设置嵌套值
        stateManager.set('game.buildings.trap', 3);
        stateManager.set('game.workers["coal miner"]', 2);
        stateManager.set('character.perks["martial artist"]', true);

        // 验证获取
        expect(stateManager.get('game.buildings.trap'), equals(3));
        expect(stateManager.get('game.workers["coal miner"]'), equals(2));
        expect(stateManager.get('character.perks["martial artist"]'),
            equals(true));

        Logger.info('✅ 复杂嵌套路径测试通过');
      });

      test('应该正确处理数组表示法', () {
        Logger.info('🧪 测试数组表示法处理');

        // 设置数组表示法的值
        stateManager.set('stores["alien alloy"]', 50);
        stateManager.set('game.buildings["trading post"]', 1);

        // 验证获取
        expect(stateManager.get('stores["alien alloy"]'), equals(50));
        expect(stateManager.get('game.buildings["trading post"]'), equals(1));

        Logger.info('✅ 数组表示法处理测试通过');
      });

      test('应该正确处理默认值', () {
        Logger.info('🧪 测试默认值处理');

        // 测试不存在的路径
        expect(stateManager.get('nonexistent.path'), equals(0)); // 默认返回0
        expect(stateManager.get('nonexistent.path', true), isNull); // nullIfMissing=true返回null
        expect(stateManager.get('another.path', false), equals(0)); // nullIfMissing=false返回0

        Logger.info('✅ 默认值处理测试通过');
      });
    });

    group('➕ 状态修改操作测试', () {
      setUp(() {
        stateManager.init();
      });

      test('应该正确执行add操作', () {
        Logger.info('🧪 测试add操作');

        // 设置初始值
        stateManager.set('stores.wood', 10);
        stateManager.set('game.population', 5);

        // 执行add操作
        stateManager.add('stores.wood', 20);
        stateManager.add('game.population', 3);

        // 验证结果
        expect(stateManager.get('stores.wood'), equals(30));
        expect(stateManager.get('game.population'), equals(8));

        Logger.info('✅ add操作测试通过');
      });

      test('应该正确执行setM批量操作', () {
        Logger.info('🧪 测试setM批量操作');

        // 执行批量设置
        final modifications = {
          'wood': -10,
          'fur': -5,
          'meat': 15,
        };

        // 设置初始值
        stateManager.set('stores.wood', 20);
        stateManager.set('stores.fur', 10);
        stateManager.set('stores.meat', 0);

        // 执行批量修改
        stateManager.setM('stores', modifications);

        // 验证结果 - setM直接设置值，stores负值会被设为0
        expect(stateManager.get('stores.wood'), equals(0)); // 设置为-10，但stores不能为负，所以是0
        expect(stateManager.get('stores.fur'), equals(0)); // 设置为-5，但stores不能为负，所以是0
        expect(stateManager.get('stores.meat'), equals(15)); // 设置为15

        Logger.info('✅ setM批量操作测试通过');
      });

      test('应该正确处理负值和边界情况', () {
        Logger.info('🧪 测试负值和边界情况');

        // 设置初始值
        stateManager.set('stores.wood', 5);

        // 测试减法导致负值 - stores不能为负数，会被设为0
        stateManager.add('stores.wood', -10);
        expect(stateManager.get('stores.wood'), equals(0)); // 5 + (-10) = -5，但stores不能为负，所以是0

        // 测试零值
        stateManager.set('stores.fur', 0);
        stateManager.add('stores.fur', 0);
        expect(stateManager.get('stores.fur'), equals(0));

        Logger.info('✅ 负值和边界情况测试通过');
      });
    });

    group('💰 收入计算测试', () {
      setUp(() {
        stateManager.init();
      });

      test('应该正确计算和收集收入', () {
        Logger.info('🧪 测试收入计算和收集');

        // 设置收入源 - 使用正确的收入格式
        stateManager.setIncome('gatherer', {
          'timeLeft': 0,
          'stores': {'wood': 5}
        });
        stateManager.setIncome('trapper', {
          'timeLeft': 0,
          'stores': {'fur': 2}
        });
        stateManager.set('stores.wood', 10);
        stateManager.set('stores.fur', 3);

        // 收集收入
        stateManager.collectIncome();

        // 验证收入被正确添加
        expect(stateManager.get('stores.wood'), equals(15));
        expect(stateManager.get('stores.fur'), equals(5));

        Logger.info('✅ 收入计算和收集测试通过');
      });

      test('应该正确处理空收入', () {
        Logger.info('🧪 测试空收入处理');

        // 清理之前的收入设置
        stateManager.set('income', {});

        // 设置初始存储但无收入
        stateManager.set('stores.wood', 10);

        // 收集收入（无收入源）
        stateManager.collectIncome();

        // 验证存储未变化
        expect(stateManager.get('stores.wood'), equals(10));

        Logger.info('✅ 空收入处理测试通过');
      });
    });

    group('💾 状态持久化测试', () {
      test('应该正确保存游戏状态', () async {
        Logger.info('🧪 测试游戏状态保存');

        stateManager.init();

        // 修改一些状态
        stateManager.set('stores.wood', 100);
        stateManager.set('game.population', 10);
        stateManager.set('features.location.outside', true);

        // 保存游戏
        await stateManager.saveGame();

        // 验证保存成功（通过检查SharedPreferences）
        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('gameState');
        expect(savedData, isNotNull);
        expect(savedData, isNotEmpty);

        Logger.info('✅ 游戏状态保存测试通过');
      });

      test('应该正确加载游戏状态', () async {
        Logger.info('🧪 测试游戏状态加载');

        // 先保存一个状态
        stateManager.init();
        stateManager.set('stores.wood', 150);
        stateManager.set('game.population', 15);
        await stateManager.saveGame();

        // 创建新的StateManager实例并加载
        final newStateManager = StateManager();
        newStateManager.state.clear(); // 清空状态
        await newStateManager.loadGame();
        newStateManager.init();

        // 验证状态被正确加载
        expect(newStateManager.get('stores.wood'), equals(150));
        expect(newStateManager.get('game.population'), equals(15));

        Logger.info('✅ 游戏状态加载测试通过');
      });
    });

    group('🔄 状态迁移和验证测试', () {
      test('应该正确处理旧版本状态', () {
        Logger.info('🧪 测试旧版本状态处理');

        // 初始化状态管理器
        stateManager.init();

        // 设置一个旧版本号来触发更新
        stateManager.set('version', 1.2);
        stateManager.set('stores.wood', 50);

        // 调用状态更新
        stateManager.updateOldState();

        // 验证状态被正确更新
        expect(stateManager.get('version'), equals(1.3));
        expect(stateManager.get('stores.wood'), equals(50));

        Logger.info('✅ 旧版本状态处理测试通过');
      });

      test('应该正确验证必需字段', () {
        Logger.info('🧪 测试必需字段验证');

        // 初始化状态管理器（这会确保所有必需字段存在）
        stateManager.init();

        // 设置一些基本数据
        stateManager.set('stores.wood', 10);

        // 验证必需字段被添加
        expect(stateManager.state['game'], isA<Map>());
        expect(stateManager.state['features'], isA<Map>());
        expect(stateManager.state['config'], isA<Map>());
        expect(stateManager.state['stores'], isA<Map>());
        expect(stateManager.state['character'], isA<Map>());

        Logger.info('✅ 必需字段验证测试通过');
      });
    });

    group('⚡ 自动保存测试', () {
      test('应该正确启动自动保存', () {
        Logger.info('🧪 测试自动保存启动');

        stateManager.init();

        // 启动自动保存（验证不会崩溃）
        stateManager.startAutoSave();

        // 验证状态管理器仍然正常工作
        expect(stateManager.state, isNotEmpty);
        expect(stateManager.get('version'), equals(1.3));

        Logger.info('✅ 自动保存启动测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 StateManager 测试套件完成');
    });
  });
}
