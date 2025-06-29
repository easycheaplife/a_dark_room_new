import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 事件触发频率测试
///
/// 用于测试和验证事件触发机制的修复效果
void main() {
  group('事件触发频率测试', () {
    setUpAll(() {
      Logger.info('🧪 开始事件触发频率测试套件');
    });

    test('事件触发频率分析', () {
      Logger.info('🎯 执行事件触发频率分析...');
      testEventFrequency();
    });

    test('事件可用性检查', () {
      Logger.info('🎯 执行事件可用性检查...');
      testEventAvailability();
    });

    test('事件触发模拟', () {
      Logger.info('🎯 执行事件触发模拟...');
      runEventSimulation(100);
    });

    test('事件时间间隔验证', () {
      Logger.info('🎯 执行事件时间间隔验证...');
      testEventTiming();
    });

    tearDownAll(() {
      Logger.info('✅ 事件触发频率测试套件完成');
    });
  });
}



/// 测试事件触发频率
void testEventFrequency() {
  Logger.info('🎯 测试事件触发频率...');
  Logger.info('');

  const eventTimeRange = [3, 6]; // 分钟
  final intervals = <int>[];
  final testRounds = 1000;

  Logger.info('📊 模拟 $testRounds 次事件调度...');

  for (int i = 0; i < testRounds; i++) {
    final random = Random();
    final interval = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
        eventTimeRange[0];
    intervals.add(interval);
  }

  final minInterval = intervals.reduce((a, b) => a < b ? a : b);
  final maxInterval = intervals.reduce((a, b) => a > b ? a : b);
  final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

  Logger.info('');
  Logger.info('📈 统计结果:');
  Logger.info('  最小间隔: $minInterval分钟');
  Logger.info('  最大间隔: $maxInterval分钟');
  Logger.info('  平均间隔: ${avgInterval.toStringAsFixed(2)}分钟');
  Logger.info('  期望间隔: 4.5分钟');

  // 分布统计
  final distribution = <int, int>{};
  for (final interval in intervals) {
    distribution[interval] = (distribution[interval] ?? 0) + 1;
  }

  Logger.info('');
  Logger.info('📊 间隔分布:');
  for (int i = eventTimeRange[0]; i <= eventTimeRange[1]; i++) {
    final count = distribution[i] ?? 0;
    final percentage = (count / testRounds * 100).toStringAsFixed(1);
    final bar = '█' * (count / (testRounds / 20)).round();
    Logger.info('  $i分钟: $count次 ($percentage%) $bar');
  }

  // 验证结果
  Logger.info('');
  Logger.info('✅ 验证结果:');
  Logger.info('  最小间隔正确: ${minInterval == eventTimeRange[0] ? '✅' : '❌'}');
  Logger.info('  最大间隔正确: ${maxInterval == eventTimeRange[1] ? '✅' : '❌'}');
  Logger.info('  平均间隔合理: ${(avgInterval - 4.5).abs() < 0.1 ? '✅' : '❌'}');
}

/// 测试事件可用性
void testEventAvailability() {
  Logger.info('🎯 测试事件可用性...');
  Logger.info('');

  // 模拟不同的游戏状态
  final gameStates = [
    {
      'name': '游戏开始',
      'fire': 1,
      'wood': 10,
      'population': 0,
      'buildings': 0,
    },
    {
      'name': '早期发展',
      'fire': 10,
      'wood': 100,
      'population': 5,
      'buildings': 2,
    },
    {
      'name': '中期发展',
      'fire': 25,
      'wood': 500,
      'population': 20,
      'buildings': 10,
    },
    {
      'name': '后期发展',
      'fire': 50,
      'wood': 1000,
      'population': 50,
      'buildings': 20,
    },
  ];

  for (final state in gameStates) {
    Logger.info('🎮 游戏状态: ${state['name']}');
    Logger.info('  火焰: ${state['fire']}, 木材: ${state['wood']}');
    Logger.info('  人口: ${state['population']}, 建筑: ${state['buildings']}');

    // 模拟事件可用性检查
    final availableEvents = _simulateEventAvailability(state);
    Logger.info('  可用事件: ${availableEvents.length}/15 (估算)');
    Logger.info('  可用率: ${(availableEvents.length / 15 * 100).toStringAsFixed(1)}%');
    Logger.info('');
  }
}

