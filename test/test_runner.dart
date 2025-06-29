#!/usr/bin/env dart

import 'dart:io';

/// 简单的测试日志工具，避免依赖Flutter框架
class TestLogger {
  static void info(String message) {
    // ignore: avoid_print
    print(message);
  }
}

/// A Dark Room 测试运行器
/// 
/// 提供多种测试运行选项：
/// 1. 运行所有测试
/// 2. 运行特定分类的测试
/// 3. 运行单个测试文件
/// 4. 生成测试报告
void main(List<String> args) async {
  TestLogger.info('🧪 A Dark Room 测试运行器');
  TestLogger.info('=' * 50);

  if (args.isEmpty) {
    showUsage();
    return;
  }

  final command = args[0];
  switch (command) {
    case 'all':
      await runAllTests();
      break;
    case 'events':
      await runEventTests();
      break;
    case 'map':
      await runMapTests();
      break;
    case 'backpack':
      await runBackpackTests();
      break;
    case 'ui':
      await runUITests();
      break;
    case 'resources':
      await runResourceTests();
      break;
    case 'single':
      if (args.length < 2) {
        TestLogger.info('❌ 请指定要运行的测试文件');
        showUsage();
        return;
      }
      await runSingleTest(args[1]);
      break;
    case 'report':
      await generateTestReport();
      break;
    case 'help':
      showUsage();
      break;
    default:
      TestLogger.info('❌ 未知命令: $command');
      showUsage();
  }
}

void showUsage() {
  TestLogger.info('用法: dart test/test_runner.dart <command> [options]');
  TestLogger.info('');
  TestLogger.info('命令:');
  TestLogger.info('  all        - 运行所有测试');
  TestLogger.info('  events     - 运行事件系统测试');
  TestLogger.info('  map        - 运行地图系统测试');
  TestLogger.info('  backpack   - 运行背包系统测试');
  TestLogger.info('  ui         - 运行UI系统测试');
  TestLogger.info('  resources  - 运行资源系统测试');
  TestLogger.info('  single     - 运行单个测试文件');
  TestLogger.info('  report     - 生成测试报告');
  TestLogger.info('  help       - 显示帮助信息');
  TestLogger.info('');
  TestLogger.info('示例:');
  TestLogger.info('  dart test/test_runner.dart all');
  TestLogger.info('  dart test/test_runner.dart events');
  TestLogger.info('  dart test/test_runner.dart single event_frequency_test.dart');
}

/// 运行所有测试
Future<void> runAllTests() async {
  TestLogger.info('🚀 运行所有测试...');
  await _runFlutterTest('test/all_tests.dart');
}

/// 运行事件系统测试
Future<void> runEventTests() async {
  TestLogger.info('📅 运行事件系统测试...');
  final eventTests = [
    'test/event_frequency_test.dart',
    'test/event_localization_fix_test.dart',
    'test/event_trigger_test.dart',
  ];
  
  for (final test in eventTests) {
    await _runFlutterTest(test);
  }
}

/// 运行地图系统测试
Future<void> runMapTests() async {
  TestLogger.info('🗺️ 运行地图系统测试...');
  final mapTests = [
    'test/landmarks_test.dart',
    'test/road_generation_fix_test.dart',
  ];
  
  for (final test in mapTests) {
    await _runFlutterTest(test);
  }
}

/// 运行背包系统测试
Future<void> runBackpackTests() async {
  TestLogger.info('🎒 运行背包系统测试...');
  final backpackTests = [
    'test/torch_backpack_check_test.dart',
    'test/torch_backpack_simple_test.dart',
    'test/original_game_torch_requirements_test.dart',
  ];
  
  for (final test in backpackTests) {
    await _runFlutterTest(test);
  }
}

/// 运行UI系统测试
Future<void> runUITests() async {
  TestLogger.info('🏛️ 运行UI系统测试...');
  final uiTests = [
    'test/ruined_city_leave_buttons_test.dart',
  ];
  
  for (final test in uiTests) {
    await _runFlutterTest(test);
  }
}

/// 运行资源系统测试
Future<void> runResourceTests() async {
  TestLogger.info('💧 运行资源系统测试...');
  final resourceTests = [
    'test/water_capacity_test.dart',
  ];
  
  for (final test in resourceTests) {
    await _runFlutterTest(test);
  }
}

/// 运行单个测试文件
Future<void> runSingleTest(String testFile) async {
  TestLogger.info('🎯 运行单个测试: $testFile');
  
  // 确保文件路径正确
  final testPath = testFile.startsWith('test/') ? testFile : 'test/$testFile';
  
  // 检查文件是否存在
  final file = File(testPath);
  if (!await file.exists()) {
    TestLogger.info('❌ 测试文件不存在: $testPath');
    return;
  }
  
  await _runFlutterTest(testPath);
}

/// 生成测试报告
Future<void> generateTestReport() async {
  TestLogger.info('📊 生成测试报告...');
  
  // 运行所有测试并收集结果
  final result = await _runFlutterTestWithOutput('test/all_tests.dart');
  
  // 分析测试结果
  final lines = result.split('\n');
  int passedTests = 0;
  int failedTests = 0;
  final failedTestNames = <String>[];
  
  for (final line in lines) {
    if (line.contains('+') && line.contains(':')) {
      // 解析测试结果行
      final parts = line.split(' ');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].startsWith('+')) {
          final passed = int.tryParse(parts[i].substring(1)) ?? 0;
          passedTests += passed;
        }
        if (parts[i].startsWith('-')) {
          final failed = int.tryParse(parts[i].substring(1)) ?? 0;
          failedTests += failed;
        }
      }
    }
    if (line.contains('FAILED')) {
      failedTestNames.add(line.trim());
    }
  }
  
  // 输出报告
  TestLogger.info('');
  TestLogger.info('📋 测试报告');
  TestLogger.info('=' * 40);
  TestLogger.info('通过测试: $passedTests');
  TestLogger.info('失败测试: $failedTests');
  TestLogger.info('总测试数: ${passedTests + failedTests}');
  TestLogger.info('成功率: ${passedTests + failedTests > 0 ? ((passedTests / (passedTests + failedTests)) * 100).toStringAsFixed(1) : 0}%');
  
  if (failedTestNames.isNotEmpty) {
    TestLogger.info('');
    TestLogger.info('失败的测试:');
    for (final failedTest in failedTestNames) {
      TestLogger.info('  ❌ $failedTest');
    }
  }
  
  TestLogger.info('=' * 40);
}

/// 执行Flutter测试命令
Future<void> _runFlutterTest(String testPath) async {
  TestLogger.info('▶️  执行: flutter test $testPath');
  
  final result = await Process.run('flutter', ['test', testPath]);
  
  if (result.exitCode == 0) {
    TestLogger.info('✅ 测试通过: $testPath');
  } else {
    TestLogger.info('❌ 测试失败: $testPath');
    TestLogger.info('错误输出: ${result.stderr}');
  }
  
  // 输出测试结果
  if (result.stdout.toString().isNotEmpty) {
    TestLogger.info(result.stdout.toString());
  }
}

/// 执行Flutter测试命令并返回输出
Future<String> _runFlutterTestWithOutput(String testPath) async {
  final result = await Process.run('flutter', ['test', testPath]);
  return result.stdout.toString() + result.stderr.toString();
}
