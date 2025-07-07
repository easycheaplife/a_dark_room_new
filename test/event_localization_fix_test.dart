import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/events/room_events_extended.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 事件本地化修复测试
/// 测试事件定义中的本地化键是否能正确翻译为对应的文本
///
/// 这个测试主要验证：
/// 1. 事件定义不再使用立即执行函数
/// 2. 事件定义返回本地化键而不是翻译后的文本
/// 3. 事件结构的正确性
void main() {
  group('事件本地化修复测试', () {
    late StateManager stateManager;

    setUpAll(() {
      // 初始化状态管理器
      stateManager = StateManager();

      // 设置测试状态
      stateManager.set('game.fire.value', 4); // 火焰旺盛
      stateManager.set('stores.wood', 100); // 有木材
      stateManager.set('stores.fur', 200); // 有毛皮

      Logger.info('🧪 测试环境初始化完成');
    });

    group('noisesInside 事件测试', () {
      test('事件标题应该是本地化键', () {
        final event = RoomEventsExtended.noisesInside;
        final title = event['title'] as String;

        // 验证返回的是本地化键而不是翻译后的文本
        expect(title, equals('events.room_events.noises_inside.title'));

        // 验证是字符串类型，不是函数
        expect(title, isA<String>());

        Logger.info('✅ noisesInside 标题测试通过: $title');
      });

      test('事件文本应该是本地化键数组', () {
        final event = RoomEventsExtended.noisesInside;
        final scenes = event['scenes'] as Map<String, dynamic>;
        final startScene = scenes['start'] as Map<String, dynamic>;
        final textList = startScene['text'] as List<String>;

        // 验证返回的是本地化键
        expect(textList[0], equals('events.room_events.noises_inside.text1'));
        expect(textList[1], equals('events.room_events.noises_inside.text2'));

        // 验证是字符串数组
        expect(textList, isA<List<String>>());
        expect(textList.length, equals(2));

        Logger.info('✅ noisesInside 文本测试通过');
        Logger.info('   text1: ${textList[0]}');
        Logger.info('   text2: ${textList[1]}');
      });

      test('事件按钮应该是本地化键', () {
        final event = RoomEventsExtended.noisesInside;
        final scenes = event['scenes'] as Map<String, dynamic>;
        final startScene = scenes['start'] as Map<String, dynamic>;
        final buttons = startScene['buttons'] as Map<String, dynamic>;

        // 测试调查按钮
        final investigateButton =
            buttons['investigate'] as Map<String, dynamic>;
        final investigateText = investigateButton['text'] as String;
        expect(investigateText, equals('ui.buttons.investigate'));
        expect(investigateText, isA<String>());

        // 测试忽视按钮
        final ignoreButton = buttons['ignore'] as Map<String, dynamic>;
        final ignoreText = ignoreButton['text'] as String;
        expect(ignoreText, equals('ui.buttons.ignore'));
        expect(ignoreText, isA<String>());

        Logger.info('✅ noisesInside 按钮测试通过');
        Logger.info('   investigate: $investigateText');
        Logger.info('   ignore: $ignoreText');
      });

      test('事件可用性函数应该正常工作', () {
        final event = RoomEventsExtended.noisesInside;
        final isAvailable = event['isAvailable'] as Function;

        // 测试有木材时事件可用
        stateManager.set('stores.wood', 100);
        expect(isAvailable(), isTrue);

        // 测试没有木材时事件不可用
        stateManager.set('stores.wood', 0);
        expect(isAvailable(), isFalse);

        // 恢复状态 - 重新设置木材
        stateManager.set('stores.wood', 50);
        expect(isAvailable(), isTrue);

        Logger.info('✅ noisesInside 可用性测试通过');
      });
    });

    group('beggar 事件测试', () {
      test('乞丐事件标题应该是本地化键', () {
        final event = RoomEventsExtended.beggar;
        final title = event['title'] as String;

        expect(title, equals('events.room_events.beggar.title'));
        expect(title, isA<String>());

        Logger.info('✅ beggar 标题测试通过: $title');
      });

      test('乞丐事件按钮应该是本地化键', () {
        final event = RoomEventsExtended.beggar;
        final scenes = event['scenes'] as Map<String, dynamic>;
        final startScene = scenes['start'] as Map<String, dynamic>;
        final buttons = startScene['buttons'] as Map<String, dynamic>;

        // 测试给50毛皮按钮
        final give50Button = buttons['50furs'] as Map<String, dynamic>;
        final give50Text = give50Button['text'] as String;
        expect(give50Text, equals('ui.buttons.give_50'));
        expect(give50Text, isA<String>());

        // 测试拒绝按钮
        final denyButton = buttons['deny'] as Map<String, dynamic>;
        final denyText = denyButton['text'] as String;
        expect(denyText, equals('ui.buttons.deny'));
        expect(denyText, isA<String>());

        Logger.info('✅ beggar 按钮测试通过');
        Logger.info('   give_50: $give50Text');
        Logger.info('   deny: $denyText');
      });
    });

    group('修复验证测试', () {
      test('验证不再使用立即执行函数', () {
        final event = RoomEventsExtended.noisesInside;
        final title = event['title'];

        // 验证title是字符串而不是函数调用的结果
        expect(title, isA<String>());
        expect(title, isNot(contains('function')));
        expect(title, isNot(contains('()')));

        // 验证是本地化键名
        expect(title, startsWith('events.'));

        Logger.info('✅ 立即执行函数移除验证通过');
        Logger.info('   title类型: ${title.runtimeType}');
        Logger.info('   title内容: $title');
      });

      test('验证事件结构完整性', () {
        final event = RoomEventsExtended.noisesInside;

        // 验证基本结构
        expect(event.containsKey('title'), isTrue);
        expect(event.containsKey('isAvailable'), isTrue);
        expect(event.containsKey('scenes'), isTrue);

        // 验证场景结构
        final scenes = event['scenes'] as Map<String, dynamic>;
        expect(scenes.containsKey('start'), isTrue);

        final startScene = scenes['start'] as Map<String, dynamic>;
        expect(startScene.containsKey('text'), isTrue);
        expect(startScene.containsKey('notification'), isTrue);
        expect(startScene.containsKey('buttons'), isTrue);

        Logger.info('✅ 事件结构完整性验证通过');
      });

      test('验证本地化键格式正确', () {
        final event = RoomEventsExtended.noisesInside;
        final title = event['title'] as String;

        // 验证本地化键格式
        expect(title.contains('.'), isTrue);
        expect(title.split('.').length, greaterThan(1));

        // 验证不包含中文字符（说明不是翻译后的文本）
        final containsChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(title);
        expect(containsChinese, isFalse);

        Logger.info('✅ 本地化键格式验证通过');
        Logger.info('   键名: $title');
        Logger.info('   包含中文: $containsChinese');
      });
    });

    tearDownAll(() {
      Logger.info('🧪 测试完成，清理测试环境');
    });
  });
}
