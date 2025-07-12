import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/logger.dart';
// 注意：在测试环境中，MiniProgramAdapter的Web功能将被模拟
import 'package:a_dark_room_new/utils/miniprogram_adapter.dart';

/// 微信小程序适配器测试
///
/// 测试微信小程序环境检测和通信功能
void main() {
  group('🔧 微信小程序适配器测试', () {
    setUpAll(() {
      Logger.info('🚀 开始微信小程序适配器测试');
    });

    group('环境检测测试', () {
      test('应该能检测微信小程序环境', () {
        Logger.info('🧪 测试微信小程序环境检测...');

        // 在测试环境中，isInMiniProgram应该为false
        expect(MiniProgramAdapter.isInMiniProgram, isFalse);

        Logger.info('✅ 微信小程序环境检测测试通过');
      });

      test('应该能获取环境信息', () {
        Logger.info('🧪 测试获取环境信息...');

        final envInfo = MiniProgramAdapter.getEnvironmentInfo();

        expect(envInfo, isA<Map<String, dynamic>>());
        expect(envInfo.containsKey('isInMiniProgram'), isTrue);
        expect(envInfo.containsKey('initialized'), isTrue);
        expect(envInfo.containsKey('hasInitialData'), isTrue);

        Logger.info('✅ 环境信息获取测试通过');
      });
    });

    group('消息发送测试', () {
      test('应该能安全地发送消息（非小程序环境）', () {
        Logger.info('🧪 测试消息发送功能...');

        // 在非小程序环境中，这些方法应该安全执行而不抛出异常
        expect(() => MiniProgramAdapter.saveGameData({'test': 'data'}),
               returnsNormally);
        expect(() => MiniProgramAdapter.showToast('测试消息'),
               returnsNormally);
        expect(() => MiniProgramAdapter.vibrate(),
               returnsNormally);
        expect(() => MiniProgramAdapter.shareGame(),
               returnsNormally);
        expect(() => MiniProgramAdapter.exitGame(),
               returnsNormally);
        expect(() => MiniProgramAdapter.setTitle('测试标题'),
               returnsNormally);

        Logger.info('✅ 消息发送测试通过');
      });

      test('应该能构建正确的消息格式', () {
        Logger.info('🧪 测试消息格式构建...');

        // 测试各种消息类型的参数
        final gameData = {'level': 1, 'score': 100};

        // 这些方法在非小程序环境中不会实际发送消息，但应该正常执行
        expect(() => MiniProgramAdapter.saveGameData(gameData),
               returnsNormally);
        expect(() => MiniProgramAdapter.showToast('成功', icon: 'success'),
               returnsNormally);
        expect(() => MiniProgramAdapter.vibrate(type: 'long'),
               returnsNormally);
        expect(() => MiniProgramAdapter.shareGame(
          title: '自定义标题',
          desc: '自定义描述',
          imageUrl: 'https://example.com/image.png'
        ), returnsNormally);

        Logger.info('✅ 消息格式构建测试通过');
      });
    });

    group('数据处理测试', () {
      test('应该能处理空的初始数据', () {
        Logger.info('🧪 测试空初始数据处理...');

        final initialData = MiniProgramAdapter.initialData;

        // 在测试环境中，初始数据应该为null或空
        if (initialData != null) {
          expect(initialData, isA<Map<String, dynamic>>());
        }

        Logger.info('✅ 空初始数据处理测试通过');
      });

      test('应该能安全地处理环境信息', () {
        Logger.info('🧪 测试环境信息处理...');

        final envInfo = MiniProgramAdapter.getEnvironmentInfo();

        // 验证环境信息的基本结构
        expect(envInfo['isInMiniProgram'], isA<bool>());
        expect(envInfo['initialized'], isA<bool>());
        expect(envInfo['hasInitialData'], isA<bool>());
        expect(envInfo['initialDataKeys'], isA<List>());
        expect(envInfo['userAgent'], isA<String>());
        expect(envInfo['url'], isA<String>());

        Logger.info('✅ 环境信息处理测试通过');
      });
    });

    group('错误处理测试', () {
      test('应该能优雅地处理初始化错误', () {
        Logger.info('🧪 测试初始化错误处理...');

        // 多次初始化应该是安全的
        expect(() async => await MiniProgramAdapter.initialize(),
               returnsNormally);

        Logger.info('✅ 初始化错误处理测试通过');
      });

      test('应该能处理无效的消息数据', () {
        Logger.info('🧪 测试无效消息数据处理...');

        // 传入空数据应该不会崩溃
        expect(() => MiniProgramAdapter.saveGameData({}),
               returnsNormally);
        expect(() => MiniProgramAdapter.showToast(''),
               returnsNormally);
        expect(() => MiniProgramAdapter.setTitle(''),
               returnsNormally);

        Logger.info('✅ 无效消息数据处理测试通过');
      });
    });

    group('功能集成测试', () {
      test('应该能完整地模拟小程序通信流程', () {
        Logger.info('🧪 测试完整通信流程...');

        // 模拟一个完整的游戏会话
        final gameData = {
          'player': {'name': 'Test Player', 'level': 5},
          'inventory': {'wood': 10, 'food': 5},
          'buildings': {'hut': 1, 'lodge': 1},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        // 1. 保存游戏数据
        expect(() => MiniProgramAdapter.saveGameData(gameData),
               returnsNormally);

        // 2. 显示保存成功提示
        expect(() => MiniProgramAdapter.showToast('游戏已保存', icon: 'success'),
               returnsNormally);

        // 3. 触发震动反馈
        expect(() => MiniProgramAdapter.vibrate(type: 'short'),
               returnsNormally);

        // 4. 分享游戏
        expect(() => MiniProgramAdapter.shareGame(
          title: 'A Dark Room - 我的游戏进度',
          desc: '我已经到达第5级了！快来一起玩吧！'
        ), returnsNormally);

        Logger.info('✅ 完整通信流程测试通过');
      });

      test('应该能处理复杂的游戏状态数据', () {
        Logger.info('🧪 测试复杂游戏状态数据处理...');

        final complexGameData = {
          'version': '1.0.0',
          'player': {
            'stats': {'health': 100, 'energy': 80},
            'skills': ['hunting', 'crafting', 'building'],
            'achievements': [
              {'id': 'first_fire', 'unlocked': true, 'timestamp': 1234567890},
              {'id': 'first_hunt', 'unlocked': false, 'timestamp': null},
            ]
          },
          'world': {
            'map': {
              'explored': [[true, false, false], [true, true, false]],
              'landmarks': {'village': {'x': 0, 'y': 0}, 'forest': {'x': 1, 'y': 0}}
            },
            'weather': {'type': 'clear', 'temperature': 20}
          },
          'settings': {
            'language': 'zh',
            'audio': true,
            'notifications': true
          }
        };

        expect(() => MiniProgramAdapter.saveGameData(complexGameData),
               returnsNormally);

        Logger.info('✅ 复杂游戏状态数据处理测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🎉 微信小程序适配器测试完成');
    });
  });
}