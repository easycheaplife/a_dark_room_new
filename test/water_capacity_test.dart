// Flutter测试文件，验证水容量显示修复
import 'package:flutter_test/flutter_test.dart';

// 导入项目文件
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/core/state_manager.dart';

void main() {
  group('水容量显示修复测试', () {
    late StateManager stateManager;
    late World world;

    setUp(() {
      // 初始化测试环境
      stateManager = StateManager();
      world = World.instance;

      // 清理状态
      stateManager.set('stores.waterskin', 0);
      stateManager.set('stores.cask', 0);
      stateManager.set('stores["water tank"]', 0);
      stateManager.set('stores["fluid recycler"]', 0);
    });

    test('基础水量测试', () {
      final baseWater = world.getMaxWater();
      expect(baseWater, equals(10), reason: '基础水量应该是10');
    });

    test('水壶升级测试', () {
      stateManager.set('stores.waterskin', 1);
      final waterskinWater = world.getMaxWater();
      expect(waterskinWater, equals(20), reason: '水壶水量应该是20');
    });

    test('水桶升级测试', () {
      stateManager.set('stores.waterskin', 0);
      stateManager.set('stores.cask', 1);
      final caskWater = world.getMaxWater();
      expect(caskWater, equals(30), reason: '水桶水量应该是30');
    });

    test('水罐升级测试', () {
      stateManager.set('stores.cask', 0);
      stateManager.set('stores["water tank"]', 1);
      final tankWater = world.getMaxWater();
      expect(tankWater, equals(60), reason: '水罐水量应该是60');
    });

    test('流体回收器升级测试', () {
      stateManager.set('stores["water tank"]', 0);
      stateManager.set('stores["fluid recycler"]', 1);
      final recyclerWater = world.getMaxWater();
      expect(recyclerWater, equals(110), reason: '流体回收器水量应该是110');
    });

    test('优先级测试 - 流体回收器优先于水罐', () {
      stateManager.set('stores["water tank"]', 1);
      stateManager.set('stores["fluid recycler"]', 1);
      final recyclerWater = world.getMaxWater();
      expect(recyclerWater, equals(110), reason: '有流体回收器时应该显示110，不是60');
    });

    test('优先级测试 - 水罐优先于水桶', () {
      stateManager.set('stores.cask', 1);
      stateManager.set('stores["water tank"]', 1);
      final tankWater = world.getMaxWater();
      expect(tankWater, equals(60), reason: '有水罐时应该显示60，不是30');
    });
  });
}
