import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/modules/room.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 测试火把背包检查修复
///
/// 验证以下功能：
/// 1. 火把检查只检查背包，不检查库存
/// 2. 火把消耗只从背包扣除
/// 3. 按钮置灰和工具提示正确显示
void main() {
  group('火把背包检查修复测试', () {
    late StateManager stateManager;
    late Path path;
    late Events events;
    late World world;
    late Room room;

    setUp(() async {
      // 初始化测试环境
      stateManager = StateManager();
      path = Path();
      events = Events();
      world = World();
      room = Room();

      // 重置状态
      try {
        await stateManager.clearGameData();
      } catch (e) {
        // 忽略binding错误，在测试环境中是正常的
      }

      // 清空背包状态
      path.outfit.clear();

      // 设置基础游戏状态
      stateManager.set('game.fire.value', 3);
      stateManager.set('game.temperature.value', 3);
      stateManager.set('game.builder.level', 1);
      stateManager.set('stores.wood', 10);
      stateManager.set('stores.cloth', 10);
      stateManager.set('stores.torch', 5);

      // 确保背包中没有火把
      stateManager.set('outfit["torch"]', 0);
      path.outfit['torch'] = 0;

      Logger.info('🧪 测试环境初始化完成');
    });

    test('火把检查应该只检查背包，不检查库存', () {
      // 设置背包中有火把，库存中没有
      path.outfit['torch'] = 1;
      stateManager.set('outfit["torch"]', 1);
      stateManager.set('stores.torch', 0);

      // 模拟洞穴进入按钮配置
      final buttonConfig = {
        'text': '进入',
        'cost': {'torch': 1},
        'nextScene': {'1': 'cave_interior'}
      };

      // 检查是否可以承担成本
      final canAfford = events
          .canAffordBackpackCost(buttonConfig['cost'] as Map<String, dynamic>);
      expect(canAfford, true, reason: '背包中有火把时应该可以进入');

      Logger.info('✅ 火把只检查背包测试通过');
    });

    test('库存有火把但背包没有时应该无法进入', () {
      // 设置背包中没有火把，库存中有火把
      path.outfit['torch'] = 0;
      stateManager.set('outfit["torch"]', 0);
      stateManager.set('stores.torch', 5);

      // 模拟洞穴进入按钮配置
      final buttonConfig = {
        'text': '进入',
        'cost': {'torch': 1},
        'nextScene': {'1': 'cave_interior'}
      };

      // 检查是否可以承担成本
      final canAfford = events
          .canAffordBackpackCost(buttonConfig['cost'] as Map<String, dynamic>);
      expect(canAfford, false, reason: '背包中没有火把时应该无法进入，即使库存有火把');

      Logger.info('✅ 库存有火把但背包没有时无法进入测试通过');
    });

    test('火把消耗应该只从背包扣除', () {
      // 设置背包中有2个火把，库存中有3个火把
      path.outfit['torch'] = 2;
      stateManager.set('outfit["torch"]', 2);
      stateManager.set('stores.torch', 3);

      // 模拟消耗1个火把
      final costs = {'torch': 1};
      events.consumeBackpackCost(costs);

      // 验证只有背包中的火把被消耗
      final torchInOutfit = path.outfit['torch'] ?? 0;
      final torchInStore = stateManager.get('stores.torch', true) ?? 0;

      expect(torchInOutfit, 1, reason: '背包中的火把应该减少1个');
      expect(torchInStore, 3, reason: '库存中的火把应该保持不变');

      Logger.info('✅ 火把只从背包消耗测试通过');
    });

    test('背包火把不足时应该无法进入', () {
      // 设置背包中只有1个火把，但需要2个
      path.outfit['torch'] = 1;
      stateManager.set('outfit["torch"]', 1);
      stateManager.set('stores.torch', 10); // 库存很多，但不应该被检查

      // 模拟需要2个火把的按钮配置
      final buttonConfig = {
        'text': '进入',
        'cost': {'torch': 2},
        'nextScene': {'1': 'cave_interior'}
      };

      // 检查是否可以承担成本
      final canAfford = events
          .canAffordBackpackCost(buttonConfig['cost'] as Map<String, dynamic>);
      expect(canAfford, false, reason: '背包火把不足时应该无法进入');

      Logger.info('✅ 背包火把不足时无法进入测试通过');
    });

    test('火把应该可以添加到背包', () {
      // 确保背包初始为空
      path.outfit['torch'] = 0;
      stateManager.set('outfit["torch"]', 0);

      // 更新装备配置
      path.updateOutfitting();

      // 尝试增加火把到背包
      path.increaseSupply('torch', 2);

      // 验证背包中有火把
      final torchInOutfit = path.outfit['torch'] ?? 0;
      expect(torchInOutfit, 2, reason: '背包中应该有2个火把');

      Logger.info('✅ 火把可以添加到背包测试通过');
    });

    test('火把应该不会留在家里', () {
      // 测试leaveItAtHome函数
      final shouldLeave = world.leaveItAtHome('torch');
      expect(shouldLeave, false, reason: '火把应该可以带走，不留在家里');

      Logger.info('✅ 火把不留在家里测试通过');
    });

    test('Room.craftables中的火把应该可以携带', () {
      // 检查Room中的火把配置
      final torchConfig = room.craftables['torch'];
      expect(torchConfig, isNotNull, reason: 'Room中应该有火把配置');
      expect(torchConfig!['type'], 'tool', reason: '火把应该是工具类型');

      // 确保背包初始为空
      path.outfit['torch'] = 0;
      stateManager.set('outfit["torch"]', 0);

      // 检查火把是否可以添加到背包
      path.updateOutfitting();
      path.increaseSupply('torch', 1);
      final torchInOutfit = path.outfit['torch'] ?? 0;
      expect(torchInOutfit, 1, reason: '火把应该可以添加到背包');

      Logger.info('✅ Room.craftables火把可携带测试通过');
    });
  });
}
