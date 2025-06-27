import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/setpieces.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 测试废墟城市离开按钮修复
///
/// 验证需要火把的场景都有离开按钮，防止玩家被困
void main() {
  group('废墟城市离开按钮修复测试', () {
    late Setpieces setpieces;
    late StateManager stateManager;
    late Path path;

    setUpAll(() async {
      // 初始化测试环境
      await Localization().init();
      setpieces = Setpieces();
      stateManager = StateManager();
      path = Path();
      Logger.info('🧪 废墟城市离开按钮测试环境初始化完成');
    });

    setUp(() {
      // 每个测试前重置状态
      // stateManager.clearAll(); // StateManager没有clearAll方法
      path.outfit.clear();
    });

    test('a3场景（医院）应该有离开按钮', () {
      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      expect(citySetpiece, isNotNull, reason: '废墟城市setpiece应该存在');

      final a3Scene = citySetpiece!['scenes']['a3'];
      expect(a3Scene, isNotNull, reason: 'a3场景应该存在');

      final buttons = a3Scene['buttons'] as Map<String, dynamic>;
      expect(buttons, isNotNull, reason: 'a3场景应该有按钮');

      // 检查进入按钮
      final enterButton = buttons['enter'];
      expect(enterButton, isNotNull, reason: 'a3场景应该有进入按钮');
      expect(enterButton['cost'], isNotNull, reason: '进入按钮应该需要火把');
      expect(enterButton['cost']['torch'], 1, reason: '进入按钮应该需要1个火把');

      // 检查离开按钮
      final leaveButton = buttons['leave'];
      expect(leaveButton, isNotNull, reason: 'a3场景应该有离开按钮');
      expect(leaveButton['nextScene'], 'finish', reason: '离开按钮应该结束场景');

      Logger.info('✅ a3场景离开按钮测试通过');
    });

    test('a4场景（地铁）应该有离开按钮', () {
      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      expect(citySetpiece, isNotNull, reason: '废墟城市setpiece应该存在');

      final a4Scene = citySetpiece!['scenes']['a4'];
      expect(a4Scene, isNotNull, reason: 'a4场景应该存在');

      final buttons = a4Scene['buttons'] as Map<String, dynamic>;
      expect(buttons, isNotNull, reason: 'a4场景应该有按钮');

      // 检查进入按钮
      final enterButton = buttons['enter'];
      expect(enterButton, isNotNull, reason: 'a4场景应该有进入按钮');
      expect(enterButton['cost'], isNotNull, reason: '进入按钮应该需要火把');
      expect(enterButton['cost']['torch'], 1, reason: '进入按钮应该需要1个火把');

      // 检查离开按钮
      final leaveButton = buttons['leave'];
      expect(leaveButton, isNotNull, reason: 'a4场景应该有离开按钮');
      expect(leaveButton['nextScene'], 'finish', reason: '离开按钮应该结束场景');

      Logger.info('✅ a4场景离开按钮测试通过');
    });

    test('c3场景应该有调查按钮和离开按钮', () {
      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      expect(citySetpiece, isNotNull, reason: '废墟城市setpiece应该存在');

      final c3Scene = citySetpiece!['scenes']['c3'];
      expect(c3Scene, isNotNull, reason: 'c3场景应该存在');

      final buttons = c3Scene['buttons'] as Map<String, dynamic>;
      expect(buttons, isNotNull, reason: 'c3场景应该有按钮');

      // 检查调查按钮（原游戏中是investigate）
      final enterButton = buttons['enter'];
      expect(enterButton, isNotNull, reason: 'c3场景应该有调查按钮');
      expect(enterButton['cost'], isNotNull, reason: '调查按钮应该需要火把');
      expect(enterButton['cost']['torch'], 1, reason: '调查按钮应该需要1个火把');

      // 检查离开按钮
      final leaveButton = buttons['leave'];
      expect(leaveButton, isNotNull, reason: 'c3场景应该有离开按钮');
      expect(leaveButton['nextScene'], 'finish', reason: '离开按钮应该结束场景');

      Logger.info('✅ c3场景按钮测试通过');
    });

    test('c3场景文本应该符合原游戏描述', () {
      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      final c3Scene = citySetpiece!['scenes']['c3'];

      final textFunction = c3Scene['text'] as List<String> Function();
      final texts = textFunction();

      expect(texts.length, 3, reason: 'c3场景应该有3段文本');

      // 检查文本内容（通过本地化键验证）
      expect(texts[0], contains('地铁站台'), reason: '第一段文本应该提到地铁站台');
      expect(texts[1], contains('光线'), reason: '第二段文本应该提到光线');
      expect(texts[2], contains('声音'), reason: '第三段文本应该提到声音');

      Logger.info('✅ c3场景文本测试通过');
    });

    test('没有火把时应该能看到离开按钮', () {
      // 设置没有火把的状态
      path.outfit['torch'] = 0;
      stateManager.set('outfit["torch"]', 0);
      stateManager.set('stores.torch', 0);

      // 模拟检查按钮可用性的逻辑
      bool canAffordTorch(Map<String, dynamic>? cost) {
        if (cost == null || cost.isEmpty) return true;

        for (final entry in cost.entries) {
          final key = entry.key;
          final required = (entry.value as num).toInt();

          if (key == 'torch') {
            final outfitAmount = path.outfit[key] ?? 0;
            if (outfitAmount < required) {
              return false;
            }
          }
        }
        return true;
      }

      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      final a4Scene = citySetpiece!['scenes']['a4'];
      final buttons = a4Scene['buttons'] as Map<String, dynamic>;

      // 检查进入按钮应该被禁用
      final enterButton = buttons['enter'];
      final canEnter =
          canAffordTorch(enterButton['cost'] as Map<String, dynamic>?);
      expect(canEnter, false, reason: '没有火把时进入按钮应该被禁用');

      // 检查离开按钮应该可用
      final leaveButton = buttons['leave'];
      final canLeave =
          canAffordTorch(leaveButton['cost'] as Map<String, dynamic>?);
      expect(canLeave, true, reason: '离开按钮应该总是可用');

      Logger.info('✅ 没有火把时的按钮状态测试通过');
    });

    test('有火把时应该能进入和离开', () {
      // 设置有火把的状态
      path.outfit['torch'] = 2;
      stateManager.set('outfit["torch"]', 2);

      // 模拟检查按钮可用性的逻辑
      bool canAffordTorch(Map<String, dynamic>? cost) {
        if (cost == null || cost.isEmpty) return true;

        for (final entry in cost.entries) {
          final key = entry.key;
          final required = (entry.value as num).toInt();

          if (key == 'torch') {
            final outfitAmount = path.outfit[key] ?? 0;
            if (outfitAmount < required) {
              return false;
            }
          }
        }
        return true;
      }

      // 获取废墟城市setpiece
      final citySetpiece = Setpieces.setpieces['city'];
      final a4Scene = citySetpiece!['scenes']['a4'];
      final buttons = a4Scene['buttons'] as Map<String, dynamic>;

      // 检查进入按钮应该可用
      final enterButton = buttons['enter'];
      final canEnter =
          canAffordTorch(enterButton['cost'] as Map<String, dynamic>?);
      expect(canEnter, true, reason: '有火把时进入按钮应该可用');

      // 检查离开按钮应该可用
      final leaveButton = buttons['leave'];
      final canLeave =
          canAffordTorch(leaveButton['cost'] as Map<String, dynamic>?);
      expect(canLeave, true, reason: '离开按钮应该总是可用');

      Logger.info('✅ 有火把时的按钮状态测试通过');
    });

    tearDownAll(() {
      Logger.info('🧪 废墟城市离开按钮测试完成，清理测试环境');
    });
  });
}