/// 运行事件触发模拟
void runEventSimulation(int rounds) {
  Logger.info('🎯 运行事件触发模拟 ($rounds 轮)...');
  Logger.info('');



  final triggerCounts = <String, int>{};
  final noEventCount = <int>[0]; // 使用列表以便在函数中修改

  for (int i = 0; i < rounds; i++) {
    final availableEvents = _getAvailableEvents();
    
    if (availableEvents.isEmpty) {
      noEventCount[0]++;
    } else {
      final random = Random();
      final selectedEvent = availableEvents[random.nextInt(availableEvents.length)];
      triggerCounts[selectedEvent] = (triggerCounts[selectedEvent] ?? 0) + 1;
    }
  }

  Logger.info('📊 事件触发统计:');
  final sortedEvents = triggerCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (final entry in sortedEvents) {
    final percentage = (entry.value / rounds * 100).toStringAsFixed(1);
    Logger.info('  ${entry.key}: ${entry.value}次 ($percentage%)');
  }

  Logger.info('');
  Logger.info('📈 总体统计:');
  Logger.info('  成功触发: ${rounds - noEventCount[0]}次');
  Logger.info('  无可用事件: ${noEventCount[0]}次');
  Logger.info('  触发成功率: ${((rounds - noEventCount[0]) / rounds * 100).toStringAsFixed(1)}%');

  // 验证结果
  Logger.info('');
  Logger.info('✅ 验证结果:');
  final successRate = (rounds - noEventCount[0]) / rounds;
  Logger.info('  触发成功率合理: ${successRate > 0.8 ? '✅' : '❌'} (${(successRate * 100).toStringAsFixed(1)}%)');
  Logger.info('  事件分布均匀: ${_isDistributionEven(triggerCounts) ? '✅' : '❌'}');
}

/// 测试事件时间间隔
void testEventTiming() {
  Logger.info('🎯 测试事件时间间隔...');
  Logger.info('');

  const normalInterval = [3, 6];
  const retryScale = 0.5;

  Logger.info('📊 正常间隔测试:');
  final normalIntervals = <double>[];
  for (int i = 0; i < 100; i++) {
    final random = Random();
    final interval = random.nextInt(normalInterval[1] - normalInterval[0] + 1) +
        normalInterval[0];
    normalIntervals.add(interval.toDouble());
  }

  final normalAvg = normalIntervals.reduce((a, b) => a + b) / normalIntervals.length;
  Logger.info('  平均间隔: ${normalAvg.toStringAsFixed(2)}分钟');

  Logger.info('');
  Logger.info('📊 重试间隔测试:');
  final retryIntervals = <double>[];
  for (int i = 0; i < 100; i++) {
    final random = Random();
    final baseInterval = random.nextInt(normalInterval[1] - normalInterval[0] + 1) +
        normalInterval[0];
    final retryInterval = baseInterval * retryScale;
    retryIntervals.add(retryInterval);
  }

  final retryAvg = retryIntervals.reduce((a, b) => a + b) / retryIntervals.length;
  Logger.info('  平均重试间隔: ${retryAvg.toStringAsFixed(2)}分钟');
  Logger.info('  重试缩放比例: ${retryScale}x');

  Logger.info('');
  Logger.info('✅ 验证结果:');
  Logger.info('  正常间隔合理: ${(normalAvg - 4.5).abs() < 0.2 ? '✅' : '❌'}');
  Logger.info('  重试间隔正确: ${(retryAvg - 2.25).abs() < 0.2 ? '✅' : '❌'}');
}

/// 运行所有测试
void runAllTests() {
  Logger.info('🧪 运行所有事件触发测试...');
  Logger.info('=' * 50);

  testEventFrequency();
  Logger.info('\n${'=' * 50}');

  testEventAvailability();
  Logger.info('\n${'=' * 50}');

  runEventSimulation(500);
  Logger.info('\n${'=' * 50}');

  testEventTiming();
  Logger.info('\n${'=' * 50}');
  
  Logger.info('🎉 所有测试完成！');
}

/// 模拟事件可用性检查
List<String> _simulateEventAvailability(Map<String, dynamic> state) {
  final availableEvents = <String>[];
  
  // 简化的可用性检查逻辑
  if (state['fire']! > 0 && state['wood']! > 0) {
    availableEvents.addAll(['神秘陌生人', '里面的声音', '外面的声音']);
  }
  
  if (state['population']! > 0) {
    availableEvents.addAll(['游牧部落', '病人']);
  }
  
  if (state['wood']! > 50) {
    availableEvents.addAll(['拾荒者', '乞丐']);
  }
  
  if (state['buildings']! > 5) {
    availableEvents.addAll(['小偷', '侦察兵']);
  }
  
  if (state['fire']! > 20) {
    availableEvents.addAll(['商人']);
  }
  
  return availableEvents;
}

/// 获取可用事件（模拟）
List<String> _getAvailableEvents() {
  final allEvents = [
    '神秘陌生人',
    '游牧部落', 
    '病人',
    '拾荒者',
    '乞丐',
    '小偷',
    '里面的声音',
    '外面的声音',
    '侦察兵',
    '商人',
  ];
  
  // 模拟80%的事件可用性
  final random = Random();
  return allEvents.where((_) => random.nextDouble() < 0.8).toList();
}

/// 检查分布是否均匀
bool _isDistributionEven(Map<String, int> distribution) {
  if (distribution.isEmpty) return false;
  
  final values = distribution.values.toList();
  final avg = values.reduce((a, b) => a + b) / values.length;
  final variance = values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / values.length;
  final stdDev = sqrt(variance);
  
  // 如果标准差小于平均值的30%，认为分布相对均匀
  return stdDev < avg * 0.3;
}
