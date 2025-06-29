/// A Dark Room 测试配置
/// 
/// 定义测试相关的常量和配置
class TestConfig {
  // 测试超时时间
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  
  // 测试数据量
  static const int smallSampleSize = 100;
  static const int mediumSampleSize = 500;
  static const int largeSampleSize = 1000;
  
  // 事件测试配置
  static const List<int> eventTimeRange = [3, 6]; // 分钟
  static const double retryScale = 0.5;
  static const double expectedSuccessRate = 0.8;
  
  // 地图测试配置
  static const int mapSize = 61;
  static const int mapCenter = 30;
  static const int maxLandmarkDistance = 20;
  
  // 背包测试配置
  static const int maxBackpackCapacity = 10;
  static const int defaultTorchCount = 5;
  
  // 资源测试配置
  static const int defaultWoodAmount = 100;
  static const int defaultFurAmount = 200;
  static const int defaultWaterCapacity = 10;
  
  // 测试环境配置
  static const bool enableDetailedLogging = true;
  static const bool enablePerformanceTests = false;
  
  // 测试分类
  static const List<String> testCategories = [
    '事件系统',
    '地图系统',
    '背包系统',
    'UI系统',
    '资源系统',
  ];
  
  // 测试文件映射
  static const Map<String, List<String>> categoryTestFiles = {
    '事件系统': [
      'event_frequency_test.dart',
      'event_localization_fix_test.dart',
      'event_trigger_test.dart',
    ],
    '地图系统': [
      'landmarks_test.dart',
      'road_generation_fix_test.dart',
    ],
    '背包系统': [
      'torch_backpack_check_test.dart',
      'torch_backpack_simple_test.dart',
      'original_game_torch_requirements_test.dart',
    ],
    'UI系统': [
      'ruined_city_leave_buttons_test.dart',
    ],
    '资源系统': [
      'water_capacity_test.dart',
    ],
  };
  
  // 获取所有测试文件
  static List<String> getAllTestFiles() {
    final allFiles = <String>[];
    for (final files in categoryTestFiles.values) {
      allFiles.addAll(files);
    }
    return allFiles;
  }
  
  // 获取特定分类的测试文件
  static List<String> getTestFilesForCategory(String category) {
    return categoryTestFiles[category] ?? [];
  }
  
  // 验证测试配置
  static bool validateConfig() {
    // 检查基本配置
    if (eventTimeRange.length != 2) return false;
    if (eventTimeRange[0] >= eventTimeRange[1]) return false;
    if (retryScale <= 0 || retryScale >= 1) return false;
    if (expectedSuccessRate <= 0 || expectedSuccessRate > 1) return false;
    
    // 检查地图配置
    if (mapSize <= 0) return false;
    if (mapCenter < 0 || mapCenter >= mapSize) return false;
    
    // 检查背包配置
    if (maxBackpackCapacity <= 0) return false;
    if (defaultTorchCount < 0) return false;
    
    return true;
  }
}

/// 测试工具类
class TestUtils {
  /// 生成随机事件间隔
  static int generateEventInterval() {
    final random = Random();
    return random.nextInt(TestConfig.eventTimeRange[1] - TestConfig.eventTimeRange[0] + 1) +
        TestConfig.eventTimeRange[0];
  }
  
  /// 生成重试间隔
  static double generateRetryInterval(int baseInterval) {
    return baseInterval * TestConfig.retryScale;
  }
  
  /// 计算成功率
  static double calculateSuccessRate(int successful, int total) {
    if (total == 0) return 0.0;
    return successful / total;
  }
  
  /// 验证成功率是否合理
  static bool isSuccessRateAcceptable(double rate) {
    return rate >= TestConfig.expectedSuccessRate;
  }
  
  /// 生成测试状态
  static Map<String, dynamic> generateTestGameState({
    int fire = 4,
    int wood = 100,
    int fur = 200,
    int population = 10,
    int buildings = 5,
  }) {
    return {
      'game.fire.value': fire,
      'stores.wood': wood,
      'stores.fur': fur,
      'game.population': population,
      'game.buildings': buildings,
    };
  }
}

import 'dart:math';

/// 测试专用日志工具
///
/// 避免在测试中使用print产生lint警告
class TestLogger {
  /// 输出信息日志
  static void info(String message) {
    // ignore: avoid_print
    print(message);
  }

  /// 输出错误日志
  static void error(String message) {
    // ignore: avoid_print
    print('ERROR: $message');
  }

  /// 输出警告日志
  static void warning(String message) {
    // ignore: avoid_print
    print('WARNING: $message');
  }

  /// 输出调试日志
  static void debug(String message) {
    // ignore: avoid_print
    print('DEBUG: $message');
  }
}
