import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'package:a_dark_room_new/core/audio_engine.dart';

void main() {
  group('制作系统完整性验证', () {
    late Room room;
    late StateManager stateManager;

    setUpAll(() async {
      // 初始化本地化系统
      await Localization().init();
    });

    setUp(() {
      room = Room();
      stateManager = StateManager();
      stateManager.clearGameData(); // 清理状态

      // 设置AudioEngine测试模式，避免音频插件异常
      AudioEngine().setTestMode(true);
    });

    tearDownAll(() {
      // 安全地清理状态管理器
      try {
        StateManager().clearGameData();
      } catch (e) {
        Logger.info('⚠️ 测试清理时出错: $e');
      }
    });

    test('验证所有可制作物品都有完整的button属性配置', () {
      Logger.info('🔧 验证制作系统button属性配置...');

      final craftables = room.craftables;
      expect(craftables.isNotEmpty, isTrue, reason: '可制作物品列表不应为空');

      int verifiedCount = 0;
      for (final entry in craftables.entries) {
        final itemName = entry.key;
        final itemConfig = entry.value;

        // 验证必要属性存在
        expect(itemConfig.containsKey('name'), isTrue,
            reason: '$itemName 必须有name属性');
        expect(itemConfig.containsKey('button'), isTrue,
            reason: '$itemName 必须有button属性');
        expect(itemConfig.containsKey('type'), isTrue,
            reason: '$itemName 必须有type属性');
        expect(itemConfig.containsKey('cost'), isTrue,
            reason: '$itemName 必须有cost属性');
        expect(itemConfig.containsKey('audio'), isTrue,
            reason: '$itemName 必须有audio属性');

        // 验证button属性为null（初始状态）
        expect(itemConfig['button'], isNull,
            reason: '$itemName 的button属性应该初始化为null');

        Logger.info('✅ $itemName: 所有属性配置正确');
        verifiedCount++;
      }

      Logger.info('🎉 制作系统验证完成！共验证 $verifiedCount 个可制作物品');
    });

    test('验证护甲类物品的特殊属性', () {
      Logger.info('🛡️ 验证护甲类物品特殊属性...');

      final armorItems = ['l armour', 'i armour', 's armour'];

      for (final armorName in armorItems) {
        final armor = room.craftables[armorName];
        expect(armor, isNotNull, reason: '$armorName 配置不应为空');

        // 验证护甲特有属性
        expect(armor!['type'], equals('upgrade'),
            reason: '$armorName 类型应为upgrade');
        expect(armor['maximum'], equals(1), reason: '$armorName 最大数量应为1');
        expect(armor.containsKey('buildMsg'), isTrue,
            reason: '$armorName 应有buildMsg属性');

        // 验证成本函数
        expect(armor['cost'], isA<Function>(), reason: '$armorName 的cost应为函数');

        final costFunction = armor['cost'] as Function;
        final cost = costFunction(stateManager);
        expect(cost, isA<Map<String, dynamic>>(),
            reason: '$armorName 的成本应返回Map');

        Logger.info('✅ $armorName: 护甲属性配置正确');
      }

      Logger.info('🎉 护甲类物品验证通过！');
    });

    test('验证制作解锁逻辑', () {
      Logger.info('🔓 验证制作解锁逻辑...');

      // 设置基础条件
      stateManager.set('game.builder.level', 4); // 建造者等级足够
      stateManager.set('game.buildings.workshop', 1); // 有工坊

      final testItems = ['l armour', 'i armour', 's armour', 'rifle', 'torch'];

      for (final itemName in testItems) {
        // 设置足够的资源
        final item = room.craftables[itemName]!;
        final costFunction = item['cost'] as Function;
        final cost = costFunction(stateManager);

        for (final resource in cost.keys) {
          stateManager.set('stores.$resource', cost[resource]! * 2);
        }

        // 验证解锁逻辑
        final isUnlocked = room.craftUnlocked(itemName);
        expect(isUnlocked, isTrue, reason: '$itemName 在满足条件时应该解锁');

        Logger.info('✅ $itemName: 解锁逻辑正常');
      }

      Logger.info('🎉 制作解锁逻辑验证通过！');
    });

    test('验证制作功能执行', () {
      Logger.info('🔨 验证制作功能执行...');

      // 设置基础条件
      stateManager.set('game.builder.level', 4);
      stateManager.set('game.buildings.workshop', 1);
      stateManager.set('game.temperature.value', 2); // 温度适宜

      // 测试制作火把（简单物品）
      stateManager.set('stores.wood', 10);
      stateManager.set('stores.cloth', 10);

      final initialTorches = stateManager.get('stores.torch', true) ?? 0;
      final buildResult = room.build('torch');

      expect(buildResult, isTrue, reason: '制作火把应该成功');

      final finalTorches = stateManager.get('stores.torch', true) ?? 0;
      expect(finalTorches, equals(initialTorches + 1), reason: '制作后火把数量应该增加1');

      Logger.info('✅ 制作功能执行正常');
      Logger.info('🎉 制作系统功能验证通过！');
    });

    test('验证制作系统与原游戏的一致性', () {
      Logger.info('🔍 验证与原游戏的一致性...');

      // 验证护甲成本与原游戏一致
      final expectedCosts = {
        'l armour': {'leather': 200, 'scales': 20},
        'i armour': {'leather': 200, 'iron': 100},
        's armour': {'leather': 200, 'steel': 100},
      };

      for (final entry in expectedCosts.entries) {
        final itemName = entry.key;
        final expectedCost = entry.value;

        final item = room.craftables[itemName]!;
        final costFunction = item['cost'] as Function;
        final actualCost = costFunction(stateManager);

        expect(actualCost, equals(expectedCost),
            reason: '$itemName 的成本应与原游戏一致');

        Logger.info('✅ $itemName: 成本与原游戏一致');
      }

      Logger.info('🎉 与原游戏一致性验证通过！');
    });
  });
}
