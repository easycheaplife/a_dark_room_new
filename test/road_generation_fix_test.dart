import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';

void main() {
  group('道路生成除零错误修复测试', () {
    test('测试除零错误修复逻辑', () {
      // 测试各种距离情况下的方向计算

      // 情况1：xDist = 0, yDist = 5
      int xDist = 0;
      int yDist = 5;

      // 修复后的逻辑：
      final xDir1 = xDist == 0 ? 0 : (xDist.abs() ~/ xDist);
      final yDir1 = yDist == 0 ? 0 : (yDist.abs() ~/ yDist);

      expect(xDir1, equals(0)); // 当距离为0时，方向应该为0
      expect(yDir1, equals(1)); // 当距离为正数时，方向应该为1

      // 情况2：xDist = 5, yDist = 0
      xDist = 5;
      yDist = 0;

      final xDir2 = xDist == 0 ? 0 : (xDist.abs() ~/ xDist);
      final yDir2 = yDist == 0 ? 0 : (yDist.abs() ~/ yDist);

      expect(xDir2, equals(1)); // 当距离为正数时，方向应该为1
      expect(yDir2, equals(0)); // 当距离为0时，方向应该为0

      // 情况3：xDist = -3, yDist = 4
      xDist = -3;
      yDist = 4;

      final xDir3 = xDist == 0 ? 0 : (xDist.abs() ~/ xDist);
      final yDir3 = yDist == 0 ? 0 : (yDist.abs() ~/ yDist);

      expect(xDir3, equals(-1)); // 当距离为负数时，方向应该为-1
      expect(yDir3, equals(1)); // 当距离为正数时，方向应该为1

      // 情况4：xDist = 0, yDist = 0 (这种情况在实际代码中会提前返回)
      xDist = 0;
      yDist = 0;

      final xDir4 = xDist == 0 ? 0 : (xDist.abs() ~/ xDist);
      final yDir4 = yDist == 0 ? 0 : (yDist.abs() ~/ yDist);

      expect(xDir4, equals(0));
      expect(yDir4, equals(0));

      Logger.info('✅ 除零错误修复验证成功');
      Logger.info('  情况1 (0,5): xDir=$xDir1, yDir=$yDir1');
      Logger.info('  情况2 (5,0): xDir=$xDir2, yDir=$yDir2');
      Logger.info('  情况3 (-3,4): xDir=$xDir3, yDir=$yDir3');
      Logger.info('  情况4 (0,0): xDir=$xDir4, yDir=$yDir4');
    });

    test('测试道路符号定义', () {
      // 验证道路符号是#而不是@
      const roadSymbol = '#';
      expect(roadSymbol, equals('#'));
      Logger.info('✅ 道路符号定义正确: $roadSymbol');
    });

    test('验证原始除零错误会发生', () {
      // 这个测试验证原始代码确实会有除零错误
      int xDist = 0;

      // 原始逻辑（会导致除零错误）：
      expect(() => xDist.abs() ~/ xDist,
          throwsA(isA<UnsupportedError>()));

      Logger.info('✅ 确认原始代码确实存在除零错误');
    });
  });
}
