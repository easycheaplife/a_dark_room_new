import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/engine.dart';
import '../lib/core/state_manager.dart';
import '../lib/core/localization.dart';
import '../lib/core/notifications.dart';
import '../lib/core/progress_manager.dart';
import '../lib/modules/room.dart';
import '../lib/modules/outside.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// 性能测试
/// 
/// 测试覆盖范围：
/// 1. 状态管理器性能
/// 2. 通知系统性能
/// 3. 进度管理器性能
/// 4. 模块切换性能
/// 5. 内存使用效率
void main() {
  group('⚡ 性能测试', () {
    late Engine engine;
    late StateManager stateManager;
    late Localization localization;
    late NotificationManager notificationManager;
    late ProgressManager progressManager;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始性能测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      engine = Engine();
      stateManager = StateManager();
      localization = Localization();
      notificationManager = NotificationManager();
      progressManager = ProgressManager();
      
      // 初始化系统
      await engine.init();
      await localization.init();
      stateManager.init();
      notificationManager.init();
    });

    tearDown() {
      engine.dispose();
      localization.dispose();
      progressManager.dispose();
    }

    group('📊 状态管理器性能测试', () {
      test('应该快速处理大量状态读取操作', () async {
        Logger.info('🧪 测试大量状态读取性能');

        // 设置测试数据
        for (int i = 0; i < 100; i++) {
          stateManager.set('test.item_$i', i);
        }

        // 测量读取性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          final value = stateManager.get('test.item_${i % 100}', true);
          expect(value, equals(i % 100));
        }
        
        stopwatch.stop();
        final readTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 1000次状态读取耗时: ${readTime}ms');
        expect(readTime, lessThan(100), reason: '状态读取应该在100ms内完成');
        
        Logger.info('✅ 状态读取性能测试通过');
      });

      test('应该快速处理大量状态写入操作', () async {
        Logger.info('🧪 测试大量状态写入性能');

        // 测量写入性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          stateManager.set('performance.write_$i', i);
        }
        
        stopwatch.stop();
        final writeTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 1000次状态写入耗时: ${writeTime}ms');
        expect(writeTime, lessThan(200), reason: '状态写入应该在200ms内完成');
        
        // 验证数据正确性
        for (int i = 0; i < 100; i++) {
          final value = stateManager.get('performance.write_$i', true);
          expect(value, equals(i));
        }
        
        Logger.info('✅ 状态写入性能测试通过');
      });

      test('应该快速处理状态更新操作', () async {
        Logger.info('🧪 测试状态更新性能');

        // 初始化数据
        stateManager.set('stores.wood', 0);
        
        // 测量更新性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          stateManager.add('stores.wood', 1);
        }
        
        stopwatch.stop();
        final updateTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 1000次状态更新耗时: ${updateTime}ms');
        expect(updateTime, lessThan(150), reason: '状态更新应该在150ms内完成');
        
        // 验证最终值
        expect(stateManager.get('stores.wood', true), equals(1000));
        
        Logger.info('✅ 状态更新性能测试通过');
      });
    });

    group('📢 通知系统性能测试', () {
      test('应该快速处理大量通知', () async {
        Logger.info('🧪 测试大量通知处理性能');

        // 测量通知处理性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 500; i++) {
          notificationManager.notify('performance', '性能测试通知 $i');
        }
        
        stopwatch.stop();
        final notifyTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 500个通知处理耗时: ${notifyTime}ms');
        expect(notifyTime, lessThan(100), reason: '通知处理应该在100ms内完成');
        
        // 验证通知数量
        final notifications = notificationManager.getAllNotifications();
        expect(notifications.length, equals(500));
        
        Logger.info('✅ 通知处理性能测试通过');
      });

      test('应该快速处理通知查询', () async {
        Logger.info('🧪 测试通知查询性能');

        // 添加测试通知
        for (int i = 0; i < 100; i++) {
          notificationManager.notify('module_$i', '测试通知 $i');
        }

        // 测量查询性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 1000; i++) {
          final notifications = notificationManager.getNotificationsForModule('module_${i % 100}');
          expect(notifications.length, equals(1));
        }
        
        stopwatch.stop();
        final queryTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 1000次通知查询耗时: ${queryTime}ms');
        expect(queryTime, lessThan(50), reason: '通知查询应该在50ms内完成');
        
        Logger.info('✅ 通知查询性能测试通过');
      });
    });

    group('⏱️ 进度管理器性能测试', () {
      test('应该快速处理进度创建和销毁', () async {
        Logger.info('🧪 测试进度创建销毁性能');

        // 测量进度管理性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          progressManager.startProgress(
            id: 'perf_test_$i',
            duration: 100,
            onComplete: () {},
          );
          progressManager.cancelProgress('perf_test_$i');
        }
        
        stopwatch.stop();
        final progressTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 100个进度创建销毁耗时: ${progressTime}ms');
        expect(progressTime, lessThan(50), reason: '进度管理应该在50ms内完成');
        
        // 验证没有残留进度
        expect(progressManager.hasActiveProgress, isFalse);
        
        Logger.info('✅ 进度管理性能测试通过');
      });

      test('应该高效处理并发进度', () async {
        Logger.info('🧪 测试并发进度处理性能');

        // 测量并发进度性能
        final stopwatch = Stopwatch()..start();
        
        // 创建多个并发进度
        for (int i = 0; i < 50; i++) {
          progressManager.startProgress(
            id: 'concurrent_$i',
            duration: 1000,
            onComplete: () {},
          );
        }
        
        stopwatch.stop();
        final concurrentTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 50个并发进度创建耗时: ${concurrentTime}ms');
        expect(concurrentTime, lessThan(30), reason: '并发进度创建应该在30ms内完成');
        
        // 验证所有进度都在运行
        expect(progressManager.hasActiveProgress, isTrue);
        
        // 清理进度
        for (int i = 0; i < 50; i++) {
          progressManager.cancelProgress('concurrent_$i');
        }
        
        Logger.info('✅ 并发进度性能测试通过');
      });
    });

    group('🔄 模块切换性能测试', () {
      test('应该快速处理模块切换', () async {
        Logger.info('🧪 测试模块切换性能');

        final room = Room();
        final outside = Outside();
        
        // 测量模块切换性能
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          engine.activeModule = i % 2 == 0 ? room : outside;
        }
        
        stopwatch.stop();
        final switchTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 100次模块切换耗时: ${switchTime}ms');
        expect(switchTime, lessThan(50), reason: '模块切换应该在50ms内完成');
        
        Logger.info('✅ 模块切换性能测试通过');
      });
    });

    group('💾 内存使用效率测试', () {
      test('应该有效管理状态存储内存', () async {
        Logger.info('🧪 测试状态存储内存效率');

        // 记录初始状态
        final initialStates = stateManager.getAllStates().length;
        
        // 添加大量状态
        for (int i = 0; i < 1000; i++) {
          stateManager.set('memory.test_$i', 'value_$i');
        }
        
        // 验证状态数量
        final afterAddStates = stateManager.getAllStates().length;
        expect(afterAddStates, equals(initialStates + 1000));
        
        // 清理部分状态
        for (int i = 0; i < 500; i++) {
          stateManager.remove('memory.test_$i');
        }
        
        // 验证内存清理
        final afterCleanStates = stateManager.getAllStates().length;
        expect(afterCleanStates, equals(initialStates + 500));
        
        Logger.info('✅ 状态存储内存效率测试通过');
      });

      test('应该有效管理通知内存', () async {
        Logger.info('🧪 测试通知内存效率');

        // 添加大量通知
        for (int i = 0; i < 200; i++) {
          notificationManager.notify('memory', '内存测试通知 $i');
        }
        
        // 验证通知数量限制（应该有最大限制）
        final notifications = notificationManager.getAllNotifications();
        expect(notifications.length, lessThanOrEqualTo(100), 
               reason: '通知应该有数量限制以控制内存使用');
        
        Logger.info('✅ 通知内存效率测试通过');
      });
    });

    group('🎯 综合性能测试', () {
      test('应该在复杂场景下保持良好性能', () async {
        Logger.info('🧪 测试复杂场景综合性能');

        final stopwatch = Stopwatch()..start();
        
        // 模拟复杂的游戏场景
        for (int i = 0; i < 50; i++) {
          // 状态更新
          stateManager.set('stores.wood', i);
          stateManager.add('stores.fur', 1);
          
          // 通知发送
          notificationManager.notify('complex', '复杂场景通知 $i');
          
          // 进度管理
          progressManager.startProgress(
            id: 'complex_$i',
            duration: 100,
            onComplete: () {},
          );
          
          // 模块切换
          engine.activeModule = i % 2 == 0 ? Room() : Outside();
          
          // 清理进度
          progressManager.cancelProgress('complex_$i');
        }
        
        stopwatch.stop();
        final complexTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 50轮复杂场景耗时: ${complexTime}ms');
        expect(complexTime, lessThan(200), reason: '复杂场景应该在200ms内完成');
        
        // 验证最终状态正确
        expect(stateManager.get('stores.wood', true), equals(49));
        expect(stateManager.get('stores.fur', true), equals(50));
        
        Logger.info('✅ 复杂场景综合性能测试通过');
      });

      test('应该在高负载下保持稳定', () async {
        Logger.info('🧪 测试高负载稳定性');

        final stopwatch = Stopwatch()..start();
        
        // 模拟高负载场景
        final futures = <Future>[];
        
        for (int i = 0; i < 20; i++) {
          futures.add(Future(() async {
            for (int j = 0; j < 50; j++) {
              stateManager.add('load.counter', 1);
              notificationManager.notify('load', '负载测试 $i-$j');
            }
          }));
        }
        
        await Future.wait(futures);
        
        stopwatch.stop();
        final loadTime = stopwatch.elapsedMilliseconds;
        
        Logger.info('📊 高负载测试耗时: ${loadTime}ms');
        expect(loadTime, lessThan(500), reason: '高负载应该在500ms内完成');
        
        // 验证数据一致性
        expect(stateManager.get('load.counter', true), equals(1000));
        
        Logger.info('✅ 高负载稳定性测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 性能测试套件完成');
    });
  });
}
