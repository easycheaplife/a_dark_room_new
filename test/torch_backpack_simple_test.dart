import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/path.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// 简化的火把背包检查测试
void main() {
  group('火把背包检查核心功能测试', () {
    late StateManager stateManager;
    late Path path;
    late Events events;
    late World world;

    setUp(() {
      // 初始化测试环境
      stateManager = StateManager();
      path = Path();
      events = Events();
      world = World();

      // 设置基础状态
      stateManager.set('stores.torch', 5); // 库存有5个火把
      path.outfit.clear(); // 清空背包

      Logger.info('🧪 测试环境初始化完成');
    });

    test('背包有火把时应该可以进入', () {
      // 设置背包中有1个火把
      path.outfit['torch'] = 1;
      stateManager.set('outfit["torch"]', 1);

      // 模拟洞穴进入按钮配置
      final costs = {'torch': 1};

      // 检查是否可以承担成本
      final canAfford = events.canAffordBackpackCost(costs);
      expect(canAfford, true, reason: '背包中有火把时应该可以进入');

      Logger.info('✅ 背包有火把时可以进入测试通过');
    });

    test('背包没有火把时应该无法进入（即使库存有）', () {
      // 设置背包中没有火把，但库存有火把
      path.outfit['torch'] = 0;
      stateManager.set('outfit["torch"]', 0);
      stateManager.set('stores.torch', 10); // 库存很多

      // 模拟洞穴进入按钮配置
      final costs = {'torch': 1};

      // 检查是否可以承担成本
      final canAfford = events.canAffordBackpackCost(costs);
      expect(canAfford, false, reason: '背包中没有火把时应该无法进入，即使库存有火把');

      Logger.info('✅ 背包没有火把时无法进入测试通过');
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

    test('火把应该可以带走（不留在家里）', () {
      // 测试leaveItAtHome函数
      final shouldLeave = world.leaveItAtHome('torch');
      expect(shouldLeave, false, reason: '火把应该可以带走，不留在家里');

      Logger.info('✅ 火把可以带走测试通过');
    });

    test('工具类物品识别正确', () {
      // 测试_isToolItem函数（通过canAffordBackpackCost间接测试）
      path.outfit['torch'] = 1;
      path.outfit['cured meat'] = 1;
      path.outfit['bullets'] = 1;

      final torchCost = {'torch': 1};
      final meatCost = {'cured meat': 1};
      final bulletsCost = {'bullets': 1};

      expect(events.canAffordBackpackCost(torchCost), true);
      expect(events.canAffordBackpackCost(meatCost), true);
      expect(events.canAffordBackpackCost(bulletsCost), true);

      Logger.info('✅ 工具类物品识别正确测试通过');
    });
  });
}
