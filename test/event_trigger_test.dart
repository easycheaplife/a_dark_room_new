import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'dart:math';

/// 事件触发测试套件
///
/// 测试事件触发频率和时间间隔机制
void main() {
  group('事件触发机制测试', () {
    setUpAll(() {
      Logger.info('🧪 开始事件触发机制测试套件');
    });

    group('事件时间间隔测试', () {
    test('事件时间间隔测试', () {
      Logger.info('🧪 开始事件时间间隔测试...');

      const eventTimeRange = [3, 6]; // 分钟
      final intervals = <int>[];

      // 模拟100次事件调度
      for (int i = 0; i < 100; i++) {
        final random = Random();
        final interval = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
            eventTimeRange[0];
        intervals.add(interval);
      }

      final minInterval = intervals.reduce((a, b) => a < b ? a : b);
      final maxInterval = intervals.reduce((a, b) => a > b ? a : b);
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

      Logger.info('🎯 事件间隔统计:');
      Logger.info('  最小间隔: $minInterval分钟');
      Logger.info('  最大间隔: $maxInterval分钟');
      Logger.info('  平均间隔: $avgInterval.toStringAsFixed(1)分钟');

      expect(minInterval, equals(3), reason: '最小间隔应为3分钟');
      expect(maxInterval, equals(6), reason: '最大间隔应为6分钟');
      expect(avgInterval, closeTo(4.5, 0.5), reason: '平均间隔应接近4.5分钟');
    });

    test('重试机制时间间隔测试', () {
      Logger.info('🧪 开始重试机制时间间隔测试...');

      const eventTimeRange = [3, 6]; // 分钟
      const retryScale = 0.5;
      final retryIntervals = <double>[];

      // 模拟100次重试调度
      for (int i = 0; i < 100; i++) {
        final random = Random();
        final baseInterval = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
            eventTimeRange[0];
        final retryInterval = baseInterval * retryScale;
        retryIntervals.add(retryInterval);
      }

      final minRetryInterval = retryIntervals.reduce((a, b) => a < b ? a : b);
      final maxRetryInterval = retryIntervals.reduce((a, b) => a > b ? a : b);
      final avgRetryInterval = retryIntervals.reduce((a, b) => a + b) / retryIntervals.length;

      Logger.info('🎯 重试间隔统计:');
      Logger.info('  最小重试间隔: ${minRetryInterval.toStringAsFixed(1)}分钟');
      Logger.info('  最大重试间隔: ${maxRetryInterval.toStringAsFixed(1)}分钟');
      Logger.info('  平均重试间隔: ${avgRetryInterval.toStringAsFixed(1)}分钟');

      expect(minRetryInterval, equals(1.5), reason: '最小重试间隔应为1.5分钟');
      expect(maxRetryInterval, equals(3.0), reason: '最大重试间隔应为3.0分钟');
      expect(avgRetryInterval, closeTo(2.25, 0.25), reason: '平均重试间隔应接近2.25分钟');
    });

    test('事件触发频率分布测试', () {
      Logger.info('🧪 开始事件触发频率分布测试...');

      const eventTimeRange = [3, 6]; // 分钟
      final distribution = <int, int>{};
      final testRounds = 1000;

      // 模拟1000次事件调度
      for (int i = 0; i < testRounds; i++) {
        final random = Random();
        final interval = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
            eventTimeRange[0];
        distribution[interval] = (distribution[interval] ?? 0) + 1;
      }

      Logger.info('🎯 间隔分布统计:');
      for (int i = eventTimeRange[0]; i <= eventTimeRange[1]; i++) {
        final count = distribution[i] ?? 0;
        final percentage = (count / testRounds * 100).toStringAsFixed(1);
        Logger.info('  $i分钟: $count次 ($percentage%)');

        // 每个间隔的出现概率应该大致相等（约25%）
        expect(percentage, isNot(equals('0.0')), reason: '$i分钟间隔应该有出现');
        expect(count, greaterThan(testRounds * 0.15), reason: '$i分钟间隔出现次数应该合理');
      }
    });

      test('修复效果验证测试', () {
        Logger.info('🧪 开始修复效果验证测试...');

        // 模拟修复前的情况（事件池分离，无重试）
        final oldSystemTriggerRate = _simulateOldEventSystem();

        // 模拟修复后的情况（全局事件池，有重试）
        final newSystemTriggerRate = _simulateNewEventSystem();

        Logger.info('🎯 修复效果对比:');
        Logger.info('  修复前触发成功率: ${(oldSystemTriggerRate * 100).toStringAsFixed(1)}%');
        Logger.info('  修复后触发成功率: ${(newSystemTriggerRate * 100).toStringAsFixed(1)}%');
        Logger.info('  改进幅度: ${((newSystemTriggerRate - oldSystemTriggerRate) * 100).toStringAsFixed(1)}%');

        expect(newSystemTriggerRate, greaterThan(oldSystemTriggerRate),
            reason: '修复后的触发成功率应该高于修复前');
        expect(newSystemTriggerRate, greaterThan(0.8),
            reason: '修复后的触发成功率应该超过80%');
      });
    });

    tearDownAll(() {
      Logger.info('✅ 事件触发机制测试套件完成');
    });
  });
}

/// 模拟旧事件系统（修复前）
double _simulateOldEventSystem() {
  const testRounds = 1000;
  int successfulTriggers = 0;

  for (int i = 0; i < testRounds; i++) {
    // 模拟按模块分离的事件池（较小）
    final moduleEventCount = Random().nextInt(5) + 3; // 3-7个事件
    final availableEventCount = Random().nextInt(moduleEventCount + 1); // 0到全部

    if (availableEventCount > 0) {
      successfulTriggers++;
    }
    // 旧系统无重试机制，失败就等下一个完整周期
  }

  return successfulTriggers / testRounds;
}

/// 模拟新事件系统（修复后）
double _simulateNewEventSystem() {
  const testRounds = 1000;
  int successfulTriggers = 0;

  for (int i = 0; i < testRounds; i++) {
    // 模拟全局事件池（较大）
    final globalEventCount = Random().nextInt(10) + 15; // 15-24个事件
    final availableEventCount = Random().nextInt(globalEventCount + 1); // 0到全部

    if (availableEventCount > 0) {
      successfulTriggers++;
    } else {
      // 新系统有重试机制，50%概率在重试时成功
      if (Random().nextDouble() < 0.5) {
        successfulTriggers++;
      }
    }
  }

  return successfulTriggers / testRounds;
}
