import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a_dark_room_new/core/audio_engine.dart';
import 'package:a_dark_room_new/core/audio_library.dart';
import 'package:a_dark_room_new/core/logger.dart';

/// AudioEngine 音频引擎测试
///
/// 测试覆盖范围：
/// 1. 音频引擎初始化
/// 2. 音频播放控制
/// 3. 音频池管理
/// 4. 音频预加载
/// 5. 音频状态管理
void main() {
  group('🎵 AudioEngine 音频引擎测试', () {
    late AudioEngine audioEngine;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Logger.info('🚀 开始 AudioEngine 测试套件');
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      audioEngine = AudioEngine();
      // 设置测试模式，禁用音频预加载和播放
      audioEngine.setTestMode(true);
    });

    tearDown(() {
      audioEngine.dispose();
    });

    group('🔧 音频引擎初始化测试', () {
      test('应该正确初始化音频引擎', () async {
        Logger.info('🧪 测试音频引擎初始化');

        // 执行初始化
        await audioEngine.init();

        // 验证初始化状态 - 在测试模式下，初始化应该成功
        final status = audioEngine.getAudioSystemStatus();
        expect(status['initialized'], isTrue);
        expect(status['audioEnabled'], isTrue);
        expect(status['masterVolume'], equals(1.0));
        expect(status['poolSizes'], isA<Map>());
        // 在测试模式下，预加载会被跳过
        expect(status['preloadCompleted'], isFalse);
        expect(status['preloadedCount'], equals(0));

        Logger.info('✅ 音频引擎初始化测试通过');
      });

      test('应该正确设置初始音频状态', () async {
        Logger.info('🧪 测试初始音频状态');

        await audioEngine.init();

        // 验证初始状态
        expect(audioEngine.isAudioEnabled(), isTrue);
        final status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(1.0));
        expect(audioEngine.isAudioContextRunning(), isTrue);

        Logger.info('✅ 初始音频状态测试通过');
      });

      test('应该正确处理重复初始化', () async {
        Logger.info('🧪 测试重复初始化处理');

        // 多次初始化
        await audioEngine.init();
        await audioEngine.init();
        await audioEngine.init();

        // 验证状态仍然正确
        expect(audioEngine.isAudioContextRunning(), isTrue);
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 重复初始化处理测试通过');
      });
    });

    group('🎮 音频播放控制测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确播放音效', () {
        Logger.info('🧪 测试音效播放');

        // 播放各种音效
        audioEngine.playSound(AudioLibrary.lightFire);
        audioEngine.playSound(AudioLibrary.stokeFire);
        audioEngine.playSound(AudioLibrary.gatherWood);
        audioEngine.playSound(AudioLibrary.build);

        // 验证不会崩溃（实际音频播放在测试环境中无法验证）
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音效播放测试通过');
      });

      test('应该正确播放背景音乐', () {
        Logger.info('🧪 测试背景音乐播放');

        // 播放背景音乐
        audioEngine.playBackgroundMusic(AudioLibrary.musicFireBurning);
        audioEngine.playBackgroundMusic(AudioLibrary.musicWorld);
        audioEngine.playBackgroundMusic(AudioLibrary.musicSpace);

        // 验证不会崩溃
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 背景音乐播放测试通过');
      });

      test('应该正确播放事件音频', () {
        Logger.info('🧪 测试事件音频播放');

        // 播放事件音频
        audioEngine.playEventMusic(AudioLibrary.eventNomad);
        audioEngine.playEventMusic(AudioLibrary.eventBeggar);

        // 验证不会崩溃
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 事件音频播放测试通过');
      });

      test('应该正确停止音频', () {
        Logger.info('🧪 测试音频停止');

        // 播放音频
        audioEngine.playBackgroundMusic(AudioLibrary.musicFireBurning);
        audioEngine.playEventMusic(AudioLibrary.eventNomad);

        // 停止音频
        audioEngine.stopBackgroundMusic();
        audioEngine.stopEventMusic();
        audioEngine.stopAllAudio();

        // 验证不会崩溃
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音频停止测试通过');
      });
    });

    group('🔊 音频控制测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确控制音频开关', () {
        Logger.info('🧪 测试音频开关控制');

        // 测试关闭音频
        audioEngine.setAudioEnabled(false);
        expect(audioEngine.isAudioEnabled(), isFalse);

        // 测试开启音频
        audioEngine.setAudioEnabled(true);
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音频开关控制测试通过');
      });

      test('应该正确控制音量', () async {
        Logger.info('🧪 测试音量控制');

        // 测试设置不同音量
        await audioEngine.setMasterVolume(0.5);
        var status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(0.5));

        await audioEngine.setMasterVolume(0.0);
        status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(0.0));

        await audioEngine.setMasterVolume(1.0);
        status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(1.0));

        Logger.info('✅ 音量控制测试通过');
      });

      test('应该正确处理音量边界值', () async {
        Logger.info('🧪 测试音量边界值处理');

        // 测试超出范围的音量值
        await audioEngine.setMasterVolume(-0.5); // 负值
        var status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(0.0));

        await audioEngine.setMasterVolume(1.5); // 超过1.0
        status = audioEngine.getAudioSystemStatus();
        expect(status['masterVolume'], equals(1.0));

        Logger.info('✅ 音量边界值处理测试通过');
      });

      test('应该正确处理音频启用状态', () {
        Logger.info('🧪 测试音频启用状态处理');

        // 测试禁用音频（相当于静音）
        audioEngine.setAudioEnabled(false);
        expect(audioEngine.isAudioEnabled(), isFalse);

        // 测试启用音频
        audioEngine.setAudioEnabled(true);
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音频启用状态处理测试通过');
      });
    });

    group('🎯 音频状态测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确获取音频系统状态', () {
        Logger.info('🧪 测试音频系统状态获取');

        // 获取状态
        final status = audioEngine.getAudioSystemStatus();

        // 验证状态结构
        expect(status.containsKey('initialized'), isTrue);
        expect(status.containsKey('audioEnabled'), isTrue);
        expect(status.containsKey('webAudioUnlocked'), isTrue);
        expect(status.containsKey('preloadCompleted'), isTrue);
        expect(status.containsKey('preloadedCount'), isTrue);
        expect(status.containsKey('cachedCount'), isTrue);
        expect(status.containsKey('poolSizes'), isTrue);
        expect(status.containsKey('masterVolume'), isTrue);
        expect(status.containsKey('hasBackgroundMusic'), isTrue);
        expect(status.containsKey('hasEventAudio'), isTrue);
        expect(status.containsKey('hasSoundEffect'), isTrue);

        Logger.info('✅ 音频系统状态获取测试通过');
      });

      test('应该正确检查音频上下文', () {
        Logger.info('🧪 测试音频上下文检查');

        // 检查音频上下文是否运行
        expect(audioEngine.isAudioContextRunning(), isTrue);

        Logger.info('✅ 音频上下文检查测试通过');
      });
    });

    group('🏊 音频池状态测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确获取音频池状态', () {
        Logger.info('🧪 测试音频池状态获取');

        // 获取音频池状态
        final status = audioEngine.getAudioSystemStatus();
        expect(status['poolSizes'], isA<Map>());

        Logger.info('✅ 音频池状态获取测试通过');
      });

      test('应该正确处理音频播放', () {
        Logger.info('🧪 测试音频播放处理');

        // 播放音效
        audioEngine.playSound(AudioLibrary.lightFire);
        audioEngine.playSound(AudioLibrary.stokeFire);

        // 验证系统不会崩溃
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音频播放处理测试通过');
      });
    });

    group('📊 音频状态监控测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确获取音频系统状态', () {
        Logger.info('🧪 测试音频系统状态获取');

        // 获取状态
        final status = audioEngine.getAudioSystemStatus();

        // 验证状态结构
        expect(status.containsKey('initialized'), isTrue);
        expect(status.containsKey('audioEnabled'), isTrue);
        expect(status.containsKey('webAudioUnlocked'), isTrue);
        expect(status.containsKey('preloadCompleted'), isTrue);
        expect(status.containsKey('preloadedCount'), isTrue);
        expect(status.containsKey('cachedCount'), isTrue);
        expect(status.containsKey('poolSizes'), isTrue);
        expect(status.containsKey('masterVolume'), isTrue);
        expect(status.containsKey('hasBackgroundMusic'), isTrue);
        expect(status.containsKey('hasEventAudio'), isTrue);
        expect(status.containsKey('hasSoundEffect'), isTrue);

        Logger.info('✅ 音频系统状态获取测试通过');
      });

      test('应该正确监控音频播放状态', () {
        Logger.info('🧪 测试音频播放状态监控');

        // 初始状态
        var status = audioEngine.getAudioSystemStatus();
        expect(status['hasBackgroundMusic'], isFalse);
        expect(status['hasEventAudio'], isFalse);

        // 在测试模式下，音频播放会被跳过，但不会报错
        // 播放背景音乐
        audioEngine.playBackgroundMusic(AudioLibrary.musicFireBurning);
        status = audioEngine.getAudioSystemStatus();
        // 在测试模式下，背景音乐不会真正播放
        expect(status['hasBackgroundMusic'], isFalse);

        // 播放事件音频
        audioEngine.playEventMusic(AudioLibrary.eventNomad);
        status = audioEngine.getAudioSystemStatus();
        // 在测试模式下，事件音频不会真正播放
        expect(status['hasEventAudio'], isFalse);

        Logger.info('✅ 音频播放状态监控测试通过');
      });
    });

    group('🔧 音频引擎工具方法测试', () {
      setUp(() async {
        await audioEngine.init();
      });

      test('应该正确检查音频状态', () {
        Logger.info('🧪 测试音频状态检查');

        // 检查音频上下文状态
        expect(audioEngine.isAudioContextRunning(), isA<bool>());
        expect(audioEngine.isAudioEnabled(), isA<bool>());

        // 获取系统状态
        final status = audioEngine.getAudioSystemStatus();
        expect(status, isA<Map<String, dynamic>>());

        Logger.info('✅ 音频状态检查测试通过');
      });

      test('应该正确处理音频错误', () {
        Logger.info('🧪 测试音频错误处理');

        // 尝试播放无效音频
        audioEngine.playSound('invalid_audio_file.mp3');

        // 验证系统不会崩溃
        expect(audioEngine.isAudioEnabled(), isTrue);

        Logger.info('✅ 音频错误处理测试通过');
      });

      test('应该正确停止音频播放', () {
        Logger.info('🧪 测试音频停止');

        // 播放一些音频
        audioEngine.playBackgroundMusic(AudioLibrary.musicFireBurning);
        audioEngine.playSound(AudioLibrary.lightFire);

        // 停止所有音频
        audioEngine.stopAllAudio();

        // 验证停止状态
        final status = audioEngine.getAudioSystemStatus();
        expect(status['hasBackgroundMusic'], isFalse);
        expect(status['hasEventAudio'], isFalse);

        Logger.info('✅ 音频停止测试通过');
      });
    });

    tearDownAll(() {
      Logger.info('🏁 AudioEngine 测试套件完成');
    });
  });
}
