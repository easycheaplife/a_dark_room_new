import 'dart:io';
import 'dart:convert';
import '../lib/core/logger.dart';

/// 测试覆盖率分析工具
///
/// 功能：
/// 1. 扫描源代码文件
/// 2. 扫描测试文件
/// 3. 生成覆盖率报告
/// 4. 识别缺失测试的文件
class TestCoverageTool {
  static const String sourceDir = 'lib';
  static const String testDir = 'test';
  static const String reportFile = 'docs/test_coverage_report.md';

  /// 生成测试覆盖率报告
  static Future<void> generateCoverageReport() async {
    Logger.info('🔍 开始生成测试覆盖率报告...');

    try {
      // 扫描源代码文件
      final sourceFiles = await _scanSourceFiles();
      Logger.info('📁 发现源代码文件: ${sourceFiles.length} 个');

      // 扫描测试文件
      final testFiles = await _scanTestFiles();
      Logger.info('🧪 发现测试文件: ${testFiles.length} 个');

      // 分析覆盖率
      final coverage = _analyzeCoverage(sourceFiles, testFiles);

      // 生成报告
      await _generateReport(coverage);

      Logger.info('✅ 测试覆盖率报告生成完成: $reportFile');
    } catch (e) {
      Logger.info('❌ 生成测试覆盖率报告失败: $e');
    }
  }

