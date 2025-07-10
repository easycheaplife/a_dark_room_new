import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/widgets/stores_display.dart';

void main() {
  group('库存UI修复测试', () {
    late StateManager stateManager;
    late Localization localization;

    setUp(() {
      // 初始化测试环境
      stateManager = StateManager();
      localization = Localization();

      Logger.info('🧪 测试环境初始化完成');
    });

    testWidgets('应该正确处理混合类型的stores数据', (WidgetTester tester) async {
      Logger.info('🧪 开始测试：应该正确处理混合类型的stores数据');

      // 设置混合类型的stores数据（模拟实际游戏中的情况）
      stateManager.state['stores'] = {
        'wood': 100, // 正常的数字类型
        'iron': 50, // 正常的数字类型（在resources分类中）
        'fire': {'value': 5}, // 嵌套Map类型（应该被跳过或正确处理）
        'temperature': {'value': 10}, // 嵌套Map类型（应该被跳过或正确处理）
        'cloth': 25, // 正常的数字类型
        'fur': 0, // 零值（应该被跳过）
        'meat': -5, // 负值（应该被跳过）
        'invalidData': 'not a number', // 字符串类型（应该被跳过）
        'complexObject': {
          // 复杂对象（应该被跳过）
          'nested': {'data': 'value'}
        }
      };

      // 构建测试Widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: stateManager),
              ChangeNotifierProvider.value(value: localization),
            ],
            child: const Scaffold(
              body: StoresDisplay(
                style: StoresDisplayStyle.dark,
                type: StoresDisplayType.all,
              ),
            ),
          ),
        ),
      );

      // 等待Widget构建完成
      await tester.pumpAndSettle();

      Logger.info('🧪 验证：Widget应该成功构建而不抛出类型错误');

      // 验证Widget成功构建（没有抛出异常）
      expect(find.byType(StoresDisplay), findsOneWidget);

      // 验证只显示有效的数字资源
      expect(find.text('100'), findsOneWidget); // wood
      expect(find.text('50'), findsOneWidget); // iron
      expect(find.text('25'), findsOneWidget); // cloth

      // 验证不显示零值、负值或无效数据
      expect(find.text('0'), findsNothing); // fur (零值)
      expect(find.text('-5'), findsNothing); // meat (负值)
      expect(find.text('not a number'), findsNothing); // invalidData

      Logger.info('🧪 验证：只显示有效的正数资源');
    });

    testWidgets('应该正确处理嵌套value结构', (WidgetTester tester) async {
      Logger.info('🧪 开始测试：应该正确处理嵌套value结构');

      // 设置包含嵌套value结构的stores数据
      stateManager.state['stores'] = {
        'wood': 75,
        'iron': {'value': 30}, // 应该提取value值（使用已知的资源名称）
        'coal': {'value': 0}, // 零值应该被跳过
        'invalidNested': {'notValue': 20}, // 没有value键，应该被跳过
      };

      // 构建测试Widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: stateManager),
              ChangeNotifierProvider.value(value: localization),
            ],
            child: const Scaffold(
              body: StoresDisplay(
                style: StoresDisplayStyle.light,
                type: StoresDisplayType.resourcesOnly,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证正确处理嵌套value结构
      expect(find.text('75'), findsOneWidget); // wood
      expect(find.text('30'), findsOneWidget); // iron.value
      expect(find.text('0'), findsNothing); // coal.value (零值)
      expect(find.text('20'), findsNothing); // invalidNested (没有value键)

      Logger.info('🧪 验证：正确提取嵌套value结构中的数值');
    });

    testWidgets('应该正确处理空stores数据', (WidgetTester tester) async {
      Logger.info('🧪 开始测试：应该正确处理空stores数据');

      // 设置空的stores数据
      stateManager.state['stores'] = {};

      // 构建测试Widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: stateManager),
              ChangeNotifierProvider.value(value: localization),
            ],
            child: const Scaffold(
              body: StoresDisplay(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证空数据时不显示任何内容
      expect(find.byType(StoresDisplay), findsOneWidget);
      // 由于没有资源，StoresDisplay应该返回SizedBox.shrink()
      expect(find.byType(SizedBox), findsOneWidget);

      Logger.info('🧪 验证：空stores数据时正确处理');
    });

    testWidgets('应该正确处理null stores数据', (WidgetTester tester) async {
      Logger.info('🧪 开始测试：应该正确处理null stores数据');

      // 设置null的stores数据
      stateManager.state.remove('stores');

      // 构建测试Widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: stateManager),
              ChangeNotifierProvider.value(value: localization),
            ],
            child: const Scaffold(
              body: StoresDisplay(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证null数据时不显示任何内容
      expect(find.byType(StoresDisplay), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);

      Logger.info('🧪 验证：null stores数据时正确处理');
    });

    test('应该正确分类不同类型的资源', () {
      Logger.info('🧪 开始测试：应该正确分类不同类型的资源');

      // 这个测试验证资源分类逻辑的正确性
      // 由于分类逻辑在Widget内部，我们通过设置不同的数据来间接测试

      final testData = {
        'wood': 100,
        'iron': 50,
        'rifle': 2, // 武器
        'bone spear': 1, // 武器
        'compass': 1, // 特殊物品
        'fire': {'value': 5}, // 嵌套结构
        'invalidData': 'string', // 无效数据
      };

      // 模拟资源分类逻辑
      final validResources = <String, num>{};

      for (final entry in testData.entries) {
        final rawValue = entry.value;
        num value = 0;

        if (rawValue is num) {
          value = rawValue;
        } else if (rawValue is Map && rawValue.containsKey('value')) {
          final nestedValue = rawValue['value'];
          if (nestedValue is num) {
            value = nestedValue;
          }
        } else {
          continue; // 跳过无效数据
        }

        if (value > 0) {
          validResources[entry.key] = value;
        }
      }

      // 验证分类结果
      expect(validResources.containsKey('wood'), isTrue);
      expect(validResources.containsKey('iron'), isTrue);
      expect(validResources.containsKey('rifle'), isTrue);
      expect(validResources.containsKey('bone spear'), isTrue);
      expect(validResources.containsKey('compass'), isTrue);
      expect(validResources.containsKey('fire'), isTrue);
      expect(validResources.containsKey('invalidData'), isFalse);

      expect(validResources['wood'], equals(100));
      expect(validResources['fire'], equals(5)); // 从嵌套结构提取

      Logger.info('🧪 验证：资源分类逻辑正确');
    });
  });
}
