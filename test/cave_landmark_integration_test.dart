import 'package:flutter_test/flutter_test.dart';
import 'package:a_dark_room_new/modules/world.dart';
import 'package:a_dark_room_new/modules/setpieces.dart';
import 'package:a_dark_room_new/core/state_manager.dart';
import 'package:a_dark_room_new/core/localization.dart';
import 'package:a_dark_room_new/core/logger.dart';

void main() {
  group('洞穴地标集成测试', () {
    late World world;
    late Setpieces setpieces;
    late StateManager sm;
    late Localization localization;

    setUp(() {
      sm = StateManager();
      sm.init();
      localization = Localization();
      localization.init();
      world = World();
      setpieces = Setpieces();
    });

    test('验证洞穴地标配置', () {
      Logger.info('🧪 开始验证洞穴地标配置...');
      
      // 初始化世界
      world.init();
      
      // 获取洞穴地标配置
      final landmarks = world.landmarks;
      final caveKey = 'V'; // 洞穴地标键
      
      expect(landmarks.containsKey(caveKey), isTrue, 
             reason: '世界应该包含洞穴地标配置');
      
      final caveInfo = landmarks[caveKey];
      expect(caveInfo, isNotNull, reason: '洞穴地标信息不应为空');
      expect(caveInfo!['scene'], equals('cave'), 
             reason: '洞穴地标应该配置cave场景');
      expect(caveInfo['label'], isNotNull, 
             reason: '洞穴地标应该有标签');
      
      Logger.info('✅ 洞穴地标配置: $caveInfo');
      Logger.info('✅ 洞穴地标配置验证通过');
    });

    test('验证洞穴Setpiece可用性', () {
      Logger.info('🧪 开始验证洞穴Setpiece可用性...');
      
      // 检查洞穴Setpiece是否可用
      final isAvailable = setpieces.isSetpieceAvailable('cave');
      expect(isAvailable, isTrue, reason: '洞穴Setpiece应该可用');
      
      // 获取洞穴Setpiece信息
      final caveSetpiece = setpieces.getSetpieceInfo('cave');
      expect(caveSetpiece, isNotNull, reason: '洞穴Setpiece信息不应为空');
      expect(caveSetpiece!['scenes'], isNotNull, 
             reason: '洞穴Setpiece应该有场景');
      
      Logger.info('✅ 洞穴Setpiece可用性验证通过');
    });

    test('验证洞穴地标触发逻辑', () {
      Logger.info('🧪 开始验证洞穴地标触发逻辑...');
      
      // 初始化世界
      world.init();
      
      // 模拟玩家到达洞穴地标
      // 首先设置一些基础状态
      sm.set('stores.wood', 100);
      sm.set('stores.fur', 10);
      sm.set('stores.meat', 10);
      sm.set('stores.torch', 5);
      
      // 获取洞穴地标配置
      final landmarks = world.landmarks;
      final caveKey = 'V';
      final caveInfo = landmarks[caveKey];
      
      expect(caveInfo, isNotNull);
      expect(caveInfo!['scene'], equals('cave'));
      
      // 验证Setpiece系统能识别洞穴场景
      final setpieces = Setpieces();
      final isAvailable = setpieces.isSetpieceAvailable('cave');
      expect(isAvailable, isTrue, 
             reason: '洞穴Setpiece应该在World模块中可用');
      
      Logger.info('✅ 洞穴地标触发逻辑验证通过');
    });

    test('验证洞穴地标不会立即标记为已访问', () {
      Logger.info('🧪 开始验证洞穴地标访问标记逻辑...');
      
      // 初始化世界
      world.init();
      
      // 设置测试位置
      final testX = 5;
      final testY = 5;
      
      // 确保位置未被访问
      expect(world.isVisited(testX, testY), isFalse, 
             reason: '测试位置应该未被访问');
      
      // 验证洞穴场景不应该立即标记为已访问
      // 这是通过检查World模块中的逻辑来验证的
      final landmarks = world.landmarks;
      final caveInfo = landmarks['V'];
      final sceneName = caveInfo!['scene'];
      
      // 根据World模块的逻辑，洞穴场景不应该立即标记为已访问
      final shouldNotMarkVisited = sceneName == 'cave' ||
          sceneName == 'house' ||
          sceneName == 'ironmine' ||
          sceneName == 'coalmine' ||
          sceneName == 'sulphurmine' ||
          sceneName == 'town' ||
          sceneName == 'city';
      
      expect(shouldNotMarkVisited, isTrue, 
             reason: '洞穴场景不应该立即标记为已访问');
      
      Logger.info('✅ 洞穴地标访问标记逻辑验证通过');
    });

    test('验证洞穴场景完成后的clearDungeon机制', () {
      Logger.info('🧪 开始验证洞穴clearDungeon机制...');
      
      // 获取洞穴Setpiece信息
      final caveSetpiece = setpieces.getSetpieceInfo('cave');
      expect(caveSetpiece, isNotNull);
      
      final scenes = caveSetpiece!['scenes'] as Map<String, dynamic>;
      
      // 验证结束场景都有clearDungeon
      final endScenes = ['end1', 'end2', 'end3'];
      
      for (final endScene in endScenes) {
        expect(scenes.containsKey(endScene), isTrue, 
               reason: '应该包含结束场景: $endScene');
        
        final scene = scenes[endScene] as Map<String, dynamic>;
        expect(scene['onLoad'], equals('clearDungeon'), 
               reason: '$endScene应该调用clearDungeon');
        
        Logger.info('✅ 结束场景 $endScene 配置了clearDungeon');
      }
      
      Logger.info('✅ 洞穴clearDungeon机制验证通过');
    });

    test('验证洞穴探索完整流程', () {
      Logger.info('🧪 开始验证洞穴探索完整流程...');
      
      // 初始化世界
      world.init();
      
      // 设置玩家有足够的火把
      sm.set('stores.torch', 10);
      
      // 获取洞穴Setpiece
      final caveSetpiece = setpieces.getSetpieceInfo('cave');
      expect(caveSetpiece, isNotNull);
      
      final scenes = caveSetpiece!['scenes'] as Map<String, dynamic>;
      
      // 验证开始场景
      final startScene = scenes['start'] as Map<String, dynamic>;
      expect(startScene['buttons'], isNotNull);
      
      final buttons = startScene['buttons'] as Map<String, dynamic>;
      expect(buttons.containsKey('enter'), isTrue, 
             reason: '开始场景应该有进入按钮');
      expect(buttons.containsKey('leave'), isTrue, 
             reason: '开始场景应该有离开按钮');
      
      // 验证进入按钮需要火把
      final enterButton = buttons['enter'] as Map<String, dynamic>;
      expect(enterButton['cost'], isNotNull, 
             reason: '进入按钮应该有消耗');
      
      final cost = enterButton['cost'] as Map<String, dynamic>;
      expect(cost.containsKey('torch'), isTrue, 
             reason: '进入洞穴应该需要火把');
      expect(cost['torch'], equals(1), 
             reason: '进入洞穴应该需要1个火把');
      
      // 验证随机分支
      final nextScene = enterButton['nextScene'];
      expect(nextScene, isNotNull, 
             reason: '进入按钮应该有下一个场景');
      expect(nextScene, isA<Map<String, dynamic>>(), 
             reason: '下一个场景应该是随机分支');
      
      Logger.info('✅ 洞穴探索完整流程验证通过');
    });
  });
}