  /// 扫描源代码文件
  static Future<List<String>> _scanSourceFiles() async {
    final sourceFiles = <String>[];
    final libDir = Directory(sourceDir);

    if (!await libDir.exists()) {
      throw Exception('源代码目录不存在: $sourceDir');
    }

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = entity.path
            .replaceFirst('$sourceDir\\', '')
            .replaceFirst('$sourceDir/', '');
        sourceFiles.add(relativePath);
      }
    }

    return sourceFiles;
  }

  /// 扫描测试文件
  static Future<List<String>> _scanTestFiles() async {
    final testFiles = <String>[];
    final testDirEntity = Directory(testDir);

    if (!await testDirEntity.exists()) {
      throw Exception('测试目录不存在: $testDir');
    }

    await for (final entity in testDirEntity.list(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('test_config.dart') &&
          !entity.path.endsWith('all_tests.dart') &&
          !entity.path.endsWith('test_runner.dart') &&
          !entity.path.endsWith('test_coverage_tool.dart')) {
        final relativePath = entity.path
            .replaceFirst('$testDir\\', '')
            .replaceFirst('$testDir/', '');
        testFiles.add(relativePath);
      }
    }

    return testFiles;
  }

  /// 分析测试覆盖率
  static Map<String, dynamic> _analyzeCoverage(
      List<String> sourceFiles, List<String> testFiles) {
    final coverage = <String, dynamic>{
      'totalSourceFiles': sourceFiles.length,
      'totalTestFiles': testFiles.length,
      'coveredFiles': <String>[],
      'uncoveredFiles': <String>[],
      'testsByCategory': <String, List<String>>{},
      'coverageByModule': <String, Map<String, dynamic>>{},
    };

    // 按模块分类源文件
    final moduleFiles = <String, List<String>>{};
    for (final file in sourceFiles) {
      final parts = file.split('/');
      final module = parts.length > 1 ? parts[0] : 'root';
      moduleFiles.putIfAbsent(module, () => []).add(file);
    }

    // 分析每个模块的覆盖率
    for (final module in moduleFiles.keys) {
      final files = moduleFiles[module]!;
      final coveredInModule = <String>[];
      final uncoveredInModule = <String>[];

      for (final file in files) {
        final fileName = file.split('/').last.replaceAll('.dart', '');
        final hasTest = testFiles.any((test) =>
            test.contains(fileName) ||
            test.contains(module) ||
            _isFileTestedByIntegrationTest(file, testFiles));

        if (hasTest) {
          coveredInModule.add(file);
          (coverage['coveredFiles'] as List<String>).add(file);
        } else {
          uncoveredInModule.add(file);
          (coverage['uncoveredFiles'] as List<String>).add(file);
        }
      }

      final moduleTotal = files.length;
      final moduleCovered = coveredInModule.length;
      final modulePercentage =
          moduleTotal > 0 ? (moduleCovered / moduleTotal * 100).round() : 0;

      (coverage['coverageByModule']
          as Map<String, Map<String, dynamic>>)[module] = {
        'total': moduleTotal,
        'covered': moduleCovered,
        'uncovered': uncoveredInModule.length,
        'percentage': modulePercentage,
        'coveredFiles': coveredInModule,
        'uncoveredFiles': uncoveredInModule,
      };
    }

    // 按测试类型分类
    final testCategories = <String, List<String>>{
      '核心系统': [],
      '游戏模块': [],
      '事件系统': [],
      '地图系统': [],
      '背包系统': [],
      'UI系统': [],
      '资源系统': [],
      '太空系统': [],
      '音频系统': [],
      '其他': [],
    };

    for (final test in testFiles) {
      if (test.contains('state_manager') ||
          test.contains('engine') ||
          test.contains('localization') ||
          test.contains('notification') ||
          test.contains('audio_engine')) {
        testCategories['核心系统']!.add(test);
      } else if (test.contains('room') ||
          test.contains('outside') ||
          test.contains('world') ||
          test.contains('path') ||
          test.contains('fabricator') ||
          test.contains('ship')) {
        testCategories['游戏模块']!.add(test);
      } else if (test.contains('event')) {
        testCategories['事件系统']!.add(test);
      } else if (test.contains('landmarks') || test.contains('road')) {
        testCategories['地图系统']!.add(test);
      } else if (test.contains('torch') || test.contains('backpack')) {
        testCategories['背包系统']!.add(test);
      } else if (test.contains('button') || test.contains('ui')) {
        testCategories['UI系统']!.add(test);
      } else if (test.contains('water') || test.contains('crafting')) {
        testCategories['资源系统']!.add(test);
      } else if (test.contains('space') || test.contains('ship')) {
        testCategories['太空系统']!.add(test);
      } else if (test.contains('audio')) {
        testCategories['音频系统']!.add(test);
      } else {
        testCategories['其他']!.add(test);
      }
    }

    coverage['testsByCategory'] = testCategories;

    return coverage;
  }

  /// 检查文件是否被集成测试覆盖
  static bool _isFileTestedByIntegrationTest(
      String file, List<String> testFiles) {
    // 检查是否有相关的集成测试
    final fileName = file.split('/').last.replaceAll('.dart', '');
    return testFiles.any((test) =>
        test.contains('integration') && test.contains(fileName.toLowerCase()));
  }

  /// 生成报告文件
  static Future<void> _generateReport(Map<String, dynamic> coverage) async {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // 报告头部
    buffer.writeln('# 测试覆盖率报告');
    buffer.writeln('');
    buffer.writeln(
        '**生成时间**: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    buffer.writeln('**报告类型**: 自动化测试覆盖率分析');
    buffer.writeln('');

    // 总体统计
    final totalFiles = coverage['totalSourceFiles'] as int;
    final totalTests = coverage['totalTestFiles'] as int;
    final coveredFiles = (coverage['coveredFiles'] as List<String>).length;
    final overallPercentage =
        totalFiles > 0 ? (coveredFiles / totalFiles * 100).round() : 0;

    buffer.writeln('## 📊 总体覆盖率统计');
    buffer.writeln('');
    buffer.writeln('| 指标 | 数量 | 百分比 |');
    buffer.writeln('|------|------|--------|');
    buffer.writeln('| 源代码文件总数 | $totalFiles | 100% |');
    buffer.writeln('| 已覆盖文件数 | $coveredFiles | $overallPercentage% |');
    buffer.writeln(
        '| 未覆盖文件数 | ${totalFiles - coveredFiles} | ${100 - overallPercentage}% |');
    buffer.writeln('| 测试文件总数 | $totalTests | - |');
    buffer.writeln('');

    // 按模块统计
    buffer.writeln('## 🏗️ 模块覆盖率详情');
    buffer.writeln('');
    buffer.writeln('| 模块 | 总文件数 | 已覆盖 | 未覆盖 | 覆盖率 |');
    buffer.writeln('|------|----------|--------|--------|--------|');

    final modulesCoverage =
        coverage['coverageByModule'] as Map<String, Map<String, dynamic>>;
    for (final module in modulesCoverage.keys) {
      final data = modulesCoverage[module]!;
      buffer.writeln(
          '| $module | ${data['total']} | ${data['covered']} | ${data['uncovered']} | ${data['percentage']}% |');
    }
    buffer.writeln('');

    // 测试分类统计
    buffer.writeln('## 🧪 测试分类统计');
    buffer.writeln('');
    final testsByCategory =
        coverage['testsByCategory'] as Map<String, List<String>>;
    for (final category in testsByCategory.keys) {
      final tests = testsByCategory[category]!;
      if (tests.isNotEmpty) {
        buffer.writeln('### $category (${tests.length}个测试)');
        buffer.writeln('');
        for (final test in tests) {
          buffer.writeln('- `$test`');
        }
        buffer.writeln('');
      }
    }

    // 未覆盖文件列表
    final uncoveredFiles = coverage['uncoveredFiles'] as List<String>;
    if (uncoveredFiles.isNotEmpty) {
      buffer.writeln('## ⚠️ 未覆盖文件列表');
      buffer.writeln('');
      buffer.writeln('以下文件尚未有对应的测试：');
      buffer.writeln('');
      for (final file in uncoveredFiles) {
        buffer.writeln('- `$file`');
      }
      buffer.writeln('');
    }

    // 建议
    buffer.writeln('## 💡 改进建议');
    buffer.writeln('');
    if (overallPercentage < 80) {
      buffer.writeln('- 🔴 **覆盖率偏低**: 当前覆盖率为 $overallPercentage%，建议提升至80%以上');
    } else if (overallPercentage < 90) {
      buffer.writeln('- 🟡 **覆盖率良好**: 当前覆盖率为 $overallPercentage%，建议继续提升至90%以上');
    } else {
      buffer.writeln('- 🟢 **覆盖率优秀**: 当前覆盖率为 $overallPercentage%，请保持');
    }

    if (uncoveredFiles.isNotEmpty) {
      buffer
          .writeln('- 📝 **优先添加测试**: 为上述 ${uncoveredFiles.length} 个未覆盖文件添加测试');
    }

    buffer.writeln('- 🔄 **定期更新**: 建议每次代码变更后重新生成覆盖率报告');
    buffer.writeln('');

    // 写入文件
    final reportDir = Directory('docs');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    final reportFileEntity = File(reportFile);
    await reportFileEntity.writeAsString(buffer.toString());
  }
}

/// 命令行入口
void main(List<String> args) async {
  await TestCoverageTool.generateCoverageReport();
}
