import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/widgets/notification_display.dart';
import 'package:a_dark_room_new/core/notifications.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// NotificationDisplay 通知显示组件测试
///
/// 测试覆盖范围：
/// 1. 基本通知显示
/// 2. 通知列表渲染
/// 3. 响应式布局
/// 4. 通知更新和刷新
/// 5. 滚动和渐变效果
void main() {
  group('📢 NotificationDisplay 通知显示测试', () {
    late NotificationManager notificationManager;
    late Localization localization;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 NotificationDisplay 测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notificationManager = NotificationManager();
      localization = Localization();

      // 初始化系统
      await localization.init();
      notificationManager.init();
    });

    tearDown(() {
      notificationManager.dispose();
      localization.dispose();
    });

    /// 创建测试用的Widget包装器
    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notificationManager),
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
      testWidgets('应该正确渲染空通知显示', (WidgetTester tester) async {
        Logger.info('🧪 测试空通知显示渲染');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证组件存在
        expect(find.byType(NotificationDisplay), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(ListView), findsOneWidget);

        Logger.info('✅ 空通知显示渲染测试通过');
      });

      testWidgets('应该正确显示单个通知', (WidgetTester tester) async {
        Logger.info('🧪 测试单个通知显示');

        // 添加一个通知
        notificationManager.notify('room', '收集了木材');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证通知文本显示
        expect(find.text('收集了木材'), findsOneWidget);

        Logger.info('✅ 单个通知显示测试通过');
      });

      testWidgets('应该正确显示多个通知', (WidgetTester tester) async {
        Logger.info('🧪 测试多个通知显示');

        // 添加多个通知
        notificationManager.notify('room', '收集了木材');
        notificationManager.notify('room', '点燃了火焰');
        notificationManager.notify('outside', '建造了陷阱');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证所有通知都显示
        expect(find.text('收集了木材'), findsOneWidget);
        expect(find.text('点燃了火焰'), findsOneWidget);
        expect(find.text('建造了陷阱'), findsOneWidget);

        Logger.info('✅ 多个通知显示测试通过');
      });
    });

    group('📱 响应式布局测试', () {
      testWidgets('应该在移动端使用正确的布局', (WidgetTester tester) async {
        Logger.info('🧪 测试移动端布局');

        // 设置小屏幕尺寸模拟移动设备
        await tester.binding.setSurfaceSize(const Size(400, 800));

        // 添加通知
        notificationManager.notify('room', '这是一个很长的通知消息，用来测试移动端的文本显示效果');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证组件存在
        expect(find.byType(NotificationDisplay), findsOneWidget);
        expect(find.byType(Text), findsWidgets);

        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);

        Logger.info('✅ 移动端布局测试通过');
      });

      testWidgets('应该在桌面端使用正确的布局', (WidgetTester tester) async {
        Logger.info('🧪 测试桌面端布局');

        // 设置大屏幕尺寸模拟桌面设备
        await tester.binding.setSurfaceSize(const Size(1200, 800));

        // 添加通知
        notificationManager.notify('room', '桌面端通知消息');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证组件存在
        expect(find.byType(NotificationDisplay), findsOneWidget);
        expect(find.text('桌面端通知消息'), findsOneWidget);

        // 验证渐变遮罩存在（桌面端特有）
        expect(find.byType(Positioned), findsWidgets);

        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);

        Logger.info('✅ 桌面端布局测试通过');
      });
    });

    group('🔄 通知更新测试', () {
      testWidgets('应该正确响应通知管理器的更新', (WidgetTester tester) async {
        Logger.info('🧪 测试通知更新响应');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 初始状态应该没有通知
        expect(find.byType(Text), findsNothing);

        // 添加通知
        notificationManager.notify('room', '新通知');
        await tester.pump();

        // 验证通知显示
        expect(find.text('新通知'), findsOneWidget);

        // 添加更多通知
        notificationManager.notify('room', '第二个通知');
        await tester.pump();

        // 验证两个通知都显示
        expect(find.text('新通知'), findsOneWidget);
        expect(find.text('第二个通知'), findsOneWidget);

        Logger.info('✅ 通知更新响应测试通过');
      });

      testWidgets('应该正确处理通知清理', (WidgetTester tester) async {
        Logger.info('🧪 测试通知清理');

        // 添加通知
        notificationManager.notify('room', '待清理通知');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证通知显示
        expect(find.text('待清理通知'), findsOneWidget);

        // 清理通知
        notificationManager.clearQueue('room');
        await tester.pump();

        // 验证通知仍在历史中显示（NotificationDisplay显示所有历史通知）
        expect(find.text('待清理通知'), findsOneWidget);

        Logger.info('✅ 通知清理测试通过');
      });
    });

    group('📜 滚动功能测试', () {
      testWidgets('应该支持通知列表滚动', (WidgetTester tester) async {
        Logger.info('🧪 测试通知列表滚动');

        // 添加大量通知
        for (int i = 0; i < 20; i++) {
          notificationManager.notify('room', '通知消息 $i');
        }

        await tester.pumpWidget(
          createTestWidget(
            SizedBox(
              height: 200, // 限制高度以触发滚动
              child: const NotificationDisplay(),
            ),
          ),
        );

        // 验证ListView存在
        expect(find.byType(ListView), findsOneWidget);

        // 验证至少有一些通知显示
        expect(find.textContaining('通知消息'), findsWidgets);

        // 尝试滚动
        await tester.drag(find.byType(ListView), const Offset(0, -100));
        await tester.pump();

        // 验证滚动不会崩溃
        expect(find.byType(ListView), findsOneWidget);

        Logger.info('✅ 通知列表滚动测试通过');
      });
    });

    group('🎨 样式和外观测试', () {
      testWidgets('应该使用正确的文本样式', (WidgetTester tester) async {
        Logger.info('🧪 测试文本样式');

        notificationManager.notify('room', '样式测试通知');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 查找文本组件
        final textFinder = find.text('样式测试通知');
        expect(textFinder, findsOneWidget);

        // 验证文本样式
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.color, equals(Colors.black));
        expect(textWidget.style?.fontFamily, equals('Times New Roman'));

        Logger.info('✅ 文本样式测试通过');
      });

      testWidgets('应该正确设置容器尺寸', (WidgetTester tester) async {
        Logger.info('🧪 测试容器尺寸');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 查找主容器
        final containerFinder = find.byType(Container).first;
        expect(containerFinder, findsOneWidget);

        // 验证容器存在
        final container = tester.widget<Container>(containerFinder);
        expect(container.padding, equals(const EdgeInsets.all(0)));

        Logger.info('✅ 容器尺寸测试通过');
      });

      testWidgets('应该正确显示渐变遮罩', (WidgetTester tester) async {
        Logger.info('🧪 测试渐变遮罩');

        // 设置桌面端尺寸
        await tester.binding.setSurfaceSize(const Size(1200, 800));

        notificationManager.notify('room', '渐变测试通知');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证Positioned组件存在（渐变遮罩）
        expect(find.byType(Positioned), findsWidgets);

        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);

        Logger.info('✅ 渐变遮罩测试通过');
      });
    });

    group('🔧 边界情况测试', () {
      testWidgets('应该正确处理空通知列表', (WidgetTester tester) async {
        Logger.info('🧪 测试空通知列表');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证组件不会崩溃
        expect(find.byType(NotificationDisplay), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        Logger.info('✅ 空通知列表测试通过');
      });

      testWidgets('应该正确处理长文本通知', (WidgetTester tester) async {
        Logger.info('🧪 测试长文本通知');

        final longMessage = '这是一个非常长的通知消息，' * 10;
        notificationManager.notify('room', longMessage);

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证长文本不会导致崩溃
        expect(find.byType(Text), findsOneWidget);

        Logger.info('✅ 长文本通知测试通过');
      });

      testWidgets('应该正确处理特殊字符', (WidgetTester tester) async {
        Logger.info('🧪 测试特殊字符处理');

        notificationManager.notify('room', '特殊字符: @#\$%^&*()_+{}|:"<>?');

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证特殊字符显示正常
        expect(find.textContaining('特殊字符'), findsOneWidget);

        Logger.info('✅ 特殊字符处理测试通过');
      });
    });

    group('📊 性能测试', () {
      testWidgets('应该正确处理大量通知', (WidgetTester tester) async {
        Logger.info('🧪 测试大量通知处理');

        // 添加大量通知
        for (int i = 0; i < 100; i++) {
          notificationManager.notify('room', '性能测试通知 $i');
        }

        await tester.pumpWidget(
          createTestWidget(const NotificationDisplay()),
        );

        // 验证组件不会崩溃
        expect(find.byType(NotificationDisplay), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // 验证至少显示了一些通知
        expect(find.textContaining('性能测试通知'), findsWidgets);

        Logger.info('✅ 大量通知处理测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 NotificationDisplay 测试套件完成');
    });
  });
}
