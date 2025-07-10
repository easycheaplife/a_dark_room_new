import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 测试运行器功能验证测试
///
/// 验证test/run_tests.dart的基本功能和可用性
void main() {
  group('🧪 测试运行器功能验证', () {
    late String testRunnerPath;

    setUpAll(() {
      testRunnerPath = 'test/run_tests.dart';
      Logger.info('🚀 开始测试运行器功能验证');
    });

    test('测试运行器文件应该存在', () {
      Logger.info('🧪 验证测试运行器文件存在');

      final file = File(testRunnerPath);
      expect(file.existsSync(), true, reason: '测试运行器文件应该存在于test目录下');

      Logger.info('✅ 测试运行器文件存在验证通过');
    });

    test('测试运行器文件应该包含正确的帮助信息', () async {
      Logger.info('🧪 验证测试运行器帮助信息内容');

      final file = File(testRunnerPath);
      final content = await file.readAsString();

      expect(content, contains('A Dark Room 简化测试运行器'), reason: '应该包含标题');
      expect(content, contains('用法:'), reason: '应该包含用法说明');
      expect(content, contains('dart test/run_tests.dart'),
          reason: '应该显示正确的路径');
      expect(content, contains('quick'), reason: '应该包含quick命令');
      expect(content, contains('core'), reason: '应该包含core命令');
      expect(content, contains('integration'), reason: '应该包含integration命令');
      expect(content, contains('all'), reason: '应该包含all命令');
      expect(content, contains('list'), reason: '应该包含list命令');

      Logger.info('✅ 测试运行器帮助信息内容验证通过');
    });

    test('测试运行器应该包含测试套件定义', () async {
      Logger.info('🧪 验证测试运行器套件定义');

      final file = File(testRunnerPath);
      final content = await file.readAsString();

      expect(content, contains('可用的测试套件'), reason: '应该包含套件列表标题');
      expect(content, contains('快速测试套件'), reason: '应该包含quick套件描述');
      expect(content, contains('核心系统测试'), reason: '应该包含core套件描述');
      expect(content, contains('集成测试'), reason: '应该包含integration套件描述');
      expect(content, contains('所有测试'), reason: '应该包含all套件描述');

      Logger.info('✅ 测试运行器套件定义验证通过');
    });

    test('测试运行器应该包含错误处理逻辑', () async {
      Logger.info('🧪 验证测试运行器错误处理逻辑');

      final file = File(testRunnerPath);
      final content = await file.readAsString();

      expect(content, contains('未知命令'), reason: '应该包含未知命令错误处理');
      expect(content, contains('测试运行失败'), reason: '应该包含失败处理');
      expect(content, contains('exit(1)'), reason: '应该包含错误退出逻辑');

      Logger.info('✅ 测试运行器错误处理逻辑验证通过');
    });

    test('测试运行器文件应该包含正确的路径引用', () async {
      Logger.info('🧪 验证测试运行器路径引用');

      final file = File(testRunnerPath);
      final content = await file.readAsString();

      // 验证文件内容包含正确的路径引用
      expect(content, contains('dart test/run_tests.dart'),
          reason: '应该包含正确的使用路径');
      expect(content, contains('test/quick_test_suite.dart'),
          reason: '应该包含正确的测试文件路径');
      expect(content, contains('test/simple_integration_test.dart'),
          reason: '应该包含正确的集成测试路径');

      Logger.info('✅ 测试运行器路径引用验证通过');
    });

    test('测试运行器应该能够检测测试文件存在性', () async {
      Logger.info('🧪 验证测试运行器文件检测功能');

      // 验证关键测试文件存在
      final quickTestFile = File('test/quick_test_suite.dart');
      final integrationTestFile = File('test/simple_integration_test.dart');

      expect(quickTestFile.existsSync(), true,
          reason: 'quick_test_suite.dart应该存在');
      expect(integrationTestFile.existsSync(), true,
          reason: 'simple_integration_test.dart应该存在');

      Logger.info('✅ 测试运行器文件检测功能验证通过');
    });

    tearDownAll(() {
      Logger.info('🏁 测试运行器功能验证完成');
    });
  });
}
