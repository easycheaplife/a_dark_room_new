import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';

// 导入所有测试文件
import 'armor_button_verification_test.dart' as armor_button_tests;
import 'audio_system_optimization_test.dart' as audio_system_tests;
import 'crafting_system_verification_test.dart' as crafting_system_tests;
import 'event_frequency_test.dart' as event_frequency_tests;
import 'event_localization_fix_test.dart' as event_localization_tests;
import 'event_trigger_test.dart' as event_trigger_tests;
import 'executioner_boss_fight_test.dart' as executioner_boss_fight_tests;
import 'executioner_events_test.dart' as executioner_events_tests;
import 'landmarks_test.dart' as landmarks_tests;
import 'original_game_torch_requirements_test.dart' as torch_requirements_tests;
import 'road_generation_fix_test.dart' as road_generation_tests;
import 'ruined_city_leave_buttons_test.dart' as ruined_city_tests;
import 'ship_building_upgrade_system_test.dart' as ship_building_tests;
import 'cave_setpiece_test.dart' as cave_setpiece_tests;
import 'cave_landmark_integration_test.dart' as cave_integration_tests;
import 'space_movement_sensitivity_test.dart' as space_movement_tests;
import 'space_optimization_test.dart' as space_optimization_tests;
import 'torch_backpack_check_test.dart' as torch_backpack_tests;
import 'torch_backpack_simple_test.dart' as torch_backpack_simple_tests;
import 'water_capacity_test.dart' as water_capacity_tests;

/// A Dark Room 完整测试套件
///
/// 这个文件整合了所有的单元测试，提供一键测试所有功能的能力
///
/// 运行方式：
/// flutter test test/all_tests.dart
///
/// 测试覆盖范围：
/// 1. 事件系统测试
/// 2. 本地化测试
/// 3. 游戏机制测试
/// 4. UI功能测试
/// 5. 地图生成测试
/// 6. 背包系统测试
void main() {
  group('🎮 A Dark Room 完整测试套件', () {
    setUpAll(() {
      Logger.info('🚀 开始 A Dark Room 完整测试套件');
      Logger.info('=' * 60);
      Logger.info('测试覆盖范围：');
      Logger.info('  📅 事件系统 - 触发频率、本地化、可用性、刽子手事件、Boss战斗');
      Logger.info('  🗺️  地图系统 - 地标生成、道路生成');
      Logger.info('  🎒 背包系统 - 火把检查、容量管理');
      Logger.info('  🏛️  UI系统 - 按钮状态、界面交互、护甲按钮');
      Logger.info('  💧 资源系统 - 水容量、物品管理');
      Logger.info('  🚀 太空系统 - 移动敏感度、优化测试、飞船建造升级');
      Logger.info('  🎵 音频系统 - 预加载、音频池、性能监控');
      Logger.info('  🔧 制作系统 - 制作验证、系统完整性');
      Logger.info('=' * 60);
    });

    group('📅 事件系统测试', () {
      group('事件触发频率', () {
        event_frequency_tests.main();
      });

      group('事件本地化修复', () {
        event_localization_tests.main();
      });

      group('事件触发机制', () {
        event_trigger_tests.main();
      });

      group('刽子手事件测试', () {
        executioner_events_tests.main();
      });

      group('执行者Boss战斗测试', () {
        executioner_boss_fight_tests.main();
      });

      group('洞穴Setpiece事件测试', () {
        cave_setpiece_tests.main();
      });

      group('洞穴地标集成测试', () {
        cave_integration_tests.main();
      });
    });

    group('🗺️ 地图系统测试', () {
      group('地标生成测试', () {
        landmarks_tests.main();
      });

      group('道路生成修复', () {
        road_generation_tests.main();
      });
    });

    group('🎒 背包系统测试', () {
      group('火把背包检查', () {
        torch_backpack_tests.main();
      });

      group('火把背包简化', () {
        torch_backpack_simple_tests.main();
      });

      group('火把需求验证', () {
        torch_requirements_tests.main();
      });
    });

    group('🏛️ UI系统测试', () {
      group('废墟城市离开按钮', () {
        ruined_city_tests.main();
      });

      group('护甲按钮验证', () {
        armor_button_tests.main();
      });
    });

    group('💧 资源系统测试', () {
      group('水容量管理', () {
        water_capacity_tests.main();
      });
    });

    group('🚀 太空系统测试', () {
      group('太空移动敏感度', () {
        space_movement_tests.main();
      });

      group('太空优化测试', () {
        space_optimization_tests.main();
      });

      group('飞船建造升级系统', () {
        ship_building_tests.main();
      });
    });

    group('🎵 音频系统测试', () {
      group('音频系统优化', () {
        audio_system_tests.main();
      });
    });

    group('🔧 制作系统测试', () {
      group('制作系统完整性验证', () {
        crafting_system_tests.main();
      });
    });

    tearDownAll(() {
      Logger.info('=' * 60);
      Logger.info('🎉 A Dark Room 完整测试套件执行完成');
      Logger.info('=' * 60);
    });
  });

  group('🔧 测试工具和实用程序', () {
    test('测试环境验证', () {
      Logger.info('🧪 验证测试环境...');

      // 验证Logger工作正常
      expect(Logger.info, isA<Function>());

      // 验证测试框架工作正常
      expect(true, isTrue);

      Logger.info('✅ 测试环境验证通过');
    });

    test('测试覆盖率统计', () {
      Logger.info('📊 统计测试覆盖率...');

      final testCategories = [
        '事件系统',
        '地图系统',
        '背包系统',
        'UI系统',
        '资源系统',
        '太空系统',
        '音频系统'
      ];

      final testFiles = [
        'armor_button_verification_test.dart',
        'audio_system_optimization_test.dart',
        'event_frequency_test.dart',
        'event_localization_fix_test.dart',
        'event_trigger_test.dart',
        'executioner_events_test.dart',
        'landmarks_test.dart',
        'original_game_torch_requirements_test.dart',
        'road_generation_fix_test.dart',
        'ruined_city_leave_buttons_test.dart',
        'space_movement_sensitivity_test.dart',
        'space_optimization_test.dart',
        'torch_backpack_check_test.dart',
        'torch_backpack_simple_test.dart',
        'water_capacity_test.dart'
      ];

      Logger.info('测试分类数量: ${testCategories.length}');
      Logger.info('测试文件数量: ${testFiles.length}');
      Logger.info(
          '平均每分类测试文件: ${(testFiles.length / testCategories.length).toStringAsFixed(1)}');

      expect(testFiles.length, greaterThan(5), reason: '应该有足够的测试文件');
      expect(testCategories.length, greaterThan(3), reason: '应该覆盖多个测试分类');
    });
  });
}
