import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/events/room_events_extended.dart';
import 'package:a_dark_room_new/events/room_events.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/core/logger.dart';

void main() {
  group('Event Button Behavior Tests', () {
    late StateManager stateManager;
    late Events events;

    setUp(() {
      stateManager = StateManager();
      events = Events();
      
      // 初始化世界模块
      World.instance.init();
      
      // 设置测试环境
      stateManager.set('features.location.world', true);
      stateManager.set('stores.fur', 2000);
      stateManager.set('stores.scales', 200);
      stateManager.set('stores.teeth', 100);
      stateManager.set('game.fire.value', 10);
      
      Logger.info('🧪 Event button behavior test setup completed');
    });

    test('Scout event - buttons without nextScene should not end event', () {
      Logger.info('🧪 Testing scout event button behavior');
      
      final scoutEvent = RoomEventsExtended.scout;
      final startScene = scoutEvent['scenes']['start'];
      final buttons = startScene['buttons'] as Map<String, dynamic>;
      
      // 启动事件
      events.startEvent(scoutEvent);
      expect(events.activeEvent(), isNotNull);
      
      // 测试购买地图按钮（没有nextScene）
      final buyMapButton = buttons['buyMap'];
      expect(buyMapButton['nextScene'], isNull, 
          reason: 'Buy map button should not have nextScene');
      
      events.handleButtonClick('buyMap', buyMapButton);
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active after buying map');
      
      // 测试学习按钮（没有nextScene）
      final learnButton = buttons['learn'];
      expect(learnButton['nextScene'], isNull, 
          reason: 'Learn button should not have nextScene');
      
      events.handleButtonClick('learn', learnButton);
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active after learning');
      
      // 测试离开按钮（有nextScene: 'end'）
      final leaveButton = buttons['leave'];
      expect(leaveButton['nextScene'], equals('end'), 
          reason: 'Leave button should have nextScene: end');
      
      events.handleButtonClick('leave', leaveButton);
      expect(events.activeEvent(), isNull, 
          reason: 'Event should end after clicking leave');
      
      Logger.info('🧪 Scout event button behavior test completed');
    });

    test('Nomad event - buttons without nextScene should not end event', () {
      Logger.info('🧪 Testing nomad event button behavior');
      
      final nomadEvent = RoomEvents.nomad;
      final startScene = nomadEvent['scenes']['start'];
      final buttons = startScene['buttons'] as Map<String, dynamic>;
      
      // 启动事件
      events.startEvent(nomadEvent);
      expect(events.activeEvent(), isNotNull);
      
      // 测试购买按钮（没有nextScene）
      final buyScalesButton = buttons['buyScales'];
      expect(buyScalesButton['nextScene'], isNull, 
          reason: 'Buy scales button should not have nextScene');
      
      events.handleButtonClick('buyScales', buyScalesButton);
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active after buying scales');
      
      final buyTeethButton = buttons['buyTeeth'];
      expect(buyTeethButton['nextScene'], isNull, 
          reason: 'Buy teeth button should not have nextScene');
      
      events.handleButtonClick('buyTeeth', buyTeethButton);
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active after buying teeth');
      
      // 测试告别按钮（有nextScene: 'end'）
      final goodbyeButton = buttons['goodbye'];
      expect(goodbyeButton['nextScene'], equals('end'), 
          reason: 'Goodbye button should have nextScene: end');
      
      events.handleButtonClick('goodbye', goodbyeButton);
      expect(events.activeEvent(), isNull, 
          reason: 'Event should end after clicking goodbye');
      
      Logger.info('🧪 Nomad event button behavior test completed');
    });

    test('Event button behavior consistency', () {
      Logger.info('🧪 Testing event button behavior consistency');
      
      // 测试原则：
      // 1. 没有nextScene的按钮不应该结束事件
      // 2. 有nextScene: 'end'的按钮应该结束事件
      // 3. 有其他nextScene的按钮应该跳转场景
      
      final testEvent = {
        'title': 'Test Event',
        'scenes': {
          'start': {
            'text': ['Test event'],
            'buttons': {
              'noNextScene': {
                'text': 'No Next Scene',
                // 没有nextScene配置
              },
              'endEvent': {
                'text': 'End Event',
                'nextScene': 'end'
              },
              'jumpScene': {
                'text': 'Jump Scene',
                'nextScene': 'other'
              }
            }
          },
          'other': {
            'text': ['Other scene'],
            'buttons': {
              'finish': {
                'text': 'Finish',
                'nextScene': 'end'
              }
            }
          }
        }
      };
      
      // 启动测试事件
      events.startEvent(testEvent);
      expect(events.activeEvent(), isNotNull);
      expect(events.activeScene, equals('start'));
      
      // 测试没有nextScene的按钮
      events.handleButtonClick('noNextScene', {'text': 'No Next Scene'});
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active for button without nextScene');
      expect(events.activeScene, equals('start'), 
          reason: 'Should stay in same scene for button without nextScene');
      
      // 测试跳转场景的按钮
      events.handleButtonClick('jumpScene', {'text': 'Jump Scene', 'nextScene': 'other'});
      expect(events.activeEvent(), isNotNull, 
          reason: 'Event should remain active when jumping to other scene');
      expect(events.activeScene, equals('other'), 
          reason: 'Should jump to other scene');
      
      // 测试结束事件的按钮
      events.handleButtonClick('finish', {'text': 'Finish', 'nextScene': 'end'});
      expect(events.activeEvent(), isNull, 
          reason: 'Event should end when nextScene is end');
      
      Logger.info('🧪 Event button behavior consistency test completed');
    });
  });
}
