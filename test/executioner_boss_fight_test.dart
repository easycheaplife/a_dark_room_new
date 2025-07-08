import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/events/executioner_events.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/core/localization.dart';

void main() {
  group('执行者最终Boss战斗测试', () {
    late Events events;
    late World world;

    setUp(() {
      // 初始化测试环境
      world = World();
      events = Events();

      // 初始化本地化
      Localization();

      // 设置前置条件：完成前三个部门
      world.state = {
        'executioner': true,
        'engineering': true,
        'medical': true,
        'martial': true,
      };
    });

    test('executioner-command事件应该包含最终Boss战斗', () {
      final commandEvent = ExecutionerEvents.executionerCommand;

      expect(commandEvent['title'], isNotNull);
      expect(commandEvent['scenes'], isNotNull);

      final scenes = commandEvent['scenes'] as Map<String, dynamic>;
      expect(scenes.containsKey('boss_fight'), isTrue);

      final bossFight = scenes['boss_fight'] as Map<String, dynamic>;
      expect(bossFight['combat'], isTrue);
      expect(bossFight['enemy'], equals('immortal wanderer'));
      expect(bossFight['health'], equals(500));
      expect(bossFight['damage'], equals(12));
    });

    test('最终Boss应该有特殊技能系统', () {
      final commandEvent = ExecutionerEvents.executionerCommand;
      final scenes = commandEvent['scenes'] as Map<String, dynamic>;
      final bossFight = scenes['boss_fight'] as Map<String, dynamic>;

      expect(bossFight.containsKey('specials'), isTrue);

      final specials = bossFight['specials'] as List;
      expect(specials.length, equals(1));

      final special = specials[0] as Map<String, dynamic>;
      expect(special['delay'], equals(7));
      expect(special['action'], isNotNull);
    });

    test('最终Boss应该掉落舰队信标', () {
      final commandEvent = ExecutionerEvents.executionerCommand;
      final scenes = commandEvent['scenes'] as Map<String, dynamic>;
      final bossFight = scenes['boss_fight'] as Map<String, dynamic>;

      expect(bossFight.containsKey('loot'), isTrue);

      final loot = bossFight['loot'] as Map<String, dynamic>;
      expect(loot.containsKey('fleet beacon'), isTrue);

      final fleetBeacon = loot['fleet beacon'] as Map<String, dynamic>;
      expect(fleetBeacon['min'], equals(1));
      expect(fleetBeacon['max'], equals(1));
      expect(fleetBeacon['chance'], equals(1.0));
    });

    test('胜利后应该设置command状态并清理地牢', () {
      final commandEvent = ExecutionerEvents.executionerCommand;
      final scenes = commandEvent['scenes'] as Map<String, dynamic>;
      final victory = scenes['victory'] as Map<String, dynamic>;

      expect(victory.containsKey('onLoad'), isTrue);

      // 执行胜利回调
      final onLoad = victory['onLoad'] as Function;
      onLoad();

      // 验证状态设置
      expect(world.state!['command'], isTrue);
    });

    test('Events模块应该支持setStatus方法', () {
      // 测试设置敌人状态
      events.setStatus('enemy', 'shield');
      expect(events.getEnemyStatus(), equals('shield'));

      events.setStatus('enemy', 'enraged');
      expect(events.getEnemyStatus(), equals('enraged'));

      events.setStatus('enemy', 'meditation');
      expect(events.getEnemyStatus(), equals('meditation'));

      // 测试清除状态
      events.clearEnemyStatus();
      expect(events.getEnemyStatus(), isNull);
    });

    test('特殊技能应该避免重复使用相同状态', () {
      // 模拟特殊技能执行
      events.lastSpecialStatus = 'shield';

      final possibleStatuses = ['shield', 'enraged', 'meditation']
          .where((status) => status != events.lastSpecialStatus)
          .toList();

      expect(possibleStatuses.length, equals(2));
      expect(possibleStatuses.contains('shield'), isFalse);
      expect(possibleStatuses.contains('enraged'), isTrue);
      expect(possibleStatuses.contains('meditation'), isTrue);
    });

    test('command事件应该有正确的场景流程', () {
      final commandEvent = ExecutionerEvents.executionerCommand;
      final scenes = commandEvent['scenes'] as Map<String, dynamic>;

      // 验证场景流程
      expect(scenes.containsKey('start'), isTrue);
      expect(scenes.containsKey('approach'), isTrue);
      expect(scenes.containsKey('encounter'), isTrue);
      expect(scenes.containsKey('boss_fight'), isTrue);
      expect(scenes.containsKey('victory'), isTrue);

      // 验证场景连接
      final start = scenes['start'] as Map<String, dynamic>;
      final startButtons = start['buttons'] as Map<String, dynamic>;
      final continueButton = startButtons['continue'] as Map<String, dynamic>;
      expect(continueButton['nextScene'], equals('approach'));

      final approach = scenes['approach'] as Map<String, dynamic>;
      final approachButtons = approach['buttons'] as Map<String, dynamic>;
      final approachContinue =
          approachButtons['continue'] as Map<String, dynamic>;
      expect(approachContinue['nextScene'], equals('encounter'));
    });

    test('本地化文本应该包含所有必要的Boss战斗文本', () {
      final localization = Localization();

      // 验证关键文本存在
      expect(
          () => localization
              .translate('events.executioner.command.boss_notification'),
          returnsNormally);
      expect(
          () => localization.translate('events.executioner.command.boss_name'),
          returnsNormally);
      expect(
          () => localization
              .translate('events.executioner.command.victory_text1'),
          returnsNormally);
      expect(
          () => localization
              .translate('events.executioner.command.victory_text2'),
          returnsNormally);
      expect(
          () => localization
              .translate('events.executioner.command.victory_text3'),
          returnsNormally);
    });
  });
}
