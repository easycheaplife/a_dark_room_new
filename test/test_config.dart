import 'dart:math';

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
    '核心系统',
    '事件系统',
    '地图系统',
    '背包系统',
    'UI系统',
    '资源系统',
    '太空系统',
  ];

  // 注意：具体的测试文件映射请参考 all_tests.dart
  // 这里只保留测试分类，避免维护重复的文件列表

  // 注意：测试文件管理已移至 all_tests.dart 和 run_tests.dart
  // 如需获取测试文件列表，请参考这些文件

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
    return random.nextInt(
            TestConfig.eventTimeRange[1] - TestConfig.eventTimeRange[0] + 1) +
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

/// 注意：测试中应使用 Logger.info 而不是 print
/// 这样可以保持日志输出的一致性
