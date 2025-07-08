import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/space.dart';
import 'package:a_dark_room_new/modules/ship.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// Space模块飞船移动灵敏度测试
///
/// 验证方向键移动灵敏度修复效果，
/// 确保移动速度与原游戏一致
void main() {
  group('飞船移动灵敏度测试', () {
    late Space space;
    late Ship ship;
    late StateManager stateManager;

    setUpAll(() async {
      // 初始化本地化系统
      await Localization().init();
    });

    setUp(() {
      space = Space();
      ship = Ship();
      stateManager = StateManager();
      stateManager.init();

      // 设置基本的飞船状态
      ship.init();
      ship.hull = 5;
      stateManager.set('game.spaceShip.hull', 5);
      stateManager.set('game.spaceShip.thrusters', 3);
    });

    test('验证基础移动速度计算', () {
      Logger.info('🚀 验证基础移动速度计算...');

      space.onArrival();

      // 验证速度计算与原游戏一致
      final speed = space.getSpeed();
      final expectedSpeed = 3.0 + 3; // shipSpeed + thrusters
      expect(speed, equals(expectedSpeed), reason: '速度应该等于基础速度+推进器等级');

      Logger.info('✅ 基础速度: $speed (预期: $expectedSpeed)');
    });

    test('验证单次移动距离', () {
      Logger.info('🚀 验证单次移动距离...');

      space.onArrival();

      final initialX = space.shipX;
      final initialY = space.shipY;

      // 设置向右移动
      space.right = true;
      space.lastMove =
          DateTime.now().subtract(Duration(milliseconds: 33)); // 模拟33ms间隔

      // 执行一次移动
      space.moveShip();

      final deltaX = space.shipX - initialX;
      final deltaY = space.shipY - initialY;

      // 验证移动距离合理性
      expect(deltaX, greaterThan(0), reason: '向右移动应该增加X坐标');
      expect(deltaX, lessThan(10), reason: '单次移动距离不应该过大');
      expect(deltaY, equals(0), reason: '只向右移动，Y坐标不应该改变');

      Logger.info('✅ 单次移动距离: deltaX=$deltaX, deltaY=$deltaY');
    });

    test('验证时间补偿限制', () {
      Logger.info('🚀 验证时间补偿限制...');

      space.onArrival();

      final initialX = space.shipX;

      // 测试正常时间间隔（33ms）
      space.right = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
      space.moveShip();
      final normalDelta = space.shipX - initialX;

      // 重置位置
      space.shipX = initialX;
      space.right = false;

      // 测试异常长时间间隔（200ms）
      space.right = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 200));
      space.moveShip();
      final longDelta = space.shipX - initialX;

      // 验证时间补偿被限制
      final ratio = longDelta / normalDelta;
      expect(ratio, lessThan(3.0), reason: '长时间间隔的移动距离应该被限制');
      expect(ratio, greaterThan(1.0), reason: '长时间间隔应该有一定补偿');

      Logger.info(
          '✅ 时间补偿限制: 正常移动=$normalDelta, 长间隔移动=$longDelta, 比例=${ratio.toStringAsFixed(2)}');
    });

    test('验证移动平滑处理', () {
      Logger.info('🚀 验证移动平滑处理...');

      space.onArrival();

      // 连续移动多次，验证平滑效果
      final movements = <double>[];

      for (int i = 0; i < 5; i++) {
        final oldX = space.shipX;
        space.right = true;
        space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
        space.moveShip();
        movements.add(space.shipX - oldX);
      }

      // 验证移动距离的一致性
      final avgMovement = movements.reduce((a, b) => a + b) / movements.length;
      for (final movement in movements) {
        final deviation = (movement - avgMovement).abs() / avgMovement;
        expect(deviation, lessThan(0.5), reason: '移动距离应该相对稳定');
      }

      Logger.info('✅ 移动平滑处理: 平均移动距离=${avgMovement.toStringAsFixed(2)}');
      Logger.info(
          '   移动序列: ${movements.map((m) => m.toStringAsFixed(2)).join(', ')}');
    });

    test('验证对角线移动速度调整', () {
      Logger.info('🚀 验证对角线移动速度调整...');

      space.onArrival();

      final initialX = space.shipX;
      final initialY = space.shipY;

      // 测试单方向移动
      space.right = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
      space.moveShip();
      final singleDeltaX = space.shipX - initialX;

      // 重置位置
      space.shipX = initialX;
      space.shipY = initialY;
      space.right = false;

      // 测试对角线移动
      space.right = true;
      space.up = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
      space.moveShip();
      final diagonalDeltaX = space.shipX - initialX;
      final diagonalDeltaY = initialY - space.shipY; // 向上移动，Y减少

      // 验证对角线移动速度调整（应该约为单方向的1/√2）
      final expectedDiagonal = singleDeltaX / 1.414; // 1/√2 ≈ 0.707
      final tolerance = expectedDiagonal * 0.2; // 20%容差

      expect(diagonalDeltaX, closeTo(expectedDiagonal, tolerance),
          reason: '对角线移动X分量应该约为单方向的1/√2');
      expect(diagonalDeltaY, closeTo(expectedDiagonal, tolerance),
          reason: '对角线移动Y分量应该约为单方向的1/√2');

      Logger.info(
          '✅ 对角线移动: 单方向=$singleDeltaX, 对角线X=$diagonalDeltaX, 对角线Y=$diagonalDeltaY');
      Logger.info('   预期对角线=${expectedDiagonal.toStringAsFixed(2)}');
    });

    test('验证边界限制', () {
      Logger.info('🚀 验证边界限制...');

      space.onArrival();

      // 测试左边界
      space.shipX = 15.0; // 接近左边界
      space.left = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));

      // 连续向左移动
      for (int i = 0; i < 10; i++) {
        space.moveShip();
      }

      expect(space.shipX, greaterThanOrEqualTo(10.0), reason: 'X坐标不应该小于左边界10');

      // 测试右边界
      space.shipX = 685.0; // 接近右边界
      space.left = false;
      space.right = true;

      // 连续向右移动
      for (int i = 0; i < 10; i++) {
        space.moveShip();
      }

      expect(space.shipX, lessThanOrEqualTo(690.0), reason: 'X坐标不应该大于右边界690');

      Logger.info('✅ 边界限制: 最终X坐标=${space.shipX}');
    });

    test('验证移动响应性', () {
      Logger.info('🚀 验证移动响应性...');

      space.onArrival();

      final initialX = space.shipX;

      // 测试按键按下立即响应
      space.right = true;
      space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
      space.moveShip();

      expect(space.shipX, greaterThan(initialX), reason: '按键按下应该立即响应');

      // 测试按键释放立即停止
      final moveX = space.shipX;
      space.right = false;
      space.moveShip();

      expect(space.shipX, equals(moveX), reason: '按键释放应该立即停止移动');

      Logger.info('✅ 移动响应性验证通过');
    });

    test('验证移动灵敏度修复效果', () {
      Logger.info('🚀 验证移动灵敏度修复效果...');

      space.onArrival();

      // 测试连续移动10次的总距离
      space.right = true;
      double totalDistance = 0;

      for (int i = 0; i < 10; i++) {
        final oldX = space.shipX;
        space.lastMove = DateTime.now().subtract(Duration(milliseconds: 33));
        space.moveShip();
        totalDistance += (space.shipX - oldX);
      }

      // 验证移动距离合理（不会过于灵敏）
      final avgDistance = totalDistance / 10;
      expect(avgDistance, lessThan(8.0), reason: '平均移动距离不应该过大（过于灵敏）');
      expect(avgDistance, greaterThan(2.0), reason: '平均移动距离不应该过小（反应迟钝）');

      // 验证总移动距离合理
      expect(totalDistance, lessThan(80.0), reason: '10次移动总距离不应该过大');
      expect(totalDistance, greaterThan(20.0), reason: '10次移动总距离不应该过小');

      Logger.info(
          '✅ 移动灵敏度修复效果: 平均移动距离=${avgDistance.toStringAsFixed(2)}, 总距离=${totalDistance.toStringAsFixed(2)}');
      Logger.info('   修复前问题: 移动过于灵敏，现在已通过平滑处理和时间补偿限制得到改善');
    });
  });
}
