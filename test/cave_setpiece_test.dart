import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/setpieces.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

void main() {
  group('洞穴Setpiece事件测试', () {
    late Setpieces setpieces;
    late StateManager sm;
    late Localization localization;

    setUp(() {
      sm = StateManager();
      sm.init();
      localization = Localization();
      localization.init();
      setpieces = Setpieces();
    });

    test('验证洞穴Setpiece是否可用', () {
      Logger.info('🧪 开始验证洞穴Setpiece可用性...');
      
      // 检查洞穴Setpiece是否存在
      final isAvailable = setpieces.isSetpieceAvailable('cave');
      Logger.info('🏛️ 洞穴Setpiece可用性: $isAvailable');
      
      expect(isAvailable, isTrue, reason: '洞穴Setpiece应该可用');
      
      // 获取洞穴Setpiece信息
      final caveInfo = setpieces.getSetpieceInfo('cave');
      Logger.info('🏛️ 洞穴Setpiece信息: $caveInfo');
      
      expect(caveInfo, isNotNull, reason: '洞穴Setpiece信息不应为空');
      expect(caveInfo!['title'], isNotNull, reason: '洞穴Setpiece应该有标题');
      expect(caveInfo['scenes'], isNotNull, reason: '洞穴Setpiece应该有场景');
      
      Logger.info('✅ 洞穴Setpiece可用性验证通过');
    });

    test('验证洞穴Setpiece场景完整性', () {
      Logger.info('🧪 开始验证洞穴Setpiece场景完整性...');
      
      final caveInfo = setpieces.getSetpieceInfo('cave');
      expect(caveInfo, isNotNull);
      
      final scenes = caveInfo!['scenes'] as Map<String, dynamic>;
      Logger.info('🏛️ 洞穴场景数量: ${scenes.length}');
      
      // 验证关键场景存在
      final requiredScenes = ['start', 'a1', 'a2', 'a3', 'b1', 'b2', 'b3', 'b4', 
                             'c1', 'c2', 'end1', 'end2', 'end3', 'leave_end'];
      
      for (final sceneName in requiredScenes) {
        expect(scenes.containsKey(sceneName), isTrue, 
               reason: '洞穴应该包含场景: $sceneName');
        Logger.info('✅ 场景存在: $sceneName');
      }
      
      // 验证开始场景的结构
      final startScene = scenes['start'] as Map<String, dynamic>;
      expect(startScene['text'], isNotNull, reason: '开始场景应该有文本');
      expect(startScene['buttons'], isNotNull, reason: '开始场景应该有按钮');
      
      final buttons = startScene['buttons'] as Map<String, dynamic>;
      expect(buttons.containsKey('enter'), isTrue, reason: '开始场景应该有进入按钮');
      expect(buttons.containsKey('leave'), isTrue, reason: '开始场景应该有离开按钮');
      
      Logger.info('✅ 洞穴Setpiece场景完整性验证通过');
    });

    test('验证洞穴Setpiece战斗场景', () {
      Logger.info('🧪 开始验证洞穴Setpiece战斗场景...');
      
      final caveInfo = setpieces.getSetpieceInfo('cave');
      final scenes = caveInfo!['scenes'] as Map<String, dynamic>;
      
      // 验证战斗场景a1 (beast)
      final a1Scene = scenes['a1'] as Map<String, dynamic>;
      expect(a1Scene['combat'], isTrue, reason: 'a1场景应该是战斗场景');
      expect(a1Scene['enemy'], equals('beast'), reason: 'a1场景敌人应该是beast');
      expect(a1Scene['health'], equals(5), reason: 'beast血量应该是5');
      expect(a1Scene['damage'], equals(1), reason: 'beast伤害应该是1');
      expect(a1Scene['loot'], isNotNull, reason: 'a1场景应该有战利品');
      
      Logger.info('✅ a1战斗场景验证通过: ${a1Scene['enemy']}');
      
      // 验证战斗场景b4 (cave lizard)
      final b4Scene = scenes['b4'] as Map<String, dynamic>;
      expect(b4Scene['combat'], isTrue, reason: 'b4场景应该是战斗场景');
      expect(b4Scene['enemy'], equals('cave lizard'), reason: 'b4场景敌人应该是cave lizard');
      expect(b4Scene['health'], equals(6), reason: 'cave lizard血量应该是6');
      expect(b4Scene['damage'], equals(3), reason: 'cave lizard伤害应该是3');
      expect(b4Scene['loot'], isNotNull, reason: 'b4场景应该有战利品');
      
      Logger.info('✅ b4战斗场景验证通过: ${b4Scene['enemy']}');
      Logger.info('✅ 洞穴Setpiece战斗场景验证通过');
    });

    test('验证洞穴Setpiece结束场景和奖励', () {
      Logger.info('🧪 开始验证洞穴Setpiece结束场景和奖励...');
      
      final caveInfo = setpieces.getSetpieceInfo('cave');
      final scenes = caveInfo!['scenes'] as Map<String, dynamic>;
      
      // 验证三个结束场景
      final endScenes = ['end1', 'end2', 'end3'];
      
      for (final endScene in endScenes) {
        final scene = scenes[endScene] as Map<String, dynamic>;
        expect(scene['text'], isNotNull, reason: '$endScene应该有文本');
        expect(scene['onLoad'], equals('clearDungeon'), 
               reason: '$endScene应该调用clearDungeon');
        expect(scene['loot'], isNotNull, reason: '$endScene应该有战利品');
        
        final loot = scene['loot'] as Map<String, dynamic>;
        expect(loot.isNotEmpty, isTrue, reason: '$endScene应该有具体的战利品');
        
        Logger.info('✅ 结束场景验证通过: $endScene, 战利品种类: ${loot.length}');
      }
      
      // 验证end3场景有钢剑奖励
      final end3Scene = scenes['end3'] as Map<String, dynamic>;
      final end3Loot = end3Scene['loot'] as Map<String, dynamic>;
      expect(end3Loot.containsKey('steel sword'), isTrue, 
             reason: 'end3场景应该有钢剑奖励');
      
      Logger.info('✅ 洞穴Setpiece结束场景和奖励验证通过');
    });

    test('验证洞穴Setpiece本地化文本', () {
      Logger.info('🧪 开始验证洞穴Setpiece本地化文本...');
      
      // 验证标题本地化
      final title = localization.translate('setpieces.cave.title');
      expect(title.isNotEmpty, isTrue, reason: '洞穴标题不应为空');
      Logger.info('✅ 洞穴标题: $title');
      
      // 验证开始场景文本
      final startText1 = localization.translate('setpieces.cave.start.text1');
      final startText2 = localization.translate('setpieces.cave.start.text2');
      expect(startText1.isNotEmpty, isTrue, reason: '开始文本1不应为空');
      expect(startText2.isNotEmpty, isTrue, reason: '开始文本2不应为空');
      
      Logger.info('✅ 开始场景文本验证通过');
      
      // 验证战斗通知文本
      final beastNotification = localization.translate('setpieces.cave_scenes.beast_notification');
      final lizardNotification = localization.translate('setpieces.cave_scenes.cave_lizard_notification');
      expect(beastNotification.isNotEmpty, isTrue, reason: '野兽通知文本不应为空');
      expect(lizardNotification.isNotEmpty, isTrue, reason: '洞穴蜥蜴通知文本不应为空');
      
      Logger.info('✅ 战斗通知文本验证通过');
      Logger.info('✅ 洞穴Setpiece本地化文本验证通过');
    });
  });
}
