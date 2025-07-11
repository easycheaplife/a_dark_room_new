import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/setpieces.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';

void main() {
  group('铁矿战斗修复测试', () {
    late World world;
    late Events events;
    late Setpieces setpieces;
    late StateManager stateManager;

    setUp(() {
      // 初始化测试环境
      stateManager = StateManager();
      world = World();
      events = Events();
      setpieces = Setpieces();

      // 初始化本地化
      Localization();

      // 设置基本游戏状态
      stateManager.set('features.location.world', true);
      stateManager.set('game.fire.wood', 100);
      stateManager.set('game.stores.torch', 5);

      Logger.info('🧪 测试环境初始化完成');
    });

    test('验证铁矿setpiece配置正确', () {
      Logger.info('🧪 开始测试：验证铁矿setpiece配置正确');

      // 验证铁矿setpiece存在
      expect(setpieces.isSetpieceAvailable('ironmine'), isTrue);
      Logger.info('🧪 ✅ 铁矿setpiece存在');

      // 获取铁矿setpiece配置
      final ironmineSetpiece = setpieces.getSetpieceInfo('ironmine');
      expect(ironmineSetpiece, isNotNull);

      // 验证场景配置
      final scenes = ironmineSetpiece!['scenes'] as Map<String, dynamic>;
      expect(scenes.containsKey('start'), isTrue);
      expect(scenes.containsKey('enter'), isTrue);
      expect(scenes.containsKey('cleared'), isTrue);
      Logger.info('🧪 ✅ 铁矿场景配置完整');

      // 验证战斗场景配置
      final enterScene = scenes['enter'] as Map<String, dynamic>;
      expect(enterScene['combat'], isTrue);
      expect(enterScene['enemy'], equals('beastly matriarch'));

      // 验证leave按钮配置
      final buttons = enterScene['buttons'] as Map<String, dynamic>;
      expect(buttons.containsKey('leave'), isTrue);

      final leaveButton = buttons['leave'] as Map<String, dynamic>;
      expect(leaveButton['nextScene'], equals({'1': 'cleared'}));
      Logger.info('🧪 ✅ 战斗场景leave按钮配置正确');

      // 验证cleared场景配置
      final clearedScene = scenes['cleared'] as Map<String, dynamic>;
      expect(clearedScene['onLoad'], equals('clearIronMine'));
      Logger.info('🧪 ✅ cleared场景onLoad配置正确');
    });

    test('验证铁矿访问流程', () {
      Logger.info('🧪 开始测试：验证铁矿访问流程');

      // 初始化世界
      world.init();

      // 确保world.state不为null
      world.state ??= {};

      // 创建测试地图
      final testMap = List.generate(10, (x) => List.generate(10, (y) => '.'));
      testMap[5][5] = 'I';
      world.state!['map'] = testMap;
      world.curPos = [5, 5];

      // 第一步：访问铁矿，应该触发setpiece事件
      world.doSpace();
      expect(events.activeEvent(), isNotNull);
      expect(events.activeScene, equals('start'));
      expect(testMap[5][5], equals('I')); // 未立即标记为已访问
      Logger.info('🧪 ✅ 第一步：铁矿访问触发setpiece事件');

      // 第二步：进入铁矿（需要火把）
      final event = events.activeEvent();
      final startScene = event!['scenes']['start'];
      final enterButton = startScene['buttons']['enter'];

      events.handleButtonClick('enter', enterButton);
      expect(events.activeScene, equals('enter'));
      Logger.info('🧪 ✅ 第二步：成功进入铁矿战斗场景');

      // 第三步：模拟战斗胜利
      events.won = true;
      events.fought = true;

      // 第四步：点击离开按钮，应该跳转到cleared场景
      final enterScene = event['scenes']['enter'];
      final leaveButton = enterScene['buttons']['leave'];

      events.handleButtonClick('leave', leaveButton);
      expect(events.activeScene, equals('cleared'));
      Logger.info('🧪 ✅ 第四步：战斗胜利后跳转到cleared场景');

      // 第五步：验证clearIronMine被调用，铁矿被标记为已访问
      final updatedMap = world.state?['map'] as List<List<String>>?;
      expect(updatedMap![5][5], equals('I!'));
      expect(stateManager.get('game.world.ironmine', true), isTrue);
      expect(stateManager.get('game.buildings["iron mine"]', true), equals(1));
      Logger.info('🧪 ✅ 第五步：铁矿正确标记为已访问，建筑解锁');

      Logger.info('🧪 🎉 铁矿访问流程测试完成！');
    });

    test('验证修复后的行为与原游戏一致', () {
      Logger.info('🧪 开始测试：验证修复后的行为与原游戏一致');

      // 初始化世界
      world.init();

      // 确保world.state不为null
      world.state ??= {};

      // 创建测试地图
      final testMap = List.generate(10, (x) => List.generate(10, (y) => '.'));
      testMap[5][5] = 'I';
      world.state!['map'] = testMap;
      world.curPos = [5, 5];

      // 原游戏行为验证：
      Logger.info('🧪 原游戏正确行为：');
      Logger.info('🧪 1. 访问铁矿 -> 触发setpiece事件，不立即标记为已访问');
      Logger.info('🧪 2. 进入战斗 -> 与beastly matriarch战斗');
      Logger.info('🧪 3. 战斗胜利 -> 点击离开按钮跳转到cleared场景');
      Logger.info('🧪 4. cleared场景 -> 调用clearIronMine，标记为已访问');
      Logger.info('🧪 5. 已访问的铁矿 -> 不再触发事件');

      // 验证修复后的行为
      world.doSpace();
      expect(testMap[5][5], equals('I')); // 不立即标记

      final event = events.activeEvent();
      final startScene = event!['scenes']['start'];
      final enterButton = startScene['buttons']['enter'];
      events.handleButtonClick('enter', enterButton);

      events.won = true;
      events.fought = true;

      final enterScene = event['scenes']['enter'];
      final leaveButton = enterScene['buttons']['leave'];
      events.handleButtonClick('leave', leaveButton);

      final updatedMap = world.state?['map'] as List<List<String>>?;
      expect(updatedMap![5][5], equals('I!')); // 战斗胜利后标记

      // 验证已访问的铁矿不再触发事件
      world.doSpace();
      expect(events.activeEvent(), isNull);

      Logger.info('🧪 ✅ 修复后的行为与原游戏完全一致！');
    });

    test('验证战斗界面leave按钮处理逻辑', () {
      Logger.info('🧪 开始测试：验证战斗界面leave按钮处理逻辑');

      // 这个测试验证CombatScreen中_handleLeaveButton方法的逻辑
      // 虽然我们不能直接测试UI组件，但可以验证Events.handleButtonClick的行为

      // 初始化世界
      world.init();

      // 确保world.state不为null
      world.state ??= {};

      // 创建测试地图
      final testMap = List.generate(10, (x) => List.generate(10, (y) => '.'));
      testMap[5][5] = 'I';
      world.state!['map'] = testMap;
      world.curPos = [5, 5];

      // 触发铁矿事件并进入战斗
      world.doSpace();
      final event = events.activeEvent();
      final startScene = event!['scenes']['start'];
      final enterButton = startScene['buttons']['enter'];
      events.handleButtonClick('enter', enterButton);

      // 模拟战斗胜利
      events.won = true;
      events.fought = true;

      // 获取当前场景的leave按钮配置
      final enterScene = event['scenes']['enter'];
      final leaveButton =
          enterScene['buttons']['leave'] as Map<String, dynamic>;

      // 验证leave按钮有nextScene配置
      expect(leaveButton['nextScene'], isNotNull);
      expect(leaveButton['nextScene'], equals({'1': 'cleared'}));

      // 模拟CombatScreen中_handleLeaveButton的逻辑
      Logger.info('🧪 模拟战斗界面leave按钮点击');
      events.handleButtonClick('leave', leaveButton);

      // 验证正确跳转到cleared场景
      expect(events.activeScene, equals('cleared'));

      // 验证clearIronMine被调用
      final updatedMap = world.state?['map'] as List<List<String>>?;
      expect(updatedMap![5][5], equals('I!'));

      Logger.info('🧪 ✅ 战斗界面leave按钮处理逻辑正确');
    });
  });
}
