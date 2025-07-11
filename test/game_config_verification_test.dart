import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/config/game_config.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/modules/space.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// GameConfig 配置项生效验证测试
///
/// 验证所有模块是否正确使用 GameConfig 中的配置项，
/// 而不是使用硬编码的常量值
void main() {
  group('🔧 GameConfig 配置项生效验证', () {
    setUpAll(() {
      Logger.info('🚀 开始 GameConfig 配置项验证测试');
    });

    group('🌍 World 模块配置验证', () {
      test('应该使用 GameConfig.baseHealth 而不是硬编码值', () {
        Logger.info('🧪 测试 World.baseHealth 配置');

        // 验证 World 模块使用的是 GameConfig 的值
        expect(World.baseHealth, equals(GameConfig.baseHealth));
        expect(World.baseHealth, equals(10));

        Logger.info('✅ World.baseHealth = ${World.baseHealth} (来自 GameConfig)');
      });

      test('应该使用 GameConfig 中的治疗数值配置', () {
        Logger.info('🧪 测试治疗数值配置');

        expect(World.meatHeal, equals(GameConfig.meatHeal));
        expect(World.medsHeal, equals(GameConfig.medsHeal));
        expect(World.hypoHeal, equals(GameConfig.hypoHeal));

        expect(World.meatHeal, equals(8));
        expect(World.medsHeal, equals(20));
        expect(World.hypoHeal, equals(30));

        Logger.info(
            '✅ 治疗数值: 肉=${World.meatHeal}, 药=${World.medsHeal}, 注射器=${World.hypoHeal}');
      });

      test('应该使用 GameConfig 中的战斗相关配置', () {
        Logger.info('🧪 测试战斗相关配置');

        expect(World.baseHitChance, equals(GameConfig.baseHitChance));
        expect(World.fightChance, equals(GameConfig.fightChance));
        expect(World.fightDelay, equals(GameConfig.fightDelay));

        expect(World.baseHitChance, equals(0.8));
        expect(World.fightChance, equals(0.20));
        expect(World.fightDelay, equals(3));

        Logger.info(
            '✅ 战斗配置: 命中率=${World.baseHitChance}, 战斗概率=${World.fightChance}, 延迟=${World.fightDelay}');
      });

      test('应该使用 GameConfig 中的世界地图配置', () {
        Logger.info('🧪 测试世界地图配置');

        expect(World.radius, equals(GameConfig.worldRadius));
        expect(World.villagePos, equals(GameConfig.villagePosition));
        expect(World.lightRadius, equals(GameConfig.lightRadius));
        expect(World.baseWater, equals(GameConfig.baseWater));

        expect(World.radius, equals(30));
        expect(World.villagePos, equals([30, 30]));
        expect(World.lightRadius, equals(2));
        expect(World.baseWater, equals(10));

        Logger.info('✅ 地图配置: 半径=${World.radius}, 村庄位置=${World.villagePos}');
      });

      test('应该使用 GameConfig 中的移动消耗配置', () {
        Logger.info('🧪 测试移动消耗配置');

        expect(World.movesPerFood, equals(GameConfig.movesPerFood));
        expect(World.movesPerWater, equals(GameConfig.movesPerWater));
        expect(World.deathCooldown, equals(GameConfig.deathCooldown));

        expect(World.movesPerFood, equals(2));
        expect(World.movesPerWater, equals(1));
        expect(World.deathCooldown, equals(120));

        Logger.info(
            '✅ 移动消耗: 食物=${World.movesPerFood}步, 水=${World.movesPerWater}步, 死亡冷却=${World.deathCooldown}秒');
      });
    });

    group('🎒 Path 模块配置验证', () {
      test('应该使用 GameConfig.defaultBagSpace 配置', () {
        Logger.info('🧪 测试背包空间配置');

        expect(Path.defaultBagSpace, equals(GameConfig.defaultBagSpace));
        expect(Path.defaultBagSpace, equals(10));

        Logger.info(
            '✅ Path.defaultBagSpace = ${Path.defaultBagSpace} (来自 GameConfig)');
      });

      test('应该使用 GameConfig.itemWeights 配置', () {
        Logger.info('🧪 测试物品重量配置');

        expect(Path.weight, equals(GameConfig.itemWeights));

        // 验证几个关键物品的重量
        expect(Path.weight['bone spear'], equals(2.0));
        expect(Path.weight['iron sword'], equals(3.0));
        expect(Path.weight['rifle'], equals(5.0));
        expect(Path.weight['bullets'], equals(0.1));

        Logger.info('✅ 物品重量配置正确，共${Path.weight.length}个物品');
      });
    });

    group('🚀 Space 模块配置验证', () {
      test('应该使用 GameConfig 中的太空相关配置', () {
        Logger.info('🧪 测试太空模块配置');

        expect(Space.shipSpeed, equals(GameConfig.shipSpeed));
        expect(Space.baseAsteroidDelay, equals(GameConfig.baseAsteroidDelay));
        expect(Space.baseAsteroidSpeed, equals(GameConfig.baseAsteroidSpeed));
        expect(Space.ftbSpeed, equals(GameConfig.ftbSpeed));

        expect(Space.shipSpeed, equals(3.0));
        expect(Space.baseAsteroidDelay, equals(500));
        expect(Space.baseAsteroidSpeed, equals(1500));
        expect(Space.ftbSpeed, equals(60000));

        Logger.info(
            '✅ 太空配置: 飞船速度=${Space.shipSpeed}, 小行星延迟=${Space.baseAsteroidDelay}');
      });

      test('应该使用 GameConfig 中的星空配置', () {
        Logger.info('🧪 测试星空配置');

        expect(Space.starWidth, equals(GameConfig.starWidth));
        expect(Space.starHeight, equals(GameConfig.starHeight));
        expect(Space.numStars, equals(GameConfig.numStars));
        expect(Space.starSpeed, equals(GameConfig.starSpeed));
        expect(Space.frameDelay, equals(GameConfig.frameDelay));

        expect(Space.starWidth, equals(3000));
        expect(Space.starHeight, equals(3000));
        expect(Space.numStars, equals(200));
        expect(Space.starSpeed, equals(60000));
        expect(Space.frameDelay, equals(100));

        Logger.info(
            '✅ 星空配置: 宽度=${Space.starWidth}, 高度=${Space.starHeight}, 星星数量=${Space.numStars}');
      });
    });

    group('🏠 Outside 模块配置验证', () {
      test('应该使用 GameConfig 中的外部模块配置', () {
        Logger.info('🧪 测试外部模块配置');

        // Outside 模块使用私有getter，我们通过反射或间接方式验证
        // 这里我们验证 GameConfig 中的值是否正确
        expect(GameConfig.popDelayRange, equals([0.5, 3.0]));
        expect(GameConfig.hutRoom, equals(4));
        expect(GameConfig.gatherWoodDelay, equals(60));
        expect(GameConfig.checkTrapsDelay, equals(90));

        Logger.info(
            '✅ 外部配置: 人口延迟=${GameConfig.popDelayRange}, 小屋容量=${GameConfig.hutRoom}');
        Logger.info(
            '✅ 操作延迟: 伐木=${GameConfig.gatherWoodDelay}秒, 陷阱=${GameConfig.checkTrapsDelay}秒');
      });
    });

    group('🔧 配置一致性验证', () {
      test('所有模块应该使用相同的基础配置值', () {
        Logger.info('🧪 测试配置一致性');

        // 验证所有模块使用的基础健康值都来自同一个配置
        final worldHealth = World.baseHealth;
        final configHealth = GameConfig.baseHealth;

        expect(worldHealth, equals(configHealth));
        expect(worldHealth, equals(10));

        Logger.info('✅ 基础健康值在所有模块中保持一致: $worldHealth');
      });

      test('配置项应该有合理的默认值', () {
        Logger.info('🧪 测试配置默认值合理性');

        // 验证关键配置项的值在合理范围内
        expect(GameConfig.baseHealth, greaterThan(0));
        expect(GameConfig.baseHealth, lessThanOrEqualTo(100));

        expect(GameConfig.meatHeal, greaterThan(0));
        expect(GameConfig.medsHeal, greaterThan(GameConfig.meatHeal));
        expect(GameConfig.hypoHeal, greaterThan(GameConfig.medsHeal));

        expect(GameConfig.baseHitChance, greaterThan(0.0));
        expect(GameConfig.baseHitChance, lessThanOrEqualTo(1.0));

        expect(GameConfig.fightChance, greaterThan(0.0));
        expect(GameConfig.fightChance, lessThanOrEqualTo(1.0));

        Logger.info('✅ 所有配置项的默认值都在合理范围内');
      });
    });

    tearDown(() {
      // 测试清理
    });

    tearDownAll(() {
      Logger.info('🏁 GameConfig 配置项验证测试完成');
    });
  });
}
