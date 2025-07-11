// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

/*
  flutter test test/landmarks_test.dart --name "Map landmark statistics"
*/
import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/modules/world.dart';

import 'package:a_dark_room_new/core/logger.dart';

void main() {
  group('Cache Landmark Generation Tests', () {
    late StateManager stateManager;
    late World world;

    setUp(() {
      stateManager = StateManager();
      world = World();
    });

    test('Map landmark statistics without prestige data', () {
      // 确保没有prestige数据
      stateManager.remove('previous.stores');

      // 初始化世界
      world.init();

      // 生成地图
      final map = world.generateMap();

      // 统计所有地标
      final landmarkCounts = <String, int>{};
      final landmarkPositions = <String, List<String>>{};

      for (int i = 0; i < map.length; i++) {
        for (int j = 0; j < map[i].length; j++) {
          final tile = map[i][j];
          if (tile != '.' &&
              tile != ',' &&
              tile != ';' &&
              tile != '#' &&
              tile != 'A') {
            landmarkCounts[tile] = (landmarkCounts[tile] ?? 0) + 1;
            landmarkPositions[tile] ??= [];
            final distance = (i - 30).abs() + (j - 30).abs();
            landmarkPositions[tile]!.add('($i,$j,距离:$distance)');
          }
        }
      }

      // 输出地标统计
      Logger.info('\n=== 地图地标统计 (无prestige数据) ===');
      Logger.info('总地标类型数: ${landmarkCounts.length}');
      Logger.info('总地标数量: ${landmarkCounts.values.fold(0, (a, b) => a + b)}');

      final sortedLandmarks = landmarkCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedLandmarks) {
        final positions = landmarkPositions[entry.key]!.take(3).join(', ');
        final moreText = landmarkPositions[entry.key]!.length > 3
            ? '... (+${landmarkPositions[entry.key]!.length - 3}个)'
            : '';
        Logger.info('${entry.key}: ${entry.value}个 - $positions$moreText');
      }
      Logger.info('=====================================\n');

      // 验证缓存地标不存在
      expect(landmarkCounts.containsKey('U'), false);
    });

    test('Map landmark statistics with prestige data', () {
      // 设置prestige数据
      stateManager.set('previous.stores', [10, 5, 3, 2, 1]);

      // 初始化世界
      world.init();

      // 生成地图
      final map = world.generateMap();

      // 统计所有地标
      final landmarkCounts = <String, int>{};
      final landmarkPositions = <String, List<String>>{};

      for (int i = 0; i < map.length; i++) {
        for (int j = 0; j < map[i].length; j++) {
          final tile = map[i][j];
          if (tile != '.' &&
              tile != ',' &&
              tile != ';' &&
              tile != '#' &&
              tile != 'A') {
            landmarkCounts[tile] = (landmarkCounts[tile] ?? 0) + 1;
            landmarkPositions[tile] ??= [];
            final distance = (i - 30).abs() + (j - 30).abs();
            landmarkPositions[tile]!.add('($i,$j,距离:$distance)');
          }
        }
      }

      // 输出地标统计
      Logger.info('\n=== 地图地标统计 (有prestige数据) ===');
      Logger.info('总地标类型数: ${landmarkCounts.length}');
      Logger.info('总地标数量: ${landmarkCounts.values.fold(0, (a, b) => a + b)}');

      final sortedLandmarks = landmarkCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedLandmarks) {
        final positions = landmarkPositions[entry.key]!.take(3).join(', ');
        final moreText = landmarkPositions[entry.key]!.length > 3
            ? '... (+${landmarkPositions[entry.key]!.length - 3}个)'
            : '';
        Logger.info('${entry.key}: ${entry.value}个 - $positions$moreText');
      }
      Logger.info('=====================================\n');

      // 验证缓存地标存在
      expect(landmarkCounts.containsKey('U'), true);
      expect(landmarkCounts['U'], 1);
    });
  });
}
