import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';

/// 护甲类物品button属性验证测试
///
/// 验证护甲类物品的button属性是否正确设置为null，
/// 确保与原游戏的实现保持一致
void main() {
  group('护甲类物品button属性验证', () {
    late Room room;
    late StateManager stateManager;

    setUpAll(() async {
      // 初始化本地化系统
      await Localization().init();
    });

    setUp(() {
      room = Room();
      stateManager = StateManager();
      stateManager.init();
    });

    test('验证所有护甲类物品都有button属性设置为null', () {
      print('🛡️ 开始验证护甲类物品button属性...');

      final armorItems = ['l armour', 'i armour', 's armour'];

      for (final armorName in armorItems) {
        final armor = room.craftables[armorName];

        // 验证护甲物品存在
        expect(armor, isNotNull, reason: '护甲物品 $armorName 应该存在');

        // 验证button属性存在且为null
        expect(armor!.containsKey('button'), isTrue,
            reason: '护甲物品 $armorName 应该包含button属性');
        expect(armor['button'], isNull,
            reason: '护甲物品 $armorName 的button属性应该为null');

        // 验证type属性为upgrade
        expect(armor['type'], equals('upgrade'),
            reason: '护甲物品 $armorName 的type应该为upgrade');

        // 验证maximum属性为1
        expect(armor['maximum'], equals(1),
            reason: '护甲物品 $armorName 的maximum应该为1');

        print(
            '✅ $armorName: button=${armor['button']}, type=${armor['type']}, maximum=${armor['maximum']}');
      }

      print('🎉 所有护甲类物品button属性验证通过！');
    });

    test('验证rifle武器也有正确的button属性', () {
      print('🔫 验证rifle武器button属性...');

      final rifle = room.craftables['rifle'];

      // 验证rifle存在
      expect(rifle, isNotNull, reason: 'rifle武器应该存在');

      // 验证button属性存在且为null
      expect(rifle!.containsKey('button'), isTrue, reason: 'rifle应该包含button属性');
      expect(rifle['button'], isNull, reason: 'rifle的button属性应该为null');

      // 验证type属性为weapon
      expect(rifle['type'], equals('weapon'), reason: 'rifle的type应该为weapon');

      print('✅ rifle: button=${rifle['button']}, type=${rifle['type']}');
      print('🎉 rifle武器button属性验证通过！');
    });

    test('对比原游戏和Flutter项目的护甲配置一致性', () {
      print('🔍 对比护甲配置一致性...');

      // 原游戏中的护甲配置（从原游戏源码提取）
      final originalArmorConfigs = {
        'l armour': {
          'type': 'upgrade',
          'maximum': 1,
          'cost': {'leather': 200, 'scales': 20},
        },
        'i armour': {
          'type': 'upgrade',
          'maximum': 1,
          'cost': {'leather': 200, 'iron': 100},
        },
        's armour': {
          'type': 'upgrade',
          'maximum': 1,
          'cost': {'leather': 200, 'steel': 100},
        },
      };

      for (final armorName in originalArmorConfigs.keys) {
        final originalConfig = originalArmorConfigs[armorName]!;
        final flutterConfig = room.craftables[armorName]!;

        // 验证type一致
        expect(flutterConfig['type'], equals(originalConfig['type']),
            reason: '$armorName 的type应该与原游戏一致');

        // 验证maximum一致
        expect(flutterConfig['maximum'], equals(originalConfig['maximum']),
            reason: '$armorName 的maximum应该与原游戏一致');

        // 验证cost一致（需要调用cost函数）
        final costFunction = flutterConfig['cost'] as Function;
        final actualCost = costFunction(stateManager);
        final expectedCost = originalConfig['cost'] as Map<String, int>;

        expect(actualCost, equals(expectedCost),
            reason: '$armorName 的cost应该与原游戏一致');

        print('✅ $armorName 配置与原游戏完全一致');
      }

      print('🎉 所有护甲配置与原游戏保持一致！');
    });

    test('验证护甲类物品的解锁逻辑', () {
      print('🔓 验证护甲类物品解锁逻辑...');

      // 设置必要的前置条件
      stateManager.set('game.builder.level', 4); // 建造者等级足够
      stateManager.set('game.buildings.workshop', 1); // 有工坊

      final armorItems = ['l armour', 'i armour', 's armour'];

      for (final armorName in armorItems) {
        // 设置足够的资源
        final armor = room.craftables[armorName]!;
        final costFunction = armor['cost'] as Function;
        final cost = costFunction(stateManager);

        for (final resource in cost.keys) {
          stateManager.set('stores.$resource', cost[resource]! * 2);
        }

        // 验证解锁逻辑
        final isUnlocked = room.craftUnlocked(armorName);
        expect(isUnlocked, isTrue, reason: '$armorName 在满足条件时应该解锁');

        print('✅ $armorName 解锁逻辑正常');
      }

      print('🎉 护甲类物品解锁逻辑验证通过！');
    });

    test('验证护甲类物品在UI中的显示逻辑', () {
      print('🖥️ 验证护甲类物品UI显示逻辑...');

      final armorItems = ['l armour', 'i armour', 's armour'];

      for (final armorName in armorItems) {
        final armor = room.craftables[armorName]!;

        // 验证是否需要工坊
        final needsWorkshop = room.needsWorkshop(armor['type']);
        expect(needsWorkshop, isTrue, reason: '护甲类物品应该需要工坊');

        // 验证本地化名称
        final localizedName = room.getLocalizedName(armorName);
        expect(localizedName, isNotEmpty, reason: '护甲类物品应该有本地化名称');

        print('✅ $armorName: 需要工坊=$needsWorkshop, 本地化名称="$localizedName"');
      }

      print('🎉 护甲类物品UI显示逻辑验证通过！');
    });
  });
}
