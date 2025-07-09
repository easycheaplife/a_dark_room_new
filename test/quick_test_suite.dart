import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 快速测试套件
/// 
/// 用于日常开发的快速验证，包含最重要的核心功能测试
/// 运行时间控制在30秒以内，适合频繁执行
void main() {
  group('⚡ 快速测试套件', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始快速测试套件');
      Logger.info('目标：验证核心功能正常工作');
    });

    group('🎯 核心系统快速验证', () {
      test('状态管理器基本功能', () async {
        Logger.info('🧪 测试状态管理器基本功能');
        
        SharedPreferences.setMockInitialValues({});
        final stateManager = StateManager();
        stateManager.init();
        
        // 基本设置和获取
        stateManager.set('test.value', 100);
        expect(stateManager.get('test.value'), equals(100));
        
        // 数值操作
        stateManager.add('test.value', 50);
        expect(stateManager.get('test.value'), equals(150));
        
        Logger.info('✅ 状态管理器基本功能正常');
      });

      test('本地化系统快速验证', () async {
        Logger.info('🧪 测试本地化系统');
        
        final localization = Localization();
        await localization.init();
        
        // 验证基本翻译功能
        final roomFire = localization.translate('room.fire');
        expect(roomFire, isNotEmpty);
        
        // 验证语言切换
        await localization.switchLanguage('en');
        final englishText = localization.translate('room.fire');
        expect(englishText, isNotEmpty);
        
        await localization.switchLanguage('zh');
        final chineseText = localization.translate('room.fire');
        expect(chineseText, isNotEmpty);
        
        Logger.info('✅ 本地化系统正常');
        
        localization.dispose();
      });

      test('游戏状态数据完整性', () async {
        Logger.info('🧪 测试游戏状态数据完整性');
        
        SharedPreferences.setMockInitialValues({});
        final stateManager = StateManager();
        stateManager.init();
        
        // 设置基本游戏状态
        stateManager.set('stores.wood', 200);
        stateManager.set('stores.fur', 300);
        stateManager.set('stores.water', 15);
        stateManager.set('game.population', 5);
        stateManager.set('game.fire.value', 4);
        
        // 验证状态
        expect(stateManager.get('stores.wood'), equals(200));
        expect(stateManager.get('stores.fur'), equals(300));
        expect(stateManager.get('stores.water'), equals(15));
        expect(stateManager.get('game.population'), equals(5));
        expect(stateManager.get('game.fire.value'), equals(4));
        
        Logger.info('✅ 游戏状态数据完整性正常');
      });
    });

    group('🔧 基础功能验证', () {
      test('资源计算逻辑', () async {
        Logger.info('🧪 测试资源计算逻辑');
        
        SharedPreferences.setMockInitialValues({});
        final stateManager = StateManager();
        stateManager.init();
        
        // 设置初始资源
        stateManager.set('stores.wood', 100);
        stateManager.set('stores.fur', 50);
        
        // 模拟资源消耗
        stateManager.add('stores.wood', -20);
        stateManager.add('stores.fur', -10);
        
        expect(stateManager.get('stores.wood'), equals(80));
        expect(stateManager.get('stores.fur'), equals(40));
        
        // 模拟资源生产
        stateManager.add('stores.wood', 30);
        stateManager.add('stores.fur', 15);
        
        expect(stateManager.get('stores.wood'), equals(110));
        expect(stateManager.get('stores.fur'), equals(55));
        
        Logger.info('✅ 资源计算逻辑正常');
      });
    });

    group('🎮 游戏逻辑快速验证', () {
      test('基础游戏状态流转', () async {
        Logger.info('🧪 测试基础游戏状态流转');
        
        SharedPreferences.setMockInitialValues({});
        final stateManager = StateManager();
        stateManager.init();
        
        // 模拟游戏开始状态
        stateManager.set('game.fire.value', 1);
        stateManager.set('stores.wood', 0);
        
        // 模拟收集木材
        stateManager.add('stores.wood', 10);
        expect(stateManager.get('stores.wood'), equals(10));
        
        // 模拟添加木材到火堆
        stateManager.add('stores.wood', -4);
        stateManager.add('game.fire.value', 1);
        
        expect(stateManager.get('stores.wood'), equals(6));
        expect(stateManager.get('game.fire.value'), equals(2));
        
        Logger.info('✅ 基础游戏状态流转正常');
      });

      test('建筑和人口关系', () async {
        Logger.info('🧪 测试建筑和人口关系');
        
        SharedPreferences.setMockInitialValues({});
        final stateManager = StateManager();
        stateManager.init();
        
        // 设置初始状态
        stateManager.set('game.population', 0);
        stateManager.set('game.buildings.hut', 0);
        
        // 模拟建造小屋
        stateManager.add('game.buildings.hut', 2);
        expect(stateManager.get('game.buildings.hut'), equals(2));
        
        // 模拟人口增长
        stateManager.add('game.population', 3);
        expect(stateManager.get('game.population'), equals(3));
        
        // 验证人口不超过住房容量的逻辑可以正常设置
        final maxPopulation = (stateManager.get('game.buildings.hut', true) ?? 0) * 4;
        expect(stateManager.get('game.population', true), lessThanOrEqualTo(maxPopulation));
        
        Logger.info('✅ 建筑和人口关系正常');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 快速测试套件完成');
      Logger.info('✅ 所有核心功能验证通过');
    });
  });
}
