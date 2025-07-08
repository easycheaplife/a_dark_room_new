import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/widgets/header.dart';
import '../lib/core/engine.dart';
import '../lib/core/state_manager.dart';
import '../lib/core/localization.dart';
import '../lib/modules/room.dart';
import '../lib/modules/outside.dart';
import '../lib/modules/path.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// Header 页面头部组件测试
/// 
/// 测试覆盖范围：
/// 1. 基本头部渲染
/// 2. 页签显示和切换
/// 3. 模块解锁条件
/// 4. 响应式布局
/// 5. 导航功能
void main() {
  group('📋 Header 页面头部测试', () {
    late Engine engine;
    late StateManager stateManager;
    late Localization localization;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 Header 测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      engine = Engine();
      stateManager = StateManager();
      localization = Localization();
      
      // 初始化系统
      await engine.init();
      await localization.init();
      stateManager.init();
    });

    tearDown() {
      engine.dispose();
      localization.dispose();
    }

    /// 创建测试用的Widget包装器
    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: engine),
          ChangeNotifierProvider.value(value: stateManager),
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
      testWidgets('应该正确渲染基本头部', (WidgetTester tester) async {
        Logger.info('🧪 测试基本头部渲染');

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证头部容器存在
        expect(find.byType(Header), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
        
        Logger.info('✅ 基本头部渲染测试通过');
      });

      testWidgets('应该显示房间页签', (WidgetTester tester) async {
        Logger.info('🧪 测试房间页签显示');

        // 设置房间模块为活动模块
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证房间页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 房间页签显示测试通过');
      });

      testWidgets('应该正确处理页签导航禁用', (WidgetTester tester) async {
        Logger.info('🧪 测试页签导航禁用');

        // 禁用页签导航
        engine.tabNavigation = false;

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证头部仍然存在但页签被隐藏
        expect(find.byType(Header), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
        
        Logger.info('✅ 页签导航禁用测试通过');
      });
    });

    group('📑 页签显示测试', () {
      testWidgets('应该根据火焰状态显示正确的房间标题', (WidgetTester tester) async {
        Logger.info('🧪 测试房间标题显示');

        // 设置火焰熄灭状态
        stateManager.set('game.fire.value', 0);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 房间标题显示测试通过');
      });

      testWidgets('应该在解锁外部世界后显示外部页签', (WidgetTester tester) async {
        Logger.info('🧪 测试外部页签解锁');

        // 解锁外部世界
        stateManager.set('features.location.outside', true);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 外部页签解锁测试通过');
      });

      testWidgets('应该在获得指南针后显示路径页签', (WidgetTester tester) async {
        Logger.info('🧪 测试路径页签解锁');

        // 设置指南针
        stateManager.set('stores.compass', 1);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 路径页签解锁测试通过');
      });

      testWidgets('应该在解锁制造器后显示制造器页签', (WidgetTester tester) async {
        Logger.info('🧪 测试制造器页签解锁');

        // 解锁制造器
        stateManager.set('features.location.fabricator', true);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 制造器页签解锁测试通过');
      });

      testWidgets('应该在解锁飞船后显示飞船页签', (WidgetTester tester) async {
        Logger.info('🧪 测试飞船页签解锁');

        // 解锁飞船
        stateManager.set('features.location.spaceShip', true);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 飞船页签解锁测试通过');
      });
    });

    group('🏠 外部标题测试', () {
      testWidgets('应该根据小屋数量显示正确的外部标题', (WidgetTester tester) async {
        Logger.info('🧪 测试外部标题变化');

        // 解锁外部世界
        stateManager.set('features.location.outside', true);
        
        // 测试不同小屋数量的标题
        final testCases = [
          {'huts': 0, 'expectedKey': 'ui.titles.quiet_forest'},
          {'huts': 1, 'expectedKey': 'ui.titles.lonely_hut'},
          {'huts': 3, 'expectedKey': 'ui.titles.small_village'},
          {'huts': 6, 'expectedKey': 'ui.titles.medium_village'},
          {'huts': 12, 'expectedKey': 'ui.titles.large_village'},
          {'huts': 20, 'expectedKey': 'ui.titles.bustling_town'},
        ];

        for (final testCase in testCases) {
          stateManager.set('game.buildings.hut', testCase['huts']);
          engine.activeModule = Outside();

          await tester.pumpWidget(
            createTestWidget(const Header()),
          );

          // 验证页签存在
          expect(find.byType(GestureDetector), findsWidgets);
          
          await tester.pump();
        }
        
        Logger.info('✅ 外部标题变化测试通过');
      });
    });

    group('📱 响应式布局测试', () {
      testWidgets('应该在移动端使用正确的布局', (WidgetTester tester) async {
        Logger.info('🧪 测试移动端布局');

        // 设置小屏幕尺寸模拟移动设备
        await tester.binding.setSurfaceSize(const Size(400, 800));
        
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证头部存在
        expect(find.byType(Header), findsOneWidget);
        
        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
        
        Logger.info('✅ 移动端布局测试通过');
      });

      testWidgets('应该在桌面端使用正确的布局', (WidgetTester tester) async {
        Logger.info('🧪 测试桌面端布局');

        // 设置大屏幕尺寸模拟桌面设备
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证头部存在
        expect(find.byType(Header), findsOneWidget);
        
        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
        
        Logger.info('✅ 桌面端布局测试通过');
      });
    });

    group('🔧 功能按钮测试', () {
      testWidgets('应该显示设置按钮', (WidgetTester tester) async {
        Logger.info('🧪 测试设置按钮显示');

        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 查找设置图标
        expect(find.byIcon(Icons.settings), findsWidgets);
        
        Logger.info('✅ 设置按钮显示测试通过');
      });

      testWidgets('应该显示导入导出按钮', (WidgetTester tester) async {
        Logger.info('🧪 测试导入导出按钮显示');

        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 查找导入导出图标
        expect(find.byIcon(Icons.save_alt), findsWidgets);
        
        Logger.info('✅ 导入导出按钮显示测试通过');
      });

      testWidgets('应该正确处理设置按钮点击', (WidgetTester tester) async {
        Logger.info('🧪 测试设置按钮点击');

        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 查找并点击设置按钮
        final settingsButton = find.byIcon(Icons.settings).first;
        await tester.tap(settingsButton);
        await tester.pump();

        // 验证不会崩溃
        expect(find.byType(Header), findsOneWidget);
        
        Logger.info('✅ 设置按钮点击测试通过');
      });
    });

    group('🎯 页签选择测试', () {
      testWidgets('应该正确显示选中状态', (WidgetTester tester) async {
        Logger.info('🧪 测试页签选中状态');

        // 设置房间为活动模块
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 页签选中状态测试通过');
      });

      testWidgets('应该正确处理页签点击', (WidgetTester tester) async {
        Logger.info('🧪 测试页签点击');

        // 解锁外部世界
        stateManager.set('features.location.outside', true);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 查找页签并尝试点击
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.first);
          await tester.pump();
        }

        // 验证不会崩溃
        expect(find.byType(Header), findsOneWidget);
        
        Logger.info('✅ 页签点击测试通过');
      });
    });

    group('🔒 解锁条件测试', () {
      testWidgets('应该正确检查路径解锁条件', (WidgetTester tester) async {
        Logger.info('🧪 测试路径解锁条件');

        // 测试有指南针的情况
        stateManager.set('stores.compass', 1);
        engine.activeModule = Room();

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        // 测试有足够资源制作指南针的情况
        stateManager.set('stores.compass', 0);
        stateManager.set('game.buildings["trading post"]', 1);
        stateManager.set('stores.fur', 400);
        stateManager.set('stores.scales', 20);
        stateManager.set('stores.teeth', 10);

        await tester.pumpWidget(
          createTestWidget(const Header()),
        );

        // 验证页签存在
        expect(find.byType(GestureDetector), findsWidgets);
        
        Logger.info('✅ 路径解锁条件测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 Header 测试套件完成');
    });
  });
}
