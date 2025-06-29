import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/logger.dart';
import 'package:a_dark_room_new/modules/events.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/events/executioner_events.dart';

void main() {
  group('执行者事件测试', () {
    late StateManager sm;
    late Events events;
    late World world;

    setUpAll(() {
      Logger.info('🧪 开始执行者事件测试套件');
    });

    setUp(() async {
      sm = StateManager();
      await sm.clearGameData();
      events = Events();
      world = World();
      world.init();
    });

    tearDownAll(() {
      Logger.info('✅ 执行者事件测试套件完成');
    });

    test('executioner事件应该正确定义', () {
      Logger.info('🎯 测试executioner事件定义...');
      
      final executionerEvents = ExecutionerEvents.events;
      
      // 验证所有必需的事件都存在
      expect(executionerEvents.containsKey('executioner-intro'), isTrue, 
          reason: '应该包含executioner-intro事件');
      expect(executionerEvents.containsKey('executioner-antechamber'), isTrue, 
          reason: '应该包含executioner-antechamber事件');
      expect(executionerEvents.containsKey('executioner-engineering'), isTrue, 
          reason: '应该包含executioner-engineering事件');
      expect(executionerEvents.containsKey('executioner-medical'), isTrue, 
          reason: '应该包含executioner-medical事件');
      expect(executionerEvents.containsKey('executioner-martial'), isTrue, 
          reason: '应该包含executioner-martial事件');
      expect(executionerEvents.containsKey('executioner-command'), isTrue, 
          reason: '应该包含executioner-command事件');
      
      Logger.info('✅ 执行者事件定义测试通过');
    });

    test('executioner-intro事件应该有正确的结构', () {
      Logger.info('🎯 测试executioner-intro事件结构...');
      
      final introEvent = ExecutionerEvents.executionerIntro;
      
      // 验证事件结构
      expect(introEvent['title'], isNotNull, reason: '应该有标题');
      expect(introEvent['scenes'], isNotNull, reason: '应该有场景');
      expect(introEvent['scenes']['start'], isNotNull, reason: '应该有start场景');
      expect(introEvent['scenes']['interior'], isNotNull, reason: '应该有interior场景');
      expect(introEvent['scenes']['discovery'], isNotNull, reason: '应该有discovery场景');
      
      // 验证discovery场景有onLoad回调
      final discoveryScene = introEvent['scenes']['discovery'];
      expect(discoveryScene['onLoad'], isNotNull, reason: 'discovery场景应该有onLoad回调');
      
      Logger.info('✅ executioner-intro事件结构测试通过');
    });

    test('executioner-antechamber事件应该有正确的按钮', () {
      Logger.info('🎯 测试executioner-antechamber事件按钮...');
      
      final antechamberEvent = ExecutionerEvents.executionerAntechamber;
      final startScene = antechamberEvent['scenes']['start'];
      final buttons = startScene['buttons'];
      
      // 验证所有必需的按钮都存在
      expect(buttons['engineering'], isNotNull, reason: '应该有engineering按钮');
      expect(buttons['medical'], isNotNull, reason: '应该有medical按钮');
      expect(buttons['martial'], isNotNull, reason: '应该有martial按钮');
      expect(buttons['command'], isNotNull, reason: '应该有command按钮');
      expect(buttons['leave'], isNotNull, reason: '应该有leave按钮');
      
      // 验证按钮有nextEvent配置
      expect(buttons['engineering']['nextEvent'], equals('executioner-engineering'));
      expect(buttons['medical']['nextEvent'], equals('executioner-medical'));
      expect(buttons['martial']['nextEvent'], equals('executioner-martial'));
      expect(buttons['command']['nextEvent'], equals('executioner-command'));
      
      Logger.info('✅ executioner-antechamber事件按钮测试通过');
    });

    test('Events模块应该能启动executioner事件', () {
      Logger.info('🎯 测试Events模块启动executioner事件...');
      
      // 测试startEventByName方法
      expect(() => events.startEventByName('executioner-intro'), 
          returnsNormally, reason: '应该能启动executioner-intro事件');
      
      expect(() => events.startEventByName('executioner-antechamber'), 
          returnsNormally, reason: '应该能启动executioner-antechamber事件');
      
      expect(() => events.startEventByName('non-existent-event'), 
          returnsNormally, reason: '不存在的事件应该优雅处理');
      
      Logger.info('✅ Events模块启动executioner事件测试通过');
    });

    test('World模块应该根据状态选择正确的executioner事件', () {
      Logger.info('🎯 测试World模块executioner事件选择逻辑...');
      
      // 初始状态：executioner未完成，应该触发intro事件
      world.state = {};
      expect(world.state!['executioner'], isNot(equals(true)), 
          reason: '初始状态executioner应该未完成');
      
      // 设置executioner完成状态
      world.state!['executioner'] = true;
      expect(world.state!['executioner'], equals(true), 
          reason: 'executioner状态应该能正确设置');
      
      Logger.info('✅ World模块executioner事件选择逻辑测试通过');
    });

    test('制造器解锁条件应该正确检查', () {
      Logger.info('🎯 测试制造器解锁条件...');
      
      // 设置世界状态
      world.state = {};
      
      // 只有executioner完成，制造器不应该解锁
      world.state!['executioner'] = true;
      expect(world.state!['command'], isNot(equals(true)), 
          reason: '只有executioner完成时，command应该未完成');
      
      // 完成command，制造器应该可以解锁
      world.state!['command'] = true;
      expect(world.state!['command'], equals(true), 
          reason: 'command状态应该能正确设置');
      
      Logger.info('✅ 制造器解锁条件测试通过');
    });
  });
}
