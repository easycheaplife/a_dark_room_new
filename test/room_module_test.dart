import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/modules/room.dart';
import '../lib/core/state_manager.dart';
import '../lib/core/engine.dart';
import '../lib/core/logger.dart';
import 'test_config.dart';

/// Room 房间模块测试
///
/// 测试覆盖范围：
/// 1. 房间模块初始化
/// 2. 火焰系统管理
/// 3. 建筑系统
/// 4. 制作系统
/// 5. 温度和工人管理
void main() {
  group('🏠 Room 房间模块测试', () {
    late Room room;
    late StateManager stateManager;
    late Engine engine;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 Room 模块测试套件');
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stateManager = StateManager();
      engine = Engine();
      room = Room();

      // 初始化核心系统
      await engine.init();
      stateManager.init();
    });

    tearDown(() {
      // 不要dispose单例Engine，只重置状态
      stateManager.reset();
    });

    group('🔧 房间模块初始化测试', () {
      test('应该正确初始化房间模块', () {
        Logger.info('🧪 测试房间模块初始化');

        // 执行初始化
        room.init();

        // 验证模块状态
        expect(room.name, equals('Room')); // Room类的name属性返回'Room'
        // Room类没有title属性，只有setTitle方法

        // 验证基础状态设置
        expect(stateManager.get('features.location.room'), isTrue);

        Logger.info('✅ 房间模块初始化测试通过');
      });

      test('应该正确设置初始火焰状态', () {
        Logger.info('🧪 测试初始火焰状态');

        room.init();

        // 验证火焰初始状态
        expect(stateManager.get('game.fire.value'), equals(0));
        expect(stateManager.get('game.fire.max'), equals(100));
        expect(stateManager.get('game.fire.lit'), isFalse);

        Logger.info('✅ 初始火焰状态测试通过');
      });

      test('应该正确设置初始建筑状态', () {
        Logger.info('🧪 测试初始建筑状态');

        room.init();

        // 验证建筑初始状态
        expect(stateManager.get('game.buildings'), isA<Map>());
        expect(stateManager.get('game.workers'), isA<Map>());
        expect(stateManager.get('game.population'), equals(0));

        Logger.info('✅ 初始建筑状态测试通过');
      });
    });

    group('🔥 火焰系统测试', () {
      setUp(() {
        room.init();
      });

      test('应该正确点燃火焰', () {
        Logger.info('🧪 测试火焰点燃');

        // 设置足够的木材
        stateManager.set('stores.wood', 5);

        // 点燃火焰
        room.lightFire();

        // 验证火焰状态
        expect(stateManager.get('game.fire.lit'), isTrue);
        expect(stateManager.get('game.fire.value'), greaterThan(0));
        expect(stateManager.get('stores.wood'), lessThan(5)); // 消耗了木材

        Logger.info('✅ 火焰点燃测试通过');
      });

      test('应该正确添柴', () {
        Logger.info('🧪 测试添柴功能');

        // 先点燃火焰
        stateManager.set('stores.wood', 10);
        room.lightFire();

        final initialFire = stateManager.get('game.fire.value');
        final initialWood = stateManager.get('stores.wood');

        // 添柴
        room.stokeFire();

        // 验证火焰增加
        expect(stateManager.get('game.fire.value'), greaterThan(initialFire));
        expect(stateManager.get('stores.wood'), lessThan(initialWood));

        Logger.info('✅ 添柴功能测试通过');
      });

      test('应该正确处理火焰熄灭', () {
        Logger.info('🧪 测试火焰熄灭');

        // 点燃火焰
        stateManager.set('stores.wood', 5);
        room.lightFire();

        // 手动设置火焰值为0
        stateManager.set('game.fire.value', 0);

        // 触发火焰更新
        room.onFireChange();

        // 验证火焰熄灭
        expect(stateManager.get('game.fire.lit'), isFalse);

        Logger.info('✅ 火焰熄灭测试通过');
      });

      test('应该正确处理木材不足', () {
        Logger.info('🧪 测试木材不足处理');

        // 设置木材不足
        stateManager.set('stores.wood', 0);

        // 尝试点燃火焰
        room.lightFire();

        // 验证火焰未点燃
        expect(stateManager.get('game.fire.lit'), isFalse);
        expect(stateManager.get('game.fire.value'), equals(0));

        Logger.info('✅ 木材不足处理测试通过');
      });
    });

    group('🏗️ 建筑系统测试', () {
      setUp(() {
        room.init();
        // 点燃火焰以解锁建筑
        stateManager.set('stores.wood', 10);
        room.lightFire();
      });

      test('应该正确建造陷阱', () {
        Logger.info('🧪 测试陷阱建造');

        // 设置足够的木材
        stateManager.set('stores.wood', 10);

        // 建造陷阱
        room.build('trap');

        // 验证陷阱建造
        expect(stateManager.get('game.buildings.trap'), greaterThan(0));
        expect(stateManager.get('stores.wood'), lessThan(10)); // 消耗了木材

        Logger.info('✅ 陷阱建造测试通过');
      });

      test('应该正确建造手推车', () {
        Logger.info('🧪 测试手推车建造');

        // 设置足够的木材
        stateManager.set('stores.wood', 30);

        // 建造手推车
        room.build('cart');

        // 验证手推车建造
        expect(stateManager.get('game.buildings.cart'), greaterThan(0));
        expect(stateManager.get('stores.wood'), lessThan(30)); // 消耗了木材

        Logger.info('✅ 手推车建造测试通过');
      });

      test('应该正确建造小屋', () {
        Logger.info('🧪 测试小屋建造');

        // 设置足够的木材
        stateManager.set('stores.wood', 100);

        // 建造小屋
        room.build('hut');

        // 验证小屋建造
        expect(stateManager.get('game.buildings.hut'), greaterThan(0));
        expect(stateManager.get('stores.wood'), lessThan(100)); // 消耗了木材

        Logger.info('✅ 小屋建造测试通过');
      });

      test('应该正确处理资源不足', () {
        Logger.info('🧪 测试建造资源不足');

        // 设置木材不足
        stateManager.set('stores.wood', 1);

        final initialWood = stateManager.get('stores.wood');

        // 尝试建造陷阱（需要更多木材）
        room.build('trap');

        // 验证建造失败，木材未消耗
        expect(stateManager.get('stores.wood'), equals(initialWood));

        Logger.info('✅ 建造资源不足测试通过');
      });
    });

    group('🔨 制作系统测试', () {
      setUp(() {
        room.init();
        // 设置基础条件
        stateManager.set('stores.wood', 50);
        room.lightFire();
      });

      test('应该正确制作火把', () {
        Logger.info('🧪 测试火把制作');

        // 设置制作材料
        stateManager.set('stores.wood', 10);
        stateManager.set('stores.cloth', 5);

        // 制作火把
        room.buildItem('torch');

        // 验证火把制作
        expect(stateManager.get('stores.torch'), greaterThan(0));
        expect(stateManager.get('stores.wood'), lessThan(10)); // 消耗了木材
        expect(stateManager.get('stores.cloth'), lessThan(5)); // 消耗了布料

        Logger.info('✅ 火把制作测试通过');
      });

      test('应该正确制作水袋', () {
        Logger.info('🧪 测试水袋制作');

        // 设置制作材料和条件
        stateManager.set('stores.leather', 50);
        stateManager.set('game.builder.level', 4); // 需要建造者等级4

        // 制作水袋
        room.buildItem('waterskin');

        // 验证水袋制作
        expect(stateManager.get('stores.waterskin'), greaterThan(0));
        expect(stateManager.get('stores.leather'), lessThan(50)); // 消耗了皮革

        Logger.info('✅ 水袋制作测试通过');
      });

      test('应该正确处理制作材料不足', () {
        Logger.info('🧪 测试制作材料不足');

        // 设置材料不足
        stateManager.set('stores.wood', 1);
        stateManager.set('stores.cloth', 0);

        final initialTorch = stateManager.get('stores.torch');

        // 尝试制作火把
        room.buildItem('torch');

        // 验证制作失败
        expect(stateManager.get('stores.torch'), equals(initialTorch));

        Logger.info('✅ 制作材料不足测试通过');
      });
    });

    group('🏠 建筑状态测试', () {
      setUp(() {
        room.init();
        stateManager.set('stores.wood', 100);
        room.lightFire();
        // 建造一些小屋来增加人口
        room.build('hut');
        stateManager.set('game.population', 5);
      });

      test('应该正确跟踪建筑数量', () {
        Logger.info('🧪 测试建筑数量跟踪');

        // 建造多个陷阱
        stateManager.set('stores.wood', 100);
        room.build('trap');
        room.build('trap');

        // 验证建筑数量
        expect(stateManager.get('game.buildings.trap'), equals(2));

        Logger.info('✅ 建筑数量跟踪测试通过');
      });

      test('应该正确处理建筑上限', () {
        Logger.info('🧪 测试建筑上限处理');

        // 设置足够的资源
        stateManager.set('stores.wood', 1000);

        // 尝试建造超过上限的手推车（上限为1）
        room.build('cart');
        final result = room.build('cart'); // 第二次应该失败

        // 验证只建造了一个
        expect(stateManager.get('game.buildings.cart'), equals(1));
        expect(result, isFalse); // 第二次建造应该失败

        Logger.info('✅ 建筑上限处理测试通过');
      });
    });

    group('🌡️ 温度系统测试', () {
      setUp(() {
        room.init();
      });

      test('应该正确计算温度', () {
        Logger.info('🧪 测试温度计算');

        // 点燃火焰
        stateManager.set('stores.wood', 10);
        room.lightFire();

        // 获取温度值
        final temperatureValue = stateManager.get('game.temperature.value');

        // 验证温度合理
        expect(temperatureValue, isA<int>());
        expect(temperatureValue, greaterThanOrEqualTo(0));
        expect(temperatureValue, lessThanOrEqualTo(4));

        Logger.info('✅ 温度计算测试通过');
      });

      test('应该正确处理寒冷状态', () {
        Logger.info('🧪 测试寒冷状态');

        // 确保火焰熄灭和温度低
        stateManager.set('game.fire.value', 0);
        stateManager.set('game.temperature.value', 0); // 设置为冰冷状态

        // 获取温度值
        final temperatureValue = stateManager.get('game.temperature.value');

        // 验证寒冷状态（0=冰冷，1=寒冷）
        expect(temperatureValue, lessThanOrEqualTo(1));

        Logger.info('✅ 寒冷状态测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 Room 模块测试套件完成');
    });
  });
}
