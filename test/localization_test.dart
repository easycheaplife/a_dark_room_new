import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/localization.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// Localization 本地化系统测试
///
/// 测试覆盖范围：
/// 1. 本地化系统初始化
/// 2. 语言加载和切换
/// 3. 翻译功能和嵌套键值
/// 4. 参数替换和回退机制
/// 5. 语言持久化
void main() {
  group('🌐 Localization 本地化系统测试', () {
    late Localization localization;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 Localization 测试套件');
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localization = Localization();
      // 本地化状态会在init()时设置
    });

    tearDown(() {
      localization.dispose();
    });

    group('🔧 本地化初始化测试', () {
      test('应该正确初始化本地化系统', () async {
        Logger.info('🧪 测试本地化系统初始化');

        // 模拟中文语言文件
        const String mockChineseJson = '''
        {
          "ui": {
            "buttons": {
              "light_fire": "点火",
              "stoke_fire": "添柴"
            }
          },
          "buildings": {
            "trap": "陷阱",
            "cart": "手推车"
          }
        }
        ''';

        // 设置mock资源加载
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/lang/zh.json') {
            return utf8.encode(mockChineseJson).buffer.asByteData();
          }
          return null;
        });

        // 执行初始化
        await localization.init();

        // 验证初始化状态
        expect(localization.currentLanguage, equals('zh'));
        expect(localization.availableLanguages, isNotEmpty);
        expect(localization.availableLanguages.containsKey('zh'), isTrue);
        expect(localization.availableLanguages.containsKey('en'), isTrue);

        Logger.info('✅ 本地化系统初始化测试通过');
      });

      test('应该正确加载保存的语言设置', () async {
        Logger.info('🧪 测试保存的语言设置加载');

        // 设置保存的语言
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language', 'en');

        // 模拟英文语言文件
        const String mockEnglishJson = '''
        {
          "ui": {
            "buttons": {
              "light_fire": "Light Fire",
              "stoke_fire": "Stoke Fire"
            }
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/lang/en.json') {
            return utf8.encode(mockEnglishJson).buffer.asByteData();
          }
          return null;
        });

        await localization.init();

        // 验证语言被正确加载
        expect(localization.currentLanguage, equals('en'));

        Logger.info('✅ 保存的语言设置加载测试通过');
      });
    });

    group('🔄 语言切换测试', () {
      setUp(() async {
        // 设置mock语言文件
        const String mockChineseJson = '''
        {
          "ui": {"buttons": {"light_fire": "点火"}},
          "buildings": {"trap": "陷阱"}
        }
        ''';

        const String mockEnglishJson = '''
        {
          "ui": {"buttons": {"light_fire": "Light Fire"}},
          "buildings": {"trap": "Trap"}
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/lang/zh.json') {
            return utf8.encode(mockChineseJson).buffer.asByteData();
          } else if (key == 'assets/lang/en.json') {
            return utf8.encode(mockEnglishJson).buffer.asByteData();
          }
          return null;
        });

        await localization.init();
      });

      test('应该正确切换到不同语言', () async {
        Logger.info('🧪 测试语言切换');

        // 初始应该是中文
        expect(localization.currentLanguage, equals('zh'));
        expect(localization.translate('ui.buttons.light_fire'), equals('点火'));

        // 切换到英文
        await localization.switchLanguage('en');
        expect(localization.currentLanguage, equals('en'));
        expect(localization.translate('ui.buttons.light_fire'),
            equals('Light Fire'));

        // 切换回中文
        await localization.switchLanguage('zh');
        expect(localization.currentLanguage, equals('zh'));
        expect(localization.translate('ui.buttons.light_fire'), equals('点火'));

        Logger.info('✅ 语言切换测试通过');
      });

      test('应该正确处理无效语言', () async {
        Logger.info('🧪 测试无效语言处理');

        // 尝试切换到不存在的语言
        await localization.switchLanguage('invalid');

        // 应该回退到中文
        expect(localization.currentLanguage, equals('zh'));

        Logger.info('✅ 无效语言处理测试通过');
      });

      test('应该正确保存语言设置', () async {
        Logger.info('🧪 测试语言设置保存');

        // 切换语言
        await localization.switchLanguage('en');

        // 验证语言被保存
        final prefs = await SharedPreferences.getInstance();
        final savedLanguage = prefs.getString('language');
        expect(savedLanguage, equals('en'));

        Logger.info('✅ 语言设置保存测试通过');
      });
    });

    group('📝 翻译功能测试', () {
      setUp(() async {
        const String mockTranslationJson = '''
        {
          "ui": {
            "buttons": {
              "light_fire": "点火",
              "stoke_fire": "添柴"
            },
            "modules": {
              "room": "房间",
              "outside": "外部"
            }
          },
          "buildings": {
            "trap": "陷阱",
            "cart": "手推车"
          },
          "crafting": {
            "wood_needed": "需要 {0} 个木材",
            "multiple_items": "制作 {0} 个 {1}"
          },
          "messages": {
            "welcome": "欢迎来到黑暗房间"
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/lang/zh.json') {
            return utf8.encode(mockTranslationJson).buffer.asByteData();
          }
          return null;
        });

        await localization.init();
      });

      test('应该正确翻译简单键值', () {
        Logger.info('🧪 测试简单键值翻译');

        // 测试直接键值翻译
        expect(localization.translate('ui.buttons.light_fire'), equals('点火'));
        expect(localization.translate('ui.buttons.stoke_fire'), equals('添柴'));
        expect(localization.translate('buildings.trap'), equals('陷阱'));

        Logger.info('✅ 简单键值翻译测试通过');
      });

      test('应该正确处理嵌套键值', () {
        Logger.info('🧪 测试嵌套键值翻译');

        // 测试深层嵌套
        expect(localization.translate('ui.modules.room'), equals('房间'));
        expect(localization.translate('ui.modules.outside'), equals('外部'));

        Logger.info('✅ 嵌套键值翻译测试通过');
      });

      test('应该正确处理参数替换', () {
        Logger.info('🧪 测试参数替换');

        // 测试单个参数
        expect(localization.translate('crafting.wood_needed', [5]),
            equals('需要 5 个木材'));

        // 测试多个参数
        expect(localization.translate('crafting.multiple_items', [3, '陷阱']),
            equals('制作 3 个 陷阱'));

        Logger.info('✅ 参数替换测试通过');
      });

      test('应该正确处理不带前缀的键值', () {
        Logger.info('🧪 测试不带前缀的键值');

        // 测试自动分类查找
        expect(localization.translate('light_fire'), equals('点火'));
        expect(localization.translate('trap'), equals('陷阱'));
        expect(localization.translate('welcome'), equals('欢迎来到黑暗房间'));

        Logger.info('✅ 不带前缀的键值测试通过');
      });

      test('应该正确处理缺失的翻译', () {
        Logger.info('🧪 测试缺失翻译处理');

        // 测试不存在的键值
        expect(localization.translate('nonexistent.key'),
            equals('nonexistent.key'));
        expect(localization.translate('another.missing.key'),
            equals('another.missing.key'));

        Logger.info('✅ 缺失翻译处理测试通过');
      });
    });

    group('🔧 工具方法测试', () {
      setUp(() async {
        const String mockTranslationJson = '''
        {
          "logs": {
            "start": "开始",
            "complete": "完成",
            "error": "错误"
          }
        }
        ''';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          final String key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/lang/zh.json') {
            return utf8.encode(mockTranslationJson).buffer.asByteData();
          }
          return null;
        });

        await localization.init();
      });

      test('应该正确处理日志翻译', () {
        Logger.info('🧪 测试日志翻译');

        // 测试日志专用翻译方法
        expect(localization.translateLog('start'), equals('开始'));
        expect(localization.translateLog('complete'), equals('完成'));
        expect(localization.translateLog('error'), equals('错误'));

        Logger.info('✅ 日志翻译测试通过');
      });

      test('应该正确获取语言名称', () {
        Logger.info('🧪 测试语言名称获取');

        // 测试可用语言列表
        expect(localization.availableLanguages['zh'], equals('中文'));
        expect(localization.availableLanguages['en'], equals('English'));
        expect(localization.availableLanguages.containsKey('invalid'), isFalse);

        Logger.info('✅ 语言名称获取测试通过');
      });

      test('应该正确检查翻译存在性', () {
        Logger.info('🧪 测试翻译存在性检查');

        // 通过translate方法检查翻译是否存在
        // 如果翻译存在，返回值应该不等于键名
        final existingKey = 'ui.buttons.light_fire';
        final nonExistingKey = 'nonexistent.key';

        // 对于存在的键，翻译结果应该不等于键名
        final existingTranslation = localization.translate(existingKey);
        expect(existingTranslation, isNot(equals(existingKey)));

        // 对于不存在的键，翻译结果应该等于键名
        final nonExistingTranslation = localization.translate(nonExistingKey);
        expect(nonExistingTranslation, equals(nonExistingKey));

        Logger.info('✅ 翻译存在性检查测试通过');
      });
    });

    group('💾 持久化测试', () {
      test('应该正确保存和加载语言设置', () async {
        Logger.info('🧪 测试语言设置持久化');

        // 设置mock语言文件
        const String mockJson = '{"ui": {"test": "测试"}}';
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
          return utf8.encode(mockJson).buffer.asByteData();
        });

        await localization.init();

        // 保存语言设置
        await localization.saveLanguage('en');

        // 验证保存
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('language'), equals('en'));

        // 获取保存的语言设置
        final savedLanguage = await localization.getSavedLanguage();
        expect(savedLanguage, equals('en'));

        Logger.info('✅ 语言设置持久化测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 Localization 测试套件完成');
      // 清理mock消息处理器
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });
  });
}
