import 'dart:io';
import 'package:a_dark_room_new/core/logger.dart';

/// 自动化测试覆盖率运行工具
///
/// 功能：
/// 1. 运行所有测试
/// 2. 生成覆盖率报告
/// 3. 检查覆盖率阈值
/// 4. 输出详细报告
void main(List<String> args) async {
  Logger.info('🚀 开始自动化测试覆盖率检查...');

  final options = parseArgs(args);

  try {
    // 1. 运行测试
    final testResults = await runTests(options);

    // 2. 生成覆盖率报告
    await generateCoverageReport();

    // 3. 检查覆盖率阈值
    final coverageCheck =
        await checkCoverageThreshold(options['threshold'] ?? 80);

    // 4. 输出结果
    printResults(testResults, coverageCheck);

    // 5. 退出码
    final exitCode = testResults['success'] && coverageCheck['passed'] ? 0 : 1;
    exit(exitCode);
  } catch (e) {
    Logger.info('❌ 自动化测试失败: $e');
    exit(1);
  }
}

/// 解析命令行参数
Map<String, dynamic> parseArgs(List<String> args) {
  final options = <String, dynamic>{
    'verbose': false,
    'threshold': 80,
    'category': 'all',
    'generateReport': true,
  };

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--verbose':
      case '-v':
        options['verbose'] = true;
        break;
      case '--threshold':
      case '-t':
        if (i + 1 < args.length) {
          options['threshold'] = int.tryParse(args[i + 1]) ?? 80;
          i++;
        }
        break;
      case '--category':
      case '-c':
        if (i + 1 < args.length) {
          options['category'] = args[i + 1];
          i++;
        }
        break;
      case '--no-report':
        options['generateReport'] = false;
        break;
      case '--help':
      case '-h':
        printUsage();
        exit(0);
    }
  }

  return options;
}

/// 打印使用说明
void printUsage() {
  Logger.info('自动化测试覆盖率工具');
  Logger.info('');
  Logger.info('用法: dart test/run_coverage_tests.dart [选项]');
  Logger.info('');
  Logger.info('选项:');
  Logger.info('  -v, --verbose        详细输出');
  Logger.info('  -t, --threshold N    覆盖率阈值 (默认: 80)');
  Logger.info('  -c, --category CAT   测试分类 (all|core|modules|ui)');
  Logger.info('  --no-report          不生成覆盖率报告');
  Logger.info('  -h, --help           显示帮助');
}

/// 运行测试
Future<Map<String, dynamic>> runTests(Map<String, dynamic> options) async {
  Logger.info('🧪 运行测试...');

  final category = options['category'] as String;
  final verbose = options['verbose'] as bool;

  List<String> testFiles;

  switch (category) {
    case 'core':
      testFiles = [
        'test/state_manager_simple_test.dart',
        'test/engine_test.dart',
        'test/localization_test.dart',
        'test/notification_manager_simple_test.dart',
        'test/audio_engine_simple_test.dart',
      ];
      break;
    case 'modules':
      testFiles = [
        'test/room_module_test.dart',
        'test/outside_module_test.dart',
      ];
      break;
    case 'ui':
      testFiles = [
        'test/armor_button_verification_test.dart',
        'test/ruined_city_leave_buttons_test.dart',
      ];
      break;
    case 'all':
    default:
      testFiles = ['test/all_tests.dart'];
      break;
  }

  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;
  final failedTestDetails = <String>[];

  for (final testFile in testFiles) {
    if (verbose) {
      Logger.info('  运行: $testFile');
    }

    final result = await Process.run(
      'dart',
      ['test', testFile],
      workingDirectory: Directory.current.path,
    );

    // 解析测试结果
    final output = result.stdout as String;
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.contains('+') && line.contains(':')) {
        // 解析测试计数
        final match = RegExp(r'\+(\d+)').firstMatch(line);
        if (match != null) {
          final count = int.parse(match.group(1)!);
          totalTests += count;
          if (result.exitCode == 0) {
            passedTests += count;
          }
        }
      }

      if (line.contains('-') && line.contains(':')) {
        // 解析失败测试
        final match = RegExp(r'-(\d+)').firstMatch(line);
        if (match != null) {
          final count = int.parse(match.group(1)!);
          failedTests += count;
        }
      }
    }

    if (result.exitCode != 0) {
      failedTestDetails.add('$testFile: ${result.stderr}');
      if (verbose) {
        Logger.info('    ❌ 失败');
        Logger.info('    错误: ${result.stderr}');
      }
    } else {
      if (verbose) {
        Logger.info('    ✅ 通过');
      }
    }
  }

  final success = failedTests == 0;

  Logger.info('📊 测试结果:');
  Logger.info('  总测试数: $totalTests');
  Logger.info('  通过: $passedTests');
  Logger.info('  失败: $failedTests');

  if (!success && verbose) {
    Logger.info('');
    Logger.info('失败详情:');
    for (final detail in failedTestDetails) {
      Logger.info('  $detail');
    }
  }

  return {
    'success': success,
    'total': totalTests,
    'passed': passedTests,
    'failed': failedTests,
    'details': failedTestDetails,
  };
}

