import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/ship.dart';
import 'package:a_dark_room_new/modules/space.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';

void main() {
  group('飞船模块建造和升级系统测试', () {
    late Ship ship;
    late Space space;
    late StateManager stateManager;

    setUp(() {
      // 重置StateManager单例状态
      StateManager().reset();

      // 初始化测试环境
      stateManager = StateManager();
      ship = Ship();
      space = Space();

      // 初始化本地化
      Localization();

      // 设置初始状态
      stateManager.setM('stores', {
        'alien alloy': 10, // 足够的外星合金
      });

      // 重置飞船状态
      ship.reset();
    });

    test('飞船模块应该有正确的常量配置', () {
      expect(Ship.liftoffCooldown, equals(120));
      expect(Ship.alloyPerHull, equals(1));
      expect(Ship.alloyPerThruster, equals(1));
      expect(Ship.baseHull, equals(0));
      expect(Ship.baseThrusters, equals(1));
    });

    test('初始化飞船模块应该设置正确的状态', () {
      ship.init();

      final shipStatus = ship.getShipStatus();
      expect(shipStatus['hull'], equals(0));
      expect(shipStatus['thrusters'], equals(1));
      expect(shipStatus['canLiftOff'], isFalse); // 船体为0时不能起飞
      expect(shipStatus['canReinforceHull'], isTrue); // 有足够外星合金
      expect(shipStatus['canUpgradeEngine'], isTrue); // 有足够外星合金
    });

    test('强化船体功能应该正常工作', () {
      ship.init();

      // 强化船体前
      expect(ship.hull, equals(0));
      expect(ship.canLiftOff(), isFalse);

      // 强化船体
      ship.reinforceHull();

      // 强化船体后
      expect(ship.hull, equals(1));
      expect(ship.canLiftOff(), isTrue);

      // 检查外星合金消耗
      final alienAlloy = stateManager.get('stores["alien alloy"]', true) as int;
      expect(alienAlloy, equals(9)); // 10 - 1 = 9
    });

    test('升级引擎功能应该正常工作', () {
      ship.init();

      // 升级引擎前
      expect(ship.thrusters, equals(1));

      // 升级引擎
      ship.upgradeEngine();

      // 升级引擎后
      expect(ship.thrusters, equals(2));

      // 检查外星合金消耗
      final alienAlloy = stateManager.get('stores["alien alloy"]', true) as int;
      expect(alienAlloy, equals(9)); // 10 - 1 = 9
    });

    test('外星合金不足时应该无法建造', () {
      ship.init();

      // 设置外星合金不足
      stateManager.set('stores["alien alloy"]', 0);

      expect(ship.canReinforceHull(), isFalse);
      expect(ship.canUpgradeEngine(), isFalse);

      // 尝试强化船体应该失败
      final initialHull = ship.hull;
      ship.reinforceHull();
      expect(ship.hull, equals(initialHull)); // 船体不应该改变

      // 尝试升级引擎应该失败
      final initialThrusters = ship.thrusters;
      ship.upgradeEngine();
      expect(ship.thrusters, equals(initialThrusters)); // 引擎不应该改变
    });

    test('起飞冷却时间机制应该正常工作', () {
      ship.init();
      ship.reinforceHull(); // 确保可以起飞

      // 初始状态没有冷却
      expect(ship.isLiftoffOnCooldown, isFalse);
      expect(ship.getRemainingCooldown(), equals(0));
      expect(ship.canLiftOff(), isTrue);

      // 设置冷却时间
      ship.setLiftoffCooldown();

      // 冷却期间不能起飞
      expect(ship.isLiftoffOnCooldown, isTrue);
      expect(ship.getRemainingCooldown(), greaterThan(0));
      expect(ship.canLiftOff(), isFalse);

      // 清除冷却时间
      ship.clearLiftoffCooldown();

      // 清除后可以起飞
      expect(ship.isLiftoffOnCooldown, isFalse);
      expect(ship.getRemainingCooldown(), equals(0));
      expect(ship.canLiftOff(), isTrue);
    });

    test('太空模块坠毁应该设置起飞冷却时间', () {
      ship.init();
      space.init();
      ship.reinforceHull(); // 确保有船体

      // 模拟太空飞行
      space.onArrival();
      expect(space.hull, greaterThan(0));

      // 模拟坠毁
      space.hull = 0; // 设置船体为0
      space.crash();

      // 坠毁后应该有冷却时间
      expect(ship.isLiftoffOnCooldown, isTrue);
      expect(ship.canLiftOff(), isFalse);
    });

    test('飞船状态应该包含所有必要信息', () {
      ship.init();
      ship.reinforceHull();
      ship.upgradeEngine();

      final status = ship.getShipStatus();

      expect(status.containsKey('hull'), isTrue);
      expect(status.containsKey('thrusters'), isTrue);
      expect(status.containsKey('alienAlloy'), isTrue);
      expect(status.containsKey('canLiftOff'), isTrue);
      expect(status.containsKey('canReinforceHull'), isTrue);
      expect(status.containsKey('canUpgradeEngine'), isTrue);
      expect(status.containsKey('isLiftoffOnCooldown'), isTrue);
      expect(status.containsKey('remainingCooldown'), isTrue);

      expect(status['hull'], equals(1));
      expect(status['thrusters'], equals(2));
      expect(status['canLiftOff'], isTrue);
    });

    test('重置功能应该清除所有状态', () {
      ship.init();
      ship.reinforceHull();
      ship.upgradeEngine();
      ship.setLiftoffCooldown();

      // 重置前有状态
      expect(ship.hull, greaterThan(0));
      expect(ship.thrusters, greaterThan(1));
      expect(ship.isLiftoffOnCooldown, isTrue);

      // 重置
      ship.reset();

      // 重置后状态清空
      expect(ship.hull, equals(Ship.baseHull));
      expect(ship.thrusters, equals(Ship.baseThrusters));
      expect(ship.isLiftoffOnCooldown, isFalse);
    });

    test('飞船描述应该根据船体状态变化', () {
      ship.init();

      // 船体为0时
      expect(ship.getShipDescription(), contains('damaged'));

      // 强化船体后
      ship.reinforceHull();
      ship.reinforceHull();
      ship.reinforceHull(); // 船体为3
      expect(ship.getShipDescription(), contains('poor'));

      // 继续强化
      for (int i = 0; i < 5; i++) {
        stateManager.add('stores["alien alloy"]', 1);
        ship.reinforceHull();
      }
      expect(ship.getShipDescription(), contains('good'));
    });

    test('getMaxHull方法应该返回当前船体值', () {
      ship.init();

      expect(ship.getMaxHull(), equals(0));

      ship.reinforceHull();
      expect(ship.getMaxHull(), equals(1));

      ship.reinforceHull();
      expect(ship.getMaxHull(), equals(2));
    });

    test('所需外星合金数量应该正确', () {
      final required = ship.getRequiredAlloy();

      expect(required['hull'], equals(Ship.alloyPerHull));
      expect(required['thruster'], equals(Ship.alloyPerThruster));
    });
  });
}
