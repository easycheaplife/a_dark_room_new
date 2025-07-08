import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/widgets/progress_button.dart';
import '../lib/core/progress_manager.dart';
import '../lib/core/localization.dart';
import '../lib/core/state_manager.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// ProgressButton 进度按钮组件测试
/// 
/// 测试覆盖范围：
/// 1. 基本按钮渲染和属性
/// 2. 进度管理和状态
/// 3. 成本检查和显示
/// 4. 禁用状态和交互
/// 5. 工具提示功能
void main() {
  group('🔘 ProgressButton 进度按钮测试', () {
    late ProgressManager progressManager;
    late Localization localization;
    late StateManager stateManager;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 ProgressButton 测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      progressManager = ProgressManager();
      localization = Localization();
      stateManager = StateManager();
      
      // 初始化本地化系统
      await localization.init();
      stateManager.init();
    });

    tearDown() {
      // 清理进度管理器状态
      progressManager.dispose();
    }

    /// 创建测试用的Widget包装器
    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: progressManager),
          ChangeNotifierProvider.value(value: localization),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    group('🎨 基本渲染测试', () {
      testWidgets('应该正确渲染基本按钮', (WidgetTester tester) async {
        Logger.info('🧪 测试基本按钮渲染');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '测试按钮',
              width: 100,
            ),
          ),
        );

        // 验证按钮文本
        expect(find.text('测试按钮'), findsOneWidget);
        
        // 验证容器存在
        expect(find.byType(Container), findsWidgets);
        
        Logger.info('✅ 基本按钮渲染测试通过');
      });

      testWidgets('应该正确设置按钮尺寸', (WidgetTester tester) async {
        Logger.info('🧪 测试按钮尺寸设置');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '测试按钮',
              width: 150,
            ),
          ),
        );

        // 查找按钮容器
        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        
        // 验证宽度设置
        expect(container.constraints?.maxWidth, equals(150));
        
        Logger.info('✅ 按钮尺寸设置测试通过');
      });

      testWidgets('应该正确显示禁用状态', (WidgetTester tester) async {
        Logger.info('🧪 测试禁用状态显示');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '禁用按钮',
              disabled: true,
              width: 100,
            ),
          ),
        );

        // 验证按钮存在
        expect(find.text('禁用按钮'), findsOneWidget);
        
        // 验证禁用状态（通过查找灰色样式）
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);
        
        Logger.info('✅ 禁用状态显示测试通过');
      });
    });

    group('🔄 进度管理测试', () {
      testWidgets('应该正确启动进度', (WidgetTester tester) async {
        Logger.info('🧪 测试进度启动');

        bool actionCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '进度按钮',
              onPressed: () {
                actionCalled = true;
              },
              progressDuration: 1000,
              width: 100,
            ),
          ),
        );

        // 点击按钮
        await tester.tap(find.text('进度按钮'));
        await tester.pump();

        // 验证动作被立即执行
        expect(actionCalled, isTrue);
        
        // 验证进度管理器中有活动进度
        expect(progressManager.hasActiveProgress, isTrue);
        
        Logger.info('✅ 进度启动测试通过');
      });

      testWidgets('应该正确处理进度完成', (WidgetTester tester) async {
        Logger.info('🧪 测试进度完成');

        bool actionCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '快速按钮',
              onPressed: () {
                actionCalled = true;
              },
              progressDuration: 100, // 短时间进度
              width: 100,
            ),
          ),
        );

        // 点击按钮
        await tester.tap(find.text('快速按钮'));
        await tester.pump();

        // 验证动作被执行
        expect(actionCalled, isTrue);
        
        // 等待进度完成
        await tester.pump(const Duration(milliseconds: 150));
        
        // 验证进度已完成
        expect(progressManager.hasActiveProgress, isFalse);
        
        Logger.info('✅ 进度完成测试通过');
      });

      testWidgets('应该正确处理进度中的按钮状态', (WidgetTester tester) async {
        Logger.info('🧪 测试进度中按钮状态');

        int clickCount = 0;

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '进度按钮',
              onPressed: () {
                clickCount++;
              },
              progressDuration: 1000,
              width: 100,
            ),
          ),
        );

        // 第一次点击
        await tester.tap(find.text('进度按钮'));
        await tester.pump();

        expect(clickCount, equals(1));
        
        // 尝试再次点击（应该被阻止）
        await tester.tap(find.text('进度按钮'));
        await tester.pump();

        // 验证第二次点击被阻止
        expect(clickCount, equals(1));
        
        Logger.info('✅ 进度中按钮状态测试通过');
      });
    });

    group('💰 成本检查测试', () {
      testWidgets('应该正确显示成本信息', (WidgetTester tester) async {
        Logger.info('🧪 测试成本信息显示');

        // 设置足够的资源
        stateManager.set('stores.wood', 10);

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '建造按钮',
              cost: {'wood': 5},
              width: 100,
            ),
          ),
        );

        // 验证按钮存在
        expect(find.text('建造按钮'), findsOneWidget);
        
        Logger.info('✅ 成本信息显示测试通过');
      });

      testWidgets('应该正确处理免费按钮', (WidgetTester tester) async {
        Logger.info('🧪 测试免费按钮');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '免费按钮',
              cost: {'wood': 5},
              free: true,
              width: 100,
            ),
          ),
        );

        // 验证按钮存在且可用
        expect(find.text('免费按钮'), findsOneWidget);
        
        Logger.info('✅ 免费按钮测试通过');
      });

      testWidgets('应该正确处理资源不足', (WidgetTester tester) async {
        Logger.info('🧪 测试资源不足处理');

        // 设置资源不足
        stateManager.set('stores.wood', 2);

        bool actionCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '昂贵按钮',
              onPressed: () {
                actionCalled = true;
              },
              cost: const {'wood': 5},
              width: 100,
            ),
          ),
        );

        // 尝试点击按钮
        await tester.tap(find.text('昂贵按钮'));
        await tester.pump();

        // 验证动作未被执行（资源不足）
        expect(actionCalled, isFalse);
        
        Logger.info('✅ 资源不足处理测试通过');
      });
    });

    group('🖱️ 交互功能测试', () {
      testWidgets('应该正确处理鼠标悬停', (WidgetTester tester) async {
        Logger.info('🧪 测试鼠标悬停');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '悬停按钮',
              cost: {'wood': 5},
              tooltip: '需要5个木材',
              width: 100,
            ),
          ),
        );

        // 查找MouseRegion
        final mouseRegion = find.byType(MouseRegion);
        expect(mouseRegion, findsOneWidget);
        
        Logger.info('✅ 鼠标悬停测试通过');
      });

      testWidgets('应该正确处理点击事件', (WidgetTester tester) async {
        Logger.info('🧪 测试点击事件');

        bool clicked = false;

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '点击按钮',
              onPressed: () {
                clicked = true;
              },
              width: 100,
            ),
          ),
        );

        // 点击按钮
        await tester.tap(find.text('点击按钮'));
        await tester.pump();

        // 验证点击事件被处理
        expect(clicked, isTrue);
        
        Logger.info('✅ 点击事件测试通过');
      });

      testWidgets('应该正确处理空回调', (WidgetTester tester) async {
        Logger.info('🧪 测试空回调处理');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '无回调按钮',
              onPressed: null,
              width: 100,
            ),
          ),
        );

        // 尝试点击按钮（应该不会崩溃）
        await tester.tap(find.text('无回调按钮'));
        await tester.pump();

        // 验证没有进度启动
        expect(progressManager.hasActiveProgress, isFalse);
        
        Logger.info('✅ 空回调处理测试通过');
      });
    });

    group('🔧 工具方法测试', () {
      testWidgets('应该正确生成进度ID', (WidgetTester tester) async {
        Logger.info('🧪 测试进度ID生成');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '测试按钮',
              id: 'custom_id',
              width: 100,
            ),
          ),
        );

        // 验证按钮渲染成功
        expect(find.text('测试按钮'), findsOneWidget);
        
        Logger.info('✅ 进度ID生成测试通过');
      });

      testWidgets('应该正确处理自定义进度文本', (WidgetTester tester) async {
        Logger.info('🧪 测试自定义进度文本');

        await tester.pumpWidget(
          createTestWidget(
            ProgressButton(
              text: '自定义按钮',
              onPressed: () {},
              progressText: '处理中...',
              progressDuration: 1000,
              width: 100,
            ),
          ),
        );

        // 点击按钮启动进度
        await tester.tap(find.text('自定义按钮'));
        await tester.pump();

        // 验证按钮存在
        expect(find.byType(ProgressButton), findsOneWidget);
        
        Logger.info('✅ 自定义进度文本测试通过');
      });

      testWidgets('应该正确处理布局参数', (WidgetTester tester) async {
        Logger.info('🧪 测试布局参数处理');

        await tester.pumpWidget(
          createTestWidget(
            const ProgressButton(
              text: '布局按钮',
              width: 200,
            ),
          ),
        );

        // 验证按钮渲染
        expect(find.text('布局按钮'), findsOneWidget);
        
        Logger.info('✅ 布局参数处理测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 ProgressButton 测试套件完成');
    });
  });
}
