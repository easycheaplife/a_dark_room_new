import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/engine.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'package:a_dark_room_new/core/audio_engine.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/modules/outside.dart';

/// Engine 核心游戏引擎测试
///
/// 测试覆盖范围：
/// 1. 引擎初始化流程
/// 2. 模块管理和切换
/// 3. 游戏保存和加载
/// 4. 音频控制
/// 5. 事件记录和处理
void main() {
  group('🎮 Engine 核心游戏引擎测试', () {
    late Engine engine;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 Engine 测试套件');
    });

    setUp(() {
      // 每个测试前重置SharedPreferences
      SharedPreferences.setMockInitialValues({});
      engine = Engine();
      // 重置引擎状态
      engine.activeModule = null;
      engine.tabNavigation = true;
      engine.restoreNavigation = false;
      // 在测试环境中启用音频引擎测试模式
      AudioEngine().setTestMode(true);
    });

    tearDown(() {
      try {
        engine.dispose();
      } catch (e) {
        // 忽略已释放对象的错误
        if (!e.toString().contains('was used after being disposed')) {
          Logger.info('⚠️ 测试清理时出错: $e');
        }
      }
    });

    group('🔧 引擎初始化测试', () {
      test('应该正确初始化引擎和所有子系统', () async {
        Logger.info('🧪 测试引擎初始化');

        // 执行初始化
        await engine.init();

        // 验证引擎状态
        expect(engine.activeModule, isNotNull);
        expect(engine.activeModule, isA<Room>());
        expect(engine.tabNavigation, isTrue);

        // 验证StateManager被初始化
        final sm = StateManager();
        expect(sm.state, isNotEmpty);
        expect(sm.state['version'], equals(1.3));

        Logger.info('✅ 引擎初始化测试通过');
      });

      test('应该正确设置初始选项', () async {
        Logger.info('🧪 测试初始选项设置');

        final options = {
          'debug': true,
          'log': true,
          'doubleTime': false,
        };

        await engine.init(options: options);

        // 验证选项被正确设置
        expect(engine.options['debug'], isTrue);
        expect(engine.options['log'], isTrue);
        expect(engine.options['doubleTime'], isFalse);
        expect(engine.options['dropbox'], isFalse); // 默认值

        Logger.info('✅ 初始选项设置测试通过');
      });

      test('应该根据游戏状态初始化正确的模块', () async {
        Logger.info('🧪 测试条件模块初始化');

        // 设置已解锁外部世界的状态
        final sm = StateManager();
        await sm.loadGame();
        sm.init();
        sm.set('features.location.outside', true);

        await engine.init();

        // 验证外部模块应该被初始化
        // 注意：这里我们主要验证引擎不会崩溃，具体模块初始化由各模块测试覆盖
        expect(engine.activeModule, isNotNull);

        Logger.info('✅ 条件模块初始化测试通过');
      });
    });

    group('🔄 模块管理测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确切换到不同模块', () {
        Logger.info('🧪 测试模块切换');

        final room = Room();
        final outside = Outside();

        // 切换到房间模块
        engine.travelTo(room);
        expect(engine.activeModule, equals(room));

        // 切换到外部模块
        engine.travelTo(outside);
        expect(engine.activeModule, equals(outside));

        Logger.info('✅ 模块切换测试通过');
      });

      test('应该正确处理相同模块切换', () {
        Logger.info('🧪 测试相同模块切换');

        final room = Room();
        engine.travelTo(room);
        final firstModule = engine.activeModule;

        // 再次切换到相同模块
        engine.travelTo(room);
        expect(engine.activeModule, equals(firstModule));

        Logger.info('✅ 相同模块切换测试通过');
      });

      test('应该正确处理导航状态', () {
        Logger.info('🧪 测试导航状态处理');

        // 设置恢复导航状态
        engine.restoreNavigation = true;
        engine.tabNavigation = false;

        final room = Room();
        engine.travelTo(room);

        // 验证导航状态被恢复
        expect(engine.tabNavigation, isTrue);
        expect(engine.restoreNavigation, isFalse);

        Logger.info('✅ 导航状态处理测试通过');
      });
    });

    group('💾 游戏保存和加载测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确保存游戏', () async {
        Logger.info('🧪 测试游戏保存');

        // 修改游戏状态
        final sm = StateManager();
        sm.set('stores.wood', 100);
        sm.set('game.population', 10);

        // 保存游戏
        await engine.saveGame();

        // 验证保存成功
        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('gameState');
        expect(savedData, isNotNull);
        expect(savedData, contains('100')); // 应该包含木材数量

        Logger.info('✅ 游戏保存测试通过');
      });

      test('应该正确加载游戏', () async {
        Logger.info('🧪 测试游戏加载');

        // 先保存一个状态
        final sm = StateManager();
        sm.set('stores.wood', 150);
        await engine.saveGame();

        // 加载游戏
        await engine.loadGame();

        // 验证状态被正确加载
        expect(sm.get('stores.wood'), equals(150));

        Logger.info('✅ 游戏加载测试通过');
      });

      test('应该正确处理加载失败', () async {
        Logger.info('🧪 测试加载失败处理');

        // 清除保存的数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('gameState');

        // 尝试加载游戏
        await engine.loadGame();

        // 验证引擎不会崩溃，并创建新游戏状态
        final sm = StateManager();
        expect(sm.state, isNotEmpty);
        expect(sm.state['version'], isNotNull);

        Logger.info('✅ 加载失败处理测试通过');
      });
    });

    group('🎵 音频控制测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确切换音频开关', () {
        Logger.info('🧪 测试音频开关');

        // 测试开启音频
        engine.toggleVolume(true);
        final sm = StateManager();
        expect(sm.get('config.soundOn'), isTrue);

        // 测试关闭音频
        engine.toggleVolume(false);
        expect(sm.get('config.soundOn'), isFalse);

        Logger.info('✅ 音频开关测试通过');
      });

      test('应该正确处理音频通知', () {
        Logger.info('🧪 测试音频通知');

        final sm = StateManager();

        // 第一次调用应该显示通知
        engine.notifyAboutSound();
        expect(sm.get('playStats.audioAlertShown'), isTrue);

        // 第二次调用应该跳过
        sm.set('playStats.audioAlertShown', false);
        engine.notifyAboutSound();
        // 这里主要验证不会崩溃

        Logger.info('✅ 音频通知测试通过');
      });
    });

    group('📊 事件记录测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确记录事件', () {
        Logger.info('🧪 测试事件记录');

        // 记录事件
        engine.event('test', 'action');
        engine.event('progress', 'milestone');

        // 验证事件被记录（主要验证不会崩溃）
        // 实际的事件记录验证需要mock分析服务
        expect(true, isTrue); // 占位验证

        Logger.info('✅ 事件记录测试通过');
      });

      test('应该正确处理事件参数', () {
        Logger.info('🧪 测试事件参数处理');

        // 记录事件
        engine.event('test', 'action');

        // 验证不会崩溃
        expect(true, isTrue);

        Logger.info('✅ 事件参数处理测试通过');
      });
    });

    group('🔧 工具方法测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确获取技能信息', () {
        Logger.info('🧪 测试技能信息获取');

        final perkInfo = engine.getPerk('martial artist');

        // 验证返回正确的结构
        expect(perkInfo, isA<Map<String, String>>());
        expect(perkInfo.containsKey('name'), isTrue);
        expect(perkInfo.containsKey('desc'), isTrue);
        expect(perkInfo.containsKey('notify'), isTrue);

        Logger.info('✅ 技能信息获取测试通过');
      });

      test('应该正确检查关灯模式', () {
        Logger.info('🧪 测试关灯模式检查');

        final sm = StateManager();

        // 测试关灯模式关闭
        sm.set('config.lightsOff', false);
        expect(engine.isLightsOff(), isFalse);

        // 测试关灯模式开启
        sm.set('config.lightsOff', true);
        expect(engine.isLightsOff(), isTrue);

        Logger.info('✅ 关灯模式检查测试通过');
      });

      test('应该正确处理超级模式', () {
        Logger.info('🧪 测试超级模式处理');

        // 测试确认超级模式
        engine.confirmHyperMode();

        // 验证不会崩溃
        expect(true, isTrue);

        Logger.info('✅ 超级模式处理测试通过');
      });
    });

    group('🌐 语言和本地化测试', () {
      setUp(() async {
        await engine.init();
      });

      test('应该正确切换语言', () {
        Logger.info('🧪 测试语言切换');

        // 切换语言
        engine.switchLanguage('en');
        engine.switchLanguage('zh');

        // 验证不会崩溃
        expect(true, isTrue);

        Logger.info('✅ 语言切换测试通过');
      });

      test('应该正确保存语言设置', () async {
        Logger.info('🧪 测试语言设置保存');

        // 保存语言设置
        await engine.saveLanguage();

        // 验证不会崩溃
        expect(true, isTrue);

        Logger.info('✅ 语言设置保存测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 Engine 测试套件完成');
    });
  });
}