/// 生成覆盖率报告
Future<void> generateCoverageReport() async {
  Logger.info('📋 生成覆盖率报告...');

  final result = await Process.run(
    'dart',
    ['test/simple_coverage_tool.dart'],
    workingDirectory: Directory.current.path,
  );

  if (result.exitCode != 0) {
    Logger.info('⚠️ 覆盖率报告生成失败: ${result.stderr}');
  } else {
    Logger.info('✅ 覆盖率报告已生成');
  }
}

/// 检查覆盖率阈值
Future<Map<String, dynamic>> checkCoverageThreshold(int threshold) async {
  Logger.info('🎯 检查覆盖率阈值 ($threshold%)...');

  try {
    final reportFile = File('docs/test_coverage_report.md');
    if (!await reportFile.exists()) {
      return {
        'passed': false,
        'actual': 0,
        'threshold': threshold,
        'message': '覆盖率报告文件不存在',
      };
    }

    final content = await reportFile.readAsString();

    // 解析覆盖率百分比
    final match = RegExp(r'已覆盖文件数.*?(\d+)%').firstMatch(content);
    if (match == null) {
      return {
        'passed': false,
        'actual': 0,
        'threshold': threshold,
        'message': '无法解析覆盖率数据',
      };
    }

    final actualCoverage = int.parse(match.group(1)!);
    final passed = actualCoverage >= threshold;

    if (passed) {
      Logger.info('✅ 覆盖率检查通过: $actualCoverage% >= $threshold%');
    } else {
      Logger.info('❌ 覆盖率检查失败: $actualCoverage% < $threshold%');
    }

    return {
      'passed': passed,
      'actual': actualCoverage,
      'threshold': threshold,
      'message': passed ? '覆盖率达标' : '覆盖率不足',
    };
  } catch (e) {
    return {
      'passed': false,
      'actual': 0,
      'threshold': threshold,
      'message': '检查覆盖率时出错: $e',
    };
  }
}

/// 打印最终结果
void printResults(
    Map<String, dynamic> testResults, Map<String, dynamic> coverageCheck) {
  Logger.info('');
  Logger.info('🏁 最终结果:');
  Logger.info('================');

  // 测试结果
  final testSuccess = testResults['success'] as bool;
  final testIcon = testSuccess ? '✅' : '❌';
  Logger.info(
      '$testIcon 测试: ${testResults['passed']}/${testResults['total']} 通过');

  // 覆盖率结果
  final coverageSuccess = coverageCheck['passed'] as bool;
  final coverageIcon = coverageSuccess ? '✅' : '❌';
  Logger.info(
      '$coverageIcon 覆盖率: ${coverageCheck['actual']}% (阈值: ${coverageCheck['threshold']}%)');

  // 总体结果
  final overallSuccess = testSuccess && coverageSuccess;
  final overallIcon = overallSuccess ? '🎉' : '💥';
  final overallMessage = overallSuccess ? '所有检查通过!' : '存在问题需要修复';

  Logger.info('');
  Logger.info('$overallIcon $overallMessage');

  if (!overallSuccess) {
    Logger.info('');
    Logger.info('建议:');
    if (!testSuccess) {
      Logger.info('- 修复失败的测试');
    }
    if (!coverageSuccess) {
      Logger.info('- 添加更多测试以提高覆盖率');
      Logger.info('- 查看 docs/test_coverage_report.md 了解详情');
    }
  }
}
