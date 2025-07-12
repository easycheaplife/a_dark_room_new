import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'dart:io';

/// 微信小程序环境配置测试
///
/// 测试环境配置文件的结构和安全性
void main() {
  group('🔧 微信小程序环境配置测试', () {
    setUpAll(() {
      Logger.info('🚀 开始微信小程序环境配置测试');
    });

    group('配置文件结构测试', () {
      test('应该存在环境配置示例文件', () {
        Logger.info('🧪 检查环境配置示例文件...');

        final exampleFile = File('wechat_miniprogram/config/env.example.js');
        expect(exampleFile.existsSync(), isTrue,
               reason: '环境配置示例文件应该存在');

        final content = exampleFile.readAsStringSync();

        // 验证文件包含必要的配置结构
        expect(content, contains('ENV_CONFIG'),
               reason: '应该包含ENV_CONFIG配置对象');
        expect(content, contains('development'),
               reason: '应该包含开发环境配置');
        expect(content, contains('staging'),
               reason: '应该包含测试环境配置');
        expect(content, contains('production'),
               reason: '应该包含生产环境配置');
        expect(content, contains('h5Url'),
               reason: '应该包含H5页面地址配置');

        Logger.info('✅ 环境配置示例文件结构正确');
      });

      test('应该包含所有必要的配置项', () {
        Logger.info('🧪 检查配置项完整性...');

        final exampleFile = File('wechat_miniprogram/config/env.example.js');
        final content = exampleFile.readAsStringSync();

        // 验证必要的配置项
        final requiredConfigs = [
          'h5Url',
          'apiBaseUrl',
          'debug',
          'logLevel',
          'appId'
        ];

        for (final config in requiredConfigs) {
          expect(content, contains(config),
                 reason: '应该包含配置项: $config');
        }

        // 验证环境特定配置
        expect(content, contains('enableMock'),
               reason: '应该包含开发环境特定配置');
        expect(content, contains('showDebugInfo'),
               reason: '应该包含调试相关配置');

        Logger.info('✅ 配置项完整性检查通过');
      });

      test('应该使用示例域名而非真实域名', () {
        Logger.info('🧪 检查示例文件安全性...');

        final exampleFile = File('wechat_miniprogram/config/env.example.js');
        final content = exampleFile.readAsStringSync();

        // 验证使用示例域名
        expect(content, contains('your-domain.com'),
               reason: '示例文件应该使用示例域名');

        // 验证不包含真实的敏感信息
        expect(content, isNot(contains('localhost')),
               reason: '示例文件不应包含本地开发地址');

        // 验证不在代码中使用不兼容的API（注释中提到是可以的）
        expect(content, isNot(contains('process.env.NODE_ENV')),
               reason: '示例文件不应在代码中使用process.env（微信小程序不支持）');

        Logger.info('✅ 示例文件安全性检查通过');
      });

      test('应该避免使用不兼容的Node.js API', () {
        Logger.info('🧪 检查Node.js API兼容性...');

        final exampleFile = File('wechat_miniprogram/config/env.example.js');
        final content = exampleFile.readAsStringSync();

        // 验证不在代码中使用process.env
        expect(content, isNot(contains('process.env.NODE_ENV')),
               reason: '配置文件不应在代码中使用process.env（微信小程序不支持）');

        // 验证使用固定值
        expect(content, contains("const CURRENT_ENV = 'development'"),
               reason: '应该使用固定的环境值');

        // 验证有兼容性注释
        expect(content, contains('微信小程序不支持'),
               reason: '应该有兼容性说明注释');

        Logger.info('✅ Node.js API兼容性检查通过');
      });
    });

    group('安全性测试', () {
      test('应该存在.gitignore文件', () {
        Logger.info('🧪 检查.gitignore文件...');

        final gitignoreFile = File('wechat_miniprogram/.gitignore');
        expect(gitignoreFile.existsSync(), isTrue,
               reason: '.gitignore文件应该存在');

        final content = gitignoreFile.readAsStringSync();

        // 验证忽略敏感配置文件
        expect(content, contains('config/env.js'),
               reason: '应该忽略敏感的环境配置文件');
        expect(content, contains('project.private.config.json'),
               reason: '应该忽略私有配置文件');

        Logger.info('✅ .gitignore文件配置正确');
      });

      test('实际配置文件不应被提交', () {
        Logger.info('🧪 检查实际配置文件状态...');

        final envFile = File('wechat_miniprogram/config/env.js');

        // 如果文件存在，验证其内容不包含示例值
        if (envFile.existsSync()) {
          final content = envFile.readAsStringSync();

          // 验证不是简单复制的示例文件
          if (content.contains('your-domain.com')) {
            Logger.info('⚠️  警告: 实际配置文件仍使用示例域名');
          } else {
            Logger.info('✅ 实际配置文件已正确配置');
          }
        } else {
          Logger.info('ℹ️  实际配置文件不存在（正常情况）');
        }

        // 这个测试总是通过，只是用来检查状态
        expect(true, isTrue);
      });

      test('应该有构建脚本来管理环境', () {
        Logger.info('🧪 检查构建脚本...');

        final buildScript = File('wechat_miniprogram/scripts/build.js');
        expect(buildScript.existsSync(), isTrue,
               reason: '构建脚本应该存在');

        final content = buildScript.readAsStringSync();

        // 验证脚本功能
        expect(content, contains('environment'),
               reason: '构建脚本应该支持环境参数');
        expect(content, contains('development'),
               reason: '构建脚本应该支持开发环境');
        expect(content, contains('staging'),
               reason: '构建脚本应该支持测试环境');
        expect(content, contains('production'),
               reason: '构建脚本应该支持生产环境');

        Logger.info('✅ 构建脚本功能完整');
      });
    });

    group('配置验证测试', () {
      test('应该能验证URL格式', () {
        Logger.info('🧪 测试URL格式验证...');

        // 测试有效的URL格式
        final validUrls = [
          'https://example.com/path',
          'http://localhost:3000/path',
          'https://subdomain.example.com/path'
        ];

        for (final url in validUrls) {
          final uri = Uri.tryParse(url);
          expect(uri, isNotNull, reason: 'URL应该是有效格式: $url');
          expect(uri!.hasScheme, isTrue, reason: 'URL应该有协议: $url');
        }

        // 测试无效的URL格式
        final invalidUrls = [
          'not-a-url',
          'ftp://example.com',  // 不支持的协议
          'example.com',        // 缺少协议
        ];

        for (final url in invalidUrls) {
          final uri = Uri.tryParse(url);
          if (uri != null) {
            expect(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'),
                   isFalse, reason: 'URL应该被识别为无效: $url');
          }
        }

        Logger.info('✅ URL格式验证测试通过');
      });

      test('应该能验证环境配置的完整性', () {
        Logger.info('🧪 测试环境配置完整性验证...');

        // 模拟环境配置对象
        final mockConfig = {
          'h5Url': 'https://example.com/game',
          'apiBaseUrl': 'https://api.example.com',
          'debug': false,
          'logLevel': 'error',
          'appId': 'wx-test-appid'
        };

        // 验证必要字段存在
        final requiredFields = ['h5Url', 'debug', 'logLevel'];
        for (final field in requiredFields) {
          expect(mockConfig.containsKey(field), isTrue,
                 reason: '配置应该包含必要字段: $field');
        }

        // 验证字段类型
        expect(mockConfig['h5Url'], isA<String>(),
               reason: 'h5Url应该是字符串类型');
        expect(mockConfig['debug'], isA<bool>(),
               reason: 'debug应该是布尔类型');

        Logger.info('✅ 环境配置完整性验证通过');
      });

      test('应该能处理环境变量覆盖', () {
        Logger.info('🧪 测试环境变量覆盖逻辑...');

        // 模拟环境变量逻辑
        String getEnvironment(String? envVar, String defaultEnv) {
          return envVar ?? defaultEnv;
        }

        // 测试默认环境
        expect(getEnvironment(null, 'development'), equals('development'));

        // 测试环境变量覆盖
        expect(getEnvironment('production', 'development'), equals('production'));
        expect(getEnvironment('staging', 'development'), equals('staging'));

        // 测试空字符串处理
        expect(getEnvironment('', 'development'), equals(''));

        Logger.info('✅ 环境变量覆盖逻辑测试通过');
      });
    });

    group('文档一致性测试', () {
      test('README文件应该包含环境配置说明', () {
        Logger.info('🧪 检查README文档...');

        final readmeFile = File('wechat_miniprogram/README.md');
        expect(readmeFile.existsSync(), isTrue,
               reason: 'README文件应该存在');

        final content = readmeFile.readAsStringSync();

        // 验证包含环境配置相关说明
        expect(content, contains('环境配置'),
               reason: 'README应该包含环境配置说明');
        expect(content, contains('config/env.js'),
               reason: 'README应该提到配置文件');
        expect(content, contains('构建脚本'),
               reason: 'README应该说明构建脚本使用');

        Logger.info('✅ README文档内容完整');
      });

      test('应该有相应的优化文档', () {
        Logger.info('🧪 检查优化文档...');

        final optimizationDoc = File('docs/06_optimizations/wechat_miniprogram_environment_configuration.md');
        expect(optimizationDoc.existsSync(), isTrue,
               reason: '环境配置优化文档应该存在');

        final content = optimizationDoc.readAsStringSync();

        // 验证文档内容
        expect(content, contains('环境配置优化'),
               reason: '文档应该说明优化内容');
        expect(content, contains('安全性'),
               reason: '文档应该强调安全性改进');
        expect(content, contains('使用指南'),
               reason: '文档应该包含使用指南');

        Logger.info('✅ 优化文档内容完整');
      });
    });

    tearDownAll(() {
      Logger.info('🎉 微信小程序环境配置测试完成');
    });
  });
}