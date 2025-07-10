import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/config/game_config.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/events/world_events.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 战斗伤害配置测试
/// 
/// 验证战斗伤害相关参数是否正确从配置文件中获取，
/// 确保武器伤害和敌人数据都使用统一的配置管理
void main() {
  group('⚔️ 战斗伤害配置测试', () {
    setUpAll(() {
      Logger.info('🚀 开始战斗伤害配置测试');
    });

    group('🗡️ 武器伤害配置验证', () {
      test('武器伤害数值应该从GameConfig获取', () {
        Logger.info('🧪 测试武器伤害配置');
        
        // 验证关键武器的伤害值
        expect(World.weapons['fists']!['damage'], equals(GameConfig.weaponDamage['fists']));
        expect(World.weapons['bone spear']!['damage'], equals(GameConfig.weaponDamage['bone spear']));
        expect(World.weapons['iron sword']!['damage'], equals(GameConfig.weaponDamage['iron sword']));
        expect(World.weapons['steel sword']!['damage'], equals(GameConfig.weaponDamage['steel sword']));
        expect(World.weapons['rifle']!['damage'], equals(GameConfig.weaponDamage['rifle']));
        
        // 验证具体数值
        expect(World.weapons['fists']!['damage'], equals(1));
        expect(World.weapons['bone spear']!['damage'], equals(2));
        expect(World.weapons['iron sword']!['damage'], equals(4));
        expect(World.weapons['steel sword']!['damage'], equals(6));
        expect(World.weapons['rifle']!['damage'], equals(5));
        
        Logger.info('✅ 武器伤害配置正确');
      });

      test('武器冷却时间应该从GameConfig获取', () {
        Logger.info('🧪 测试武器冷却时间配置');
        
        // 验证关键武器的冷却时间
        expect(World.weapons['fists']!['cooldown'], equals(GameConfig.weaponCooldown['fists']));
        expect(World.weapons['bone spear']!['cooldown'], equals(GameConfig.weaponCooldown['bone spear']));
        expect(World.weapons['rifle']!['cooldown'], equals(GameConfig.weaponCooldown['rifle']));
        expect(World.weapons['grenade']!['cooldown'], equals(GameConfig.weaponCooldown['grenade']));
        expect(World.weapons['bolas']!['cooldown'], equals(GameConfig.weaponCooldown['bolas']));
        
        // 验证具体数值
        expect(World.weapons['fists']!['cooldown'], equals(2));
        expect(World.weapons['bone spear']!['cooldown'], equals(2));
        expect(World.weapons['rifle']!['cooldown'], equals(1));
        expect(World.weapons['grenade']!['cooldown'], equals(5));
        expect(World.weapons['bolas']!['cooldown'], equals(15));
        
        Logger.info('✅ 武器冷却时间配置正确');
      });

      test('特殊武器配置应该正确', () {
        Logger.info('🧪 测试特殊武器配置');
        
        // 验证缠绕武器（bolas）
        final bolas = World.weapons['bolas']!;
        expect(bolas['damage'], equals('stun')); // 特殊伤害类型
        expect(bolas['cooldown'], equals(15));
        expect(bolas['cost'], isNotNull);
        expect(bolas['cost']['bolas'], equals(1));
        
        // 验证干扰器（disruptor）
        final disruptor = World.weapons['disruptor']!;
        expect(disruptor['damage'], equals('stun')); // 特殊伤害类型
        expect(disruptor['cooldown'], equals(15));
        
        Logger.info('✅ 特殊武器配置正确');
      });

      test('所有武器都应该有配置', () {
        Logger.info('🧪 测试武器配置完整性');
        
        final weaponNames = World.weapons.keys.toList();
        Logger.info('📋 武器列表: $weaponNames');
        
        for (final weaponName in weaponNames) {
          final weapon = World.weapons[weaponName]!;
          
          // 每个武器都应该有基本属性
          expect(weapon['verb'], isNotNull, reason: '$weaponName 缺少 verb 属性');
          expect(weapon['type'], isNotNull, reason: '$weaponName 缺少 type 属性');
          expect(weapon['damage'], isNotNull, reason: '$weaponName 缺少 damage 属性');
          expect(weapon['cooldown'], isNotNull, reason: '$weaponName 缺少 cooldown 属性');
          
          Logger.info('✅ $weaponName: 伤害=${weapon['damage']}, 冷却=${weapon['cooldown']}秒');
        }
        
        Logger.info('✅ 所有武器配置完整');
      });
    });

    group('👹 敌人数据配置验证', () {
      test('土匪事件应该使用GameConfig配置', () {
        Logger.info('🧪 测试土匪事件配置');
        
        final bandit = WorldEvents.bandit;
        final scene = bandit['scenes']['start'];
        
        expect(scene['health'], equals(GameConfig.enemyHealth['bandit']));
        expect(scene['damage'], equals(GameConfig.enemyDamage['bandit']));
        expect(scene['hit'], equals(GameConfig.enemyHitChance['bandit']));
        expect(scene['attackDelay'], equals(GameConfig.enemyAttackDelay['bandit']));
        
        // 验证具体数值
        expect(scene['health'], equals(15));
        expect(scene['damage'], equals(4));
        expect(scene['hit'], equals(0.6));
        expect(scene['attackDelay'], equals(3.0));
        
        Logger.info('✅ 土匪事件配置正确');
      });

      test('土匪团伙事件应该使用GameConfig配置', () {
        Logger.info('🧪 测试土匪团伙事件配置');
        
        final banditGroup = WorldEvents.banditGroup;
        final scene = banditGroup['scenes']['start'];
        
        expect(scene['health'], equals(GameConfig.enemyHealth['bandit_group']));
        expect(scene['damage'], equals(GameConfig.enemyDamage['bandit_group']));
        expect(scene['hit'], equals(GameConfig.enemyHitChance['bandit_group']));
        expect(scene['attackDelay'], equals(GameConfig.enemyAttackDelay['bandit_group']));
        
        // 验证具体数值
        expect(scene['health'], equals(30));
        expect(scene['damage'], equals(5));
        expect(scene['hit'], equals(0.7));
        expect(scene['attackDelay'], equals(2.5));
        
        Logger.info('✅ 土匪团伙事件配置正确');
      });

      test('士兵事件应该使用GameConfig配置', () {
        Logger.info('🧪 测试士兵事件配置');
        
        final soldiers = WorldEvents.soldiers;
        final scene = soldiers['scenes']['start'];
        
        expect(scene['health'], equals(GameConfig.enemyHealth['soldiers']));
        expect(scene['damage'], equals(GameConfig.enemyDamage['soldiers']));
        expect(scene['hit'], equals(GameConfig.enemyHitChance['soldiers']));
        expect(scene['attackDelay'], equals(GameConfig.enemyAttackDelay['soldiers']));
        
        // 验证具体数值
        expect(scene['health'], equals(35));
        expect(scene['damage'], equals(6));
        expect(scene['hit'], equals(0.8));
        expect(scene['attackDelay'], equals(2.0));
        
        Logger.info('✅ 士兵事件配置正确');
      });

      test('外星人事件应该使用GameConfig配置', () {
        Logger.info('🧪 测试外星人事件配置');
        
        final alien = WorldEvents.alien;
        final scene = alien['scenes']['start'];
        
        expect(scene['health'], equals(GameConfig.enemyHealth['alien']));
        expect(scene['damage'], equals(GameConfig.enemyDamage['alien']));
        expect(scene['hit'], equals(GameConfig.enemyHitChance['alien']));
        expect(scene['attackDelay'], equals(GameConfig.enemyAttackDelay['alien']));
        
        // 验证具体数值
        expect(scene['health'], equals(45));
        expect(scene['damage'], equals(10));
        expect(scene['hit'], equals(0.7));
        expect(scene['attackDelay'], equals(2.5));
        
        Logger.info('✅ 外星人事件配置正确');
      });

      test('战团事件应该使用GameConfig配置', () {
        Logger.info('🧪 测试战团事件配置');
        
        final warband = WorldEvents.warband;
        final scene = warband['scenes']['start'];
        
        expect(scene['health'], equals(GameConfig.enemyHealth['warband']));
        expect(scene['damage'], equals(GameConfig.enemyDamage['warband']));
        expect(scene['hit'], equals(GameConfig.enemyHitChance['warband']));
        expect(scene['attackDelay'], equals(GameConfig.enemyAttackDelay['warband']));
        
        // 验证具体数值
        expect(scene['health'], equals(60));
        expect(scene['damage'], equals(7));
        expect(scene['hit'], equals(0.8));
        expect(scene['attackDelay'], equals(2.0));
        
        Logger.info('✅ 战团事件配置正确');
      });
    });

    group('🔧 配置一致性验证', () {
      test('GameConfig中的武器配置应该完整', () {
        Logger.info('🧪 测试GameConfig武器配置完整性');
        
        final weaponNames = World.weapons.keys.toList();
        final configDamageKeys = GameConfig.weaponDamage.keys.toList();
        final configCooldownKeys = GameConfig.weaponCooldown.keys.toList();
        
        // 检查所有数值伤害武器都在配置中
        for (final weaponName in weaponNames) {
          final weapon = World.weapons[weaponName]!;
          final damage = weapon['damage'];
          
          if (damage is int) {
            expect(configDamageKeys, contains(weaponName), 
                reason: '武器 $weaponName 的伤害配置缺失');
          }
          
          expect(configCooldownKeys, contains(weaponName), 
              reason: '武器 $weaponName 的冷却配置缺失');
        }
        
        Logger.info('✅ GameConfig武器配置完整');
      });

      test('GameConfig中的敌人配置应该完整', () {
        Logger.info('🧪 测试GameConfig敌人配置完整性');
        
        final enemyTypes = ['bandit', 'bandit_group', 'soldiers', 'alien', 'warband'];
        
        for (final enemyType in enemyTypes) {
          expect(GameConfig.enemyHealth.containsKey(enemyType), isTrue,
              reason: '敌人 $enemyType 的血量配置缺失');
          expect(GameConfig.enemyDamage.containsKey(enemyType), isTrue,
              reason: '敌人 $enemyType 的伤害配置缺失');
          expect(GameConfig.enemyHitChance.containsKey(enemyType), isTrue,
              reason: '敌人 $enemyType 的命中率配置缺失');
          expect(GameConfig.enemyAttackDelay.containsKey(enemyType), isTrue,
              reason: '敌人 $enemyType 的攻击延迟配置缺失');
              
          Logger.info('✅ $enemyType: 血量=${GameConfig.enemyHealth[enemyType]}, '
              '伤害=${GameConfig.enemyDamage[enemyType]}, '
              '命中=${GameConfig.enemyHitChance[enemyType]}, '
              '延迟=${GameConfig.enemyAttackDelay[enemyType]}');
        }
        
        Logger.info('✅ GameConfig敌人配置完整');
      });

      test('配置数值应该在合理范围内', () {
        Logger.info('🧪 测试配置数值合理性');
        
        // 验证武器伤害范围
        for (final damage in GameConfig.weaponDamage.values) {
          expect(damage, greaterThan(0));
          expect(damage, lessThanOrEqualTo(20));
        }
        
        // 验证武器冷却时间范围
        for (final cooldown in GameConfig.weaponCooldown.values) {
          expect(cooldown, greaterThan(0));
          expect(cooldown, lessThanOrEqualTo(20));
        }
        
        // 验证敌人血量范围
        for (final health in GameConfig.enemyHealth.values) {
          expect(health, greaterThan(0));
          expect(health, lessThanOrEqualTo(100));
        }
        
        // 验证敌人伤害范围
        for (final damage in GameConfig.enemyDamage.values) {
          expect(damage, greaterThan(0));
          expect(damage, lessThanOrEqualTo(20));
        }
        
        // 验证命中率范围
        for (final hitChance in GameConfig.enemyHitChance.values) {
          expect(hitChance, greaterThanOrEqualTo(0.0));
          expect(hitChance, lessThanOrEqualTo(1.0));
        }
        
        Logger.info('✅ 所有配置数值都在合理范围内');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 战斗伤害配置测试完成');
    });
  });
}
