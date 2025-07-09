import 'dart:io';

/// A Dark Room 简化测试运行器
///
/// 这是项目的主要测试入口，提供简单直观的测试运行功能
///
/// 使用方法：
/// dart run_tests.dart [命令]
void main(List<String> args) async {
  print('🎮 A Dark Room 简化测试运行器');
  print('=' * 60);

  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0].toLowerCase();

  try {
    switch (command) {
      case 'quick':
        await _runQuickTests();
        break;
      case 'core':
        await _runCoreTests();
        break;
      case 'integration':
        await _runIntegrationTests();
        break;
      case 'all':
        await _runAllTests();
        break;
      case 'list':
        _listTestSuites();
        break;
      case 'help':
      case '--help':
      case '-h':
        _printUsage();
        break;
      default:
        print('❌ 未知命令: $command');
        _printUsage();
        exit(1);
    }
  } catch (e) {
    print('❌ 测试运行失败: $e');
    exit(1);
  }
}

/// 打印使用说明
void _printUsage() {
  print('');
  print('用法: dart run_tests.dart <命令>');
  print('');
  print('命令:');
  print('  quick        - 运行快速测试套件 (推荐日常使用)');
  print('  core         - 运行核心系统测试');
  print('  integration  - 运行集成测试');
  print('  all          - 运行所有测试');
  print('  list         - 列出所有可用的测试套件');
  print('  help         - 显示此帮助信息');
  print('');
  print('示例:');
  print('  dart run_tests.dart quick');
  print('  dart run_tests.dart core');
  print('  dart run_tests.dart all');
}

/// 运行快速测试套件
Future<void> _runQuickTests() async {
  print('⚡ 运行快速测试套件');
  print('这是日常开发推荐的测试套件，运行时间约30秒');
  print('');

  final testFiles = [
    'test/quick_test_suite.dart',
    'test/simple_integration_test.dart',
  ];

  await _runTestFiles(testFiles, '快速测试套件');
}

/// 运行核心系统测试
Future<void> _runCoreTests() async {
  print('🎯 运行核心系统测试');
  print('测试所有核心系统功能');
  print('');

  final testFiles = [
    'test/state_manager_test.dart',
    'test/engine_test.dart',
    'test/localization_test.dart',
    'test/notification_manager_test.dart',
    'test/audio_engine_test.dart',
  ];

  await _runTestFiles(testFiles, '核心系统测试');
}

/// 运行集成测试
Future<void> _runIntegrationTests() async {
  print('🔗 运行集成测试');
  print('测试模块间交互和游戏流程');
  print('');

  final testFiles = [
    'test/simple_integration_test.dart',
    // 注意：以下测试使用Engine，在测试环境中会有音频插件警告，但功能正常
    // 'test/game_flow_integration_test.dart',
    // 'test/module_interaction_test.dart',
  ];

  await _runTestFiles(testFiles, '集成测试');
}

/// 运行所有测试
Future<void> _runAllTests() async {
  print('🚀 运行所有测试');
  print('这将运行项目中的所有测试，可能需要几分钟时间');
  print('⚠️  注意：测试中会出现音频插件错误，这是正常的（测试环境无音频支持）');
  print('📊 关注实际的逻辑错误，忽略 MissingPluginException 音频错误');
  print('');

  final result = await Process.run(
      'C:\\Users\\PC\\Downloads\\flutter\\bin\\flutter.bat', ['test']);
  _printTestResult('所有测试', result);
}

/// 列出所有测试套件
void _listTestSuites() {
  print('📋 可用的测试套件:');
  print('');

  final suites = {
    'quick': '快速测试套件 - 日常开发验证（30秒）',
    'core': '核心系统测试 - 基础功能验证（2分钟）',
    'integration': '集成测试 - 模块间交互验证（1分钟）',
    'all': '所有测试 - 完整测试验证（5分钟）',
  };

  for (final entry in suites.entries) {
    print('${entry.key}:');
    print('  描述: ${entry.value}');
    print('');
  }
}

/// 运行指定的测试文件列表
Future<void> _runTestFiles(List<String> testFiles, String suiteName) async {
  int totalFiles = 0;
  int passedFiles = 0;
  int failedFiles = 0;
  final failedFilesList = <String>[];

  for (final testFile in testFiles) {
    // 检查文件是否存在
    final file = File(testFile);
    if (!await file.exists()) {
      print('⚠️ 跳过不存在的文件: $testFile');
      continue;
    }

    totalFiles++;
    print('🧪 运行: ${testFile.split('/').last}');

    final result = await Process.run(
        'C:\\Users\\PC\\Downloads\\flutter\\bin\\flutter.bat',
        ['test', testFile, '--reporter=compact']);

    if (result.exitCode == 0) {
      passedFiles++;
      print('  ✅ 通过');
    } else {
      failedFiles++;
      failedFilesList.add(testFile);
      print('  ❌ 失败');
    }
  }

  // 打印总结
  print('');
  print('📊 $suiteName 结果:');
  print('  总文件数: $totalFiles');
  print('  通过: $passedFiles');
  print('  失败: $failedFiles');

  if (failedFilesList.isNotEmpty) {
    print('');
    print('❌ 失败的测试文件:');
    for (final file in failedFilesList) {
      print('  - ${file.split('/').last}');
    }
  }

  if (failedFiles == 0) {
    print('');
    print('🎉 $suiteName 全部通过!');
  } else {
    print('');
    print('💥 $suiteName 存在失败，请检查并修复');
    exit(1);
  }
}

/// 打印测试结果
void _printTestResult(String testName, ProcessResult result) {
  print('');
  print('📊 $testName 结果:');

  if (result.exitCode == 0) {
    print('✅ 测试通过');

    final output = result.stdout as String;
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('All tests passed!') || line.contains('+')) {
        print('  $line');
        break;
      }
    }
  } else {
    print('❌ 测试失败');
    print('退出代码: ${result.exitCode}');

    if (result.stderr != null && result.stderr.toString().isNotEmpty) {
      print('错误信息:');
      print(result.stderr);
    }

    if (result.stdout != null && result.stdout.toString().isNotEmpty) {
      print('输出信息:');
      print(result.stdout);
    }

    exit(1);
  }
}
