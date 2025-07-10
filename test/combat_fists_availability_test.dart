import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 战斗中拳头可用性测试
///
/// 验证在有缠绕武器（bolas）等非数值伤害武器时，
/// 拳头（fists）仍然可用作为基础攻击方式
void main() {
  group('🥊 战斗中拳头可用性测试', () {
    late Events events;
    late StateManager stateManager;
    late Path path;

    setUpAll(() {
      Logger.info('🚀 开始战斗拳头可用性测试');
    });

    setUp(() {
      // 初始化测试环境
      stateManager = StateManager();
      stateManager.init();
      events = Events();
      path = Path();

      // 清空背包
      for (final weaponName in World.weapons.keys) {
        if (weaponName != 'fists') {
          path.outfit[weaponName] = 0;
          stateManager.set('outfit["$weaponName"]', 0);
        }
      }
    });

    group('🎯 基础拳头可用性', () {
      test('没有任何武器时应该显示拳头', () {
        Logger.info('🧪 测试：没有武器时的拳头显示');

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('fists'));
        expect(availableWeapons.length, equals(1));
        expect(availableWeapons.first, equals('fists'));

        Logger.info('✅ 没有武器时正确显示拳头: $availableWeapons');
      });

      test('有数值伤害武器时不应该显示拳头', () {
        Logger.info('🧪 测试：有数值伤害武器时的拳头隐藏');

        // 添加一个数值伤害武器
        path.outfit['bone spear'] = 1;
        stateManager.set('outfit["bone spear"]', 1);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('bone spear'));
        expect(availableWeapons, isNot(contains('fists')));

        Logger.info('✅ 有数值伤害武器时正确隐藏拳头: $availableWeapons');
      });
    });

    group('🌪️ 缠绕武器特殊情况', () {
      test('只有缠绕武器时应该同时显示拳头和缠绕', () {
        Logger.info('🧪 测试：只有缠绕武器时的武器显示');

        // 添加缠绕武器（注意：bolas既是武器也是弹药）
        path.outfit['bolas'] = 2; // 至少需要2个：1个作为武器，1个作为弹药
        stateManager.set('outfit["bolas"]', 2);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('fists'));
        expect(availableWeapons, contains('bolas'));
        expect(availableWeapons.length, equals(2));

        // 拳头应该在前面（参考原游戏的prependTo逻辑）
        expect(availableWeapons.first, equals('fists'));

        Logger.info('✅ 只有缠绕武器时正确显示拳头和缠绕: $availableWeapons');
      });

      test('缠绕武器 + 数值伤害武器时不应该显示拳头', () {
        Logger.info('🧪 测试：缠绕武器+数值武器时的武器显示');

        // 添加缠绕武器和数值伤害武器
        path.outfit['bolas'] = 2; // 足够的弹药
        path.outfit['bone spear'] = 1;
        stateManager.set('outfit["bolas"]', 2);
        stateManager.set('outfit["bone spear"]', 1);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('bolas'));
        expect(availableWeapons, contains('bone spear'));
        expect(availableWeapons, isNot(contains('fists')));

        Logger.info('✅ 缠绕+数值武器时正确隐藏拳头: $availableWeapons');
      });

      test('缠绕武器没有弹药时不应该显示缠绕但应该显示拳头', () {
        Logger.info('🧪 测试：缠绕武器无弹药时的武器显示');

        // 添加缠绕武器但没有弹药
        path.outfit['bolas'] = 0; // 没有bolas弹药
        stateManager.set('outfit["bolas"]', 0);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('fists'));
        expect(availableWeapons, isNot(contains('bolas')));
        expect(availableWeapons.length, equals(1));

        Logger.info('✅ 缠绕武器无弹药时正确显示拳头: $availableWeapons');
      });
    });

    group('🔫 其他特殊武器测试', () {
      test('干扰器（disruptor）也应该触发拳头显示', () {
        Logger.info('🧪 测试：干扰器的武器显示');

        // 干扰器也是stun伤害
        path.outfit['disruptor'] = 1;
        stateManager.set('outfit["disruptor"]', 1);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('fists'));
        expect(availableWeapons, contains('disruptor'));
        expect(availableWeapons.length, equals(2));
        expect(availableWeapons.first, equals('fists'));

        Logger.info('✅ 干扰器时正确显示拳头和干扰器: $availableWeapons');
      });

      test('多个非数值伤害武器时应该显示拳头', () {
        Logger.info('🧪 测试：多个非数值伤害武器时的显示');

        // 添加多个非数值伤害武器
        path.outfit['bolas'] = 1;
        path.outfit['disruptor'] = 1;
        stateManager.set('outfit["bolas"]', 1);
        stateManager.set('outfit["disruptor"]', 1);

        final availableWeapons = events.getAvailableWeapons();

        expect(availableWeapons, contains('fists'));
        expect(availableWeapons, contains('bolas'));
        expect(availableWeapons, contains('disruptor'));
        expect(availableWeapons.length, equals(3));
        expect(availableWeapons.first, equals('fists'));

        Logger.info('✅ 多个非数值伤害武器时正确显示: $availableWeapons');
      });
    });

    group('🔍 武器配置验证', () {
      test('验证缠绕武器的配置正确', () {
        Logger.info('🧪 验证缠绕武器配置');

        final bolasConfig = World.weapons['bolas'];
        expect(bolasConfig, isNotNull);
        expect(bolasConfig!['damage'], equals('stun'));
        expect(bolasConfig['type'], equals('ranged'));
        expect(bolasConfig['verb'], equals('tangle'));
        expect(bolasConfig['cost'], isNotNull);
        expect(bolasConfig['cost']['bolas'], equals(1));

        Logger.info('✅ 缠绕武器配置正确: $bolasConfig');
      });

      test('验证干扰器的配置正确', () {
        Logger.info('🧪 验证干扰器配置');

        final disruptorConfig = World.weapons['disruptor'];
        expect(disruptorConfig, isNotNull);
        expect(disruptorConfig!['damage'], equals('stun'));
        expect(disruptorConfig['type'], equals('ranged'));
        expect(disruptorConfig['verb'], equals('stun'));

        Logger.info('✅ 干扰器配置正确: $disruptorConfig');
      });

      test('验证拳头的配置正确', () {
        Logger.info('🧪 验证拳头配置');

        final fistsConfig = World.weapons['fists'];
        expect(fistsConfig, isNotNull);
        expect(fistsConfig!['damage'], equals(1));
        expect(fistsConfig['type'], equals('unarmed'));
        expect(fistsConfig['verb'], equals('punch'));
        expect(fistsConfig['cost'], isNull);

        Logger.info('✅ 拳头配置正确: $fistsConfig');
      });
    });

    tearDown(() {
      // 清理测试环境
      // StateManager没有clearAll方法，手动清理关键状态
      for (final weaponName in World.weapons.keys) {
        if (weaponName != 'fists') {
          stateManager.set('outfit["$weaponName"]', 0);
        }
      }
    });

    tearDownAll(() {
      Logger.info('🏁 战斗拳头可用性测试完成');
    });
  });
}
