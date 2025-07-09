import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'audio_library.dart';
import 'logger.dart';

/// AudioEngine handles all sound effects and music in the game
/// 完整移植自原游戏的音频引擎
class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();

  factory AudioEngine() {
    return _instance;
  }

  AudioEngine._internal();

  // 音频设置
  static const double fadeTime = 1.0; // 淡入淡出时间（秒）

  // 音频播放器
  final Map<String, AudioPlayer> _audioBufferCache = {};
  AudioPlayer? _currentBackgroundMusic;
  AudioPlayer? _currentEventAudio;
  AudioPlayer? _currentSoundEffectAudio;

  // 音量设置
  double _masterVolume = 1.0;
  bool _initialized = false;
  bool _audioEnabled = true;

  // Web音频解锁状态
  bool _webAudioUnlocked = false;

  // 音频预加载状态
  bool _preloadCompleted = false;
  final Set<String> _preloadedAudio = {};

  // 音频池管理 - 参考原游戏的音频缓存机制
  static const int maxCachedPlayers = 20;
  final Map<String, List<AudioPlayer>> _audioPool = {};

  // 测试模式标志 - 在测试环境中禁用预加载
  bool _testMode = false;

  /// 设置测试模式（禁用预加载）
  void setTestMode(bool testMode) {
    _testMode = testMode;
  }

  /// 初始化音频引擎
  Future<void> init() async {
    try {
      _initialized = true;
      if (kDebugMode) {
        Logger.info('🎵 AudioEngine initialized');
      }

      // 开始预加载音频 - 参考原游戏Engine.init()
      // 在测试模式下跳过预加载
      if (!_testMode) {
        _startPreloading();
      } else if (kDebugMode) {
        Logger.info('🧪 Test mode: skipping audio preloading');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing audio engine: $e');
      }
      _initialized = false;
    }
  }

  /// 开始预加载音频 - 参考原游戏的预加载逻辑
  void _startPreloading() {
    if (!_initialized) return;

    // 异步预加载，不阻塞初始化
    Future.microtask(() async {
      try {
        if (kDebugMode) {
          print('🎵 Starting audio preloading...');
        }

        // 预加载音乐文件
        for (final audioPath in AudioLibrary.PRELOAD_MUSIC) {
          await _preloadAudioFile(audioPath);
        }

        // 预加载事件音频
        for (final audioPath in AudioLibrary.PRELOAD_EVENTS) {
          await _preloadAudioFile(audioPath);
        }

        // 预加载常用音效
        for (final audioPath in AudioLibrary.PRELOAD_SOUNDS) {
          await _preloadAudioFile(audioPath);
        }

        _preloadCompleted = true;
        if (kDebugMode) {
          print(
              '🎵 Audio preloading completed. Loaded ${_preloadedAudio.length} files.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Audio preloading error: $e');
        }
      }
    });
  }

  /// 预加载单个音频文件
  Future<void> _preloadAudioFile(String src) async {
    if (_preloadedAudio.contains(src)) return;

    try {
      // 创建音频播放器但不播放
      final player = AudioPlayer();
      await player.setAsset('assets/$src');

      // 添加到缓存
      _audioBufferCache[src] = player;
      _preloadedAudio.add(src);

      if (kDebugMode) {
        print('🎵 Preloaded: $src');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to preload $src: $e');
      }
    }
  }

  /// 解锁Web音频（需要用户交互触发）
  Future<void> unlockWebAudio() async {
    if (!kIsWeb || _webAudioUnlocked) return;

    try {
      if (kDebugMode) {
        print('🔓 Attempting to unlock web audio...');
      }

      // 方法1: 尝试调用JavaScript音频解锁函数
      try {
        // 调用web/audio_config.js中的解锁函数
        if (kIsWeb) {
          // 这里可以通过dart:js调用JavaScript函数
          // 但为了简化，我们直接使用just_audio的方式
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ JavaScript audio unlock failed: $e');
        }
      }

      // 方法2: 创建并播放一个静音音频来解锁音频上下文
      final unlockPlayer = AudioPlayer();
      await unlockPlayer.setVolume(0.0);

      // 尝试播放一个短暂的静音音频
      await unlockPlayer.setAsset('assets/audio/light-fire.flac');
      await unlockPlayer.play();

      // 等待一小段时间确保音频开始播放
      await Future.delayed(const Duration(milliseconds: 100));

      await unlockPlayer.stop();
      await unlockPlayer.dispose();

      _webAudioUnlocked = true;
      if (kDebugMode) {
        print('🔓 Web audio unlocked successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to unlock web audio: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }

      // 尝试备用解锁方法
      try {
        final backupPlayer = AudioPlayer();
        await backupPlayer.setVolume(0.01); // 极低音量
        await backupPlayer.setAsset('assets/audio/light-fire.flac');
        await backupPlayer.play();
        await Future.delayed(const Duration(milliseconds: 50));
        await backupPlayer.stop();
        await backupPlayer.dispose();

        _webAudioUnlocked = true;
        if (kDebugMode) {
          print('🔓 Web audio unlocked via backup method');
        }
      } catch (backupError) {
        if (kDebugMode) {
          print('❌ Backup unlock method also failed: $backupError');
        }
        // 即使失败也标记为已尝试解锁，避免重复尝试
        _webAudioUnlocked = true;
      }
    }
  }

  /// 加载音频文件 - 优化版本，支持音频池
  Future<AudioPlayer> loadAudioFile(String src) async {
    // 检查预加载缓存
    if (_audioBufferCache.containsKey(src)) {
      if (kDebugMode) {
        print('🎵 Using cached audio file: $src');
      }
      return _audioBufferCache[src]!;
    }

    // 检查音频池
    if (_audioPool.containsKey(src) && _audioPool[src]!.isNotEmpty) {
      final player = _audioPool[src]!.removeAt(0);
      if (kDebugMode) {
        print(
            '🎵 Reused from pool: $src (remaining: ${_audioPool[src]!.length})');
      }
      return player;
    }

    try {
      final player = AudioPlayer();

      if (kDebugMode) {
        print('🎵 Loading audio file: assets/$src');
      }

      // 在Web平台，添加额外的加载策略
      if (kIsWeb) {
        // 设置更长的超时时间，适应远程部署环境
        await player.setAsset('assets/$src').timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
                'Audio loading timeout', const Duration(seconds: 10));
          },
        );
      } else {
        await player.setAsset('assets/$src');
      }

      // 如果不是预加载的文件，添加到缓存
      if (!_preloadedAudio.contains(src)) {
        _audioBufferCache[src] = player;
      }

      if (kDebugMode) {
        print('🎵 Successfully loaded audio file: $src');
      }

      return player;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading audio file $src: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }

      // 在Web平台，尝试重新加载
      if (kIsWeb) {
        if (kDebugMode) {
          print('🌐 Web platform detected, attempting retry for: $src');
        }

        try {
          // 重试一次，使用更短的超时时间
          final retryPlayer = AudioPlayer();
          await retryPlayer.setAsset('assets/$src').timeout(
                const Duration(seconds: 5),
              );
          _audioBufferCache[src] = retryPlayer;

          if (kDebugMode) {
            print('🎵 Successfully loaded audio file on retry: $src');
          }

          return retryPlayer;
        } catch (retryError) {
          if (kDebugMode) {
            print('❌ Retry also failed for $src: $retryError');
          }
        }
      }

      // 返回一个空的播放器作为占位符
      final player = AudioPlayer();
      _audioBufferCache[src] = player;
      return player;
    }
  }

  /// 回收音频播放器到池中
  void _recycleAudioPlayer(String src, AudioPlayer player) {
    if (!_audioPool.containsKey(src)) {
      _audioPool[src] = [];
    }

    // 限制池大小
    if (_audioPool[src]!.length < maxCachedPlayers) {
      // 重置播放器状态
      player.stop().catchError((e) {
        if (kDebugMode) {
          print('⚠️ Error stopping player for recycling: $e');
        }
      });
      player.seek(Duration.zero).catchError((e) {
        if (kDebugMode) {
          print('⚠️ Error seeking player for recycling: $e');
        }
      });

      _audioPool[src]!.add(player);

      if (kDebugMode) {
        print(
            '♻️ Recycled player for: $src (pool size: ${_audioPool[src]!.length})');
      }
    } else {
      // 池已满，释放播放器
      player.dispose().catchError((e) {
        if (kDebugMode) {
          print('⚠️ Error disposing excess player: $e');
        }
      });
    }
  }

  /// 播放音效
  Future<void> playSound(String src) async {
    // 在测试模式下跳过音频播放
    if (_testMode) {
      if (kDebugMode) {
        print('🧪 Test mode: skipping audio playback for $src');
      }
      return;
    }

    if (!_initialized || !_audioEnabled) {
      if (kDebugMode) {
        print(
            '❌ AudioEngine not initialized or disabled, cannot play sound: $src');
      }
      return;
    }

    if (kDebugMode) {
      print('🔊 Attempting to play sound: $src');
    }

    // Web平台需要先解锁音频
    if (kIsWeb && !_webAudioUnlocked) {
      if (kDebugMode) {
        print('🔓 Web audio not unlocked, attempting to unlock...');
      }
      await unlockWebAudio();
    }

    try {
      // 如果当前正在播放相同的音效，不重复播放
      if (_currentSoundEffectAudio != null) {
        final currentSource = _currentSoundEffectAudio!.audioSource;
        if (currentSource is UriAudioSource &&
            currentSource.uri.toString().contains(src)) {
          return;
        }
      }

      final player = await loadAudioFile(src);
      await player.setVolume(_masterVolume);
      await player.seek(Duration.zero);
      await player.play();

      _currentSoundEffectAudio = player;

      // 播放完成后清理引用并回收到池中
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentSoundEffectAudio == player) {
            _currentSoundEffectAudio = null;
          }
          // 回收播放器到池中以便重用
          _recycleAudioPlayer(src, player);
        }
      });

      if (kDebugMode) {
        print('🔊 Playing sound: $src');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing sound $src: $e');
      }
    }
  }

  /// 播放背景音乐
  Future<void> playBackgroundMusic(String src) async {
    // 在测试模式下跳过音频播放
    if (_testMode) {
      if (kDebugMode) {
        print('🧪 Test mode: skipping background music playback for $src');
      }
      return;
    }

    if (!_initialized || !_audioEnabled) return;

    // Web平台需要先解锁音频
    if (kIsWeb && !_webAudioUnlocked) {
      await unlockWebAudio();
    }

    try {
      // 立即停止当前背景音乐
      if (_currentBackgroundMusic != null) {
        if (kDebugMode) {
          print(
              '🎵 Stopping current background music before playing new one...');
        }
        await _currentBackgroundMusic!.stop();
        _currentBackgroundMusic = null;
      }

      // 为背景音乐创建新的播放器实例，不使用缓存
      final player = AudioPlayer();

      if (kIsWeb) {
        await player.setUrl(
          'assets/$src',
          preload: true,
        );
      } else {
        await player.setAsset('assets/$src');
      }

      // 设置新的背景音乐
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(_masterVolume);
      await player.seek(Duration.zero);
      await player.play();

      _currentBackgroundMusic = player;

      if (kDebugMode) {
        print('🎵 Playing background music: $src');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing background music $src: $e');
      }
    }
  }

  /// 播放事件音乐
  Future<void> playEventMusic(String src) async {
    // 在测试模式下跳过音频播放
    if (_testMode) {
      if (kDebugMode) {
        print('🧪 Test mode: skipping event music playback for $src');
      }
      return;
    }

    if (!_initialized) return;

    // Web平台需要先解锁音频
    if (kIsWeb && !_webAudioUnlocked) {
      await unlockWebAudio();
    }

    try {
      final player = await loadAudioFile(src);

      // 降低背景音乐音量
      if (_currentBackgroundMusic != null) {
        await _fadeTo(_currentBackgroundMusic!, _masterVolume * 0.2);
      }

      // 播放事件音乐
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0.0);
      await player.seek(Duration.zero);
      await player.play();

      // 淡入事件音乐
      await _fadeIn(player, _masterVolume);

      _currentEventAudio = player;

      if (kDebugMode) {
        print('🎭 Playing event music: $src');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing event music $src: $e');
      }
    }
  }

  /// 停止事件音乐
  Future<void> stopEventMusic() async {
    if (!_initialized) return;

    try {
      // 淡出并停止事件音乐
      if (_currentEventAudio != null) {
        await _fadeOutAndStop(_currentEventAudio!);
        _currentEventAudio = null;
      }

      // 恢复背景音乐音量
      if (_currentBackgroundMusic != null) {
        await _fadeTo(_currentBackgroundMusic!, _masterVolume);
      }

      if (kDebugMode) {
        print('🎭 Stopped event music');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping event music: $e');
      }
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    if (!_initialized) return;

    try {
      // 立即停止背景音乐，不使用淡出效果
      if (_currentBackgroundMusic != null) {
        if (kDebugMode) {
          print('🎵 Stopping background music immediately...');
        }

        // 立即停止播放器
        await _currentBackgroundMusic!.stop();
        await _currentBackgroundMusic!.dispose();
        _currentBackgroundMusic = null;

        if (kDebugMode) {
          print('🎵 Background music stopped and disposed successfully');
        }
      }

      // 额外安全措施：停止并销毁所有可能播放太空音乐的缓存播放器
      final spaceAudioFiles = [
        'audio/space.flac',
        AudioLibrary.musicSpace,
      ];

      for (final audioFile in spaceAudioFiles) {
        if (_audioBufferCache.containsKey(audioFile)) {
          try {
            await _audioBufferCache[audioFile]!.stop();
            await _audioBufferCache[audioFile]!.dispose();
            _audioBufferCache.remove(audioFile);
            if (kDebugMode) {
              print('🔇 Stopped and removed cached space audio: $audioFile');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error stopping cached space audio $audioFile: $e');
            }
          }
        }
      }

      if (kDebugMode) {
        print('🎵 Stopped background music completely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping background music: $e');
      }
    }
  }

  /// 停止所有音频
  Future<void> stopAllAudio() async {
    if (!_initialized) return;

    try {
      if (kDebugMode) {
        print('🔇 Stopping all audio...');
      }

      // 停止背景音乐 - 使用更安全的方式
      if (_currentBackgroundMusic != null) {
        try {
          await _currentBackgroundMusic!.stop();
          await _currentBackgroundMusic!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping background music: $e');
          }
        }
        _currentBackgroundMusic = null;
      }

      // 停止事件音乐
      if (_currentEventAudio != null) {
        try {
          await _currentEventAudio!.stop();
          await _currentEventAudio!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping event audio: $e');
          }
        }
        _currentEventAudio = null;
      }

      // 停止音效
      if (_currentSoundEffectAudio != null) {
        try {
          await _currentSoundEffectAudio!.stop();
          await _currentSoundEffectAudio!.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping sound effect: $e');
          }
        }
        _currentSoundEffectAudio = null;
      }

      // 停止并销毁所有缓存的播放器
      if (kDebugMode) {
        print('🔇 Stopping and disposing all cached audio players...');
      }
      final cacheKeys = _audioBufferCache.keys.toList();
      for (final key in cacheKeys) {
        try {
          final player = _audioBufferCache[key];
          if (player != null) {
            await player.stop();
            await player.dispose();
            _audioBufferCache.remove(key);
            if (kDebugMode) {
              print('🔇 Stopped and disposed cached player: $key');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error stopping cached player $key: $e');
          }
        }
      }

      // 清空缓存
      _audioBufferCache.clear();

      if (kDebugMode) {
        print('🔇 All audio stopped and cache cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in stopAllAudio: $e');
      }
    }
  }

  /// 设置音频启用状态
  void setAudioEnabled(bool enabled) {
    _audioEnabled = enabled;
    if (!enabled) {
      // 使用同步方式立即停止音频
      stopAllAudioSync();
    }
    if (kDebugMode) {
      print('🔊 Audio enabled: $enabled');
    }
  }

  /// 同步停止所有音频（用于紧急情况）
  void stopAllAudioSync() {
    if (!_initialized) return;

    try {
      if (kDebugMode) {
        print('🔇 Stopping all audio synchronously...');
      }

      // 同步停止所有播放器
      _currentBackgroundMusic?.stop();
      _currentBackgroundMusic = null;

      _currentEventAudio?.stop();
      _currentEventAudio = null;

      _currentSoundEffectAudio?.stop();
      _currentSoundEffectAudio = null;

      if (kDebugMode) {
        print('🔇 All audio stopped synchronously');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in stopAllAudioSync: $e');
      }
    }
  }

  /// 检查音频是否启用
  bool isAudioEnabled() {
    return _audioEnabled;
  }

  /// 设置主音量
  Future<void> setMasterVolume(double volume, [int fadeTimeMs = 500]) async {
    _masterVolume = volume.clamp(0.0, 1.0);

    // 更新所有当前播放的音频音量
    if (_currentBackgroundMusic != null) {
      await _fadeTo(_currentBackgroundMusic!, _masterVolume,
          Duration(milliseconds: fadeTimeMs));
    }

    if (_currentEventAudio != null) {
      await _fadeTo(_currentEventAudio!, _masterVolume,
          Duration(milliseconds: fadeTimeMs));
    }

    if (_currentSoundEffectAudio != null) {
      await _currentSoundEffectAudio!.setVolume(_masterVolume);
    }

    if (kDebugMode) {
      print('🔊 Set master volume to: $_masterVolume');
    }
  }

  /// 检查音频上下文是否运行
  bool isAudioContextRunning() {
    return _initialized;
  }

  /// 获取音频系统状态信息
  Map<String, dynamic> getAudioSystemStatus() {
    final poolSizes = <String, int>{};
    for (final entry in _audioPool.entries) {
      poolSizes[entry.key] = entry.value.length;
    }

    return {
      'initialized': _initialized,
      'audioEnabled': _audioEnabled,
      'webAudioUnlocked': _webAudioUnlocked,
      'preloadCompleted': _preloadCompleted,
      'preloadedCount': _preloadedAudio.length,
      'cachedCount': _audioBufferCache.length,
      'poolSizes': poolSizes,
      'masterVolume': _masterVolume,
      'hasBackgroundMusic': _currentBackgroundMusic != null,
      'hasEventAudio': _currentEventAudio != null,
      'hasSoundEffect': _currentSoundEffectAudio != null,
    };
  }

  /// 清理音频缓存和池（用于内存管理）
  Future<void> cleanupAudioCache() async {
    if (kDebugMode) {
      print('🧹 Cleaning up audio cache and pools...');
    }

    // 清理音频池
    for (final entry in _audioPool.entries) {
      for (final player in entry.value) {
        try {
          await player.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing pooled player: $e');
          }
        }
      }
    }
    _audioPool.clear();

    // 清理非预加载的缓存
    final toRemove = <String>[];
    for (final entry in _audioBufferCache.entries) {
      if (!_preloadedAudio.contains(entry.key)) {
        toRemove.add(entry.key);
        try {
          await entry.value.dispose();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error disposing cached player: $e');
          }
        }
      }
    }

    for (final key in toRemove) {
      _audioBufferCache.remove(key);
    }

    if (kDebugMode) {
      print(
          '🧹 Audio cleanup completed. Removed ${toRemove.length} cached players.');
    }
  }

  /// 尝试恢复音频上下文
  Future<void> tryResumingAudioContext() async {
    if (!_initialized) {
      await init();
    }
    if (kDebugMode) {
      print('🎵 Audio context resumed');
    }
  }

  /// 淡入音频
  Future<void> _fadeIn(AudioPlayer player, double targetVolume,
      [Duration? duration]) async {
    duration ??= Duration(milliseconds: (fadeTime * 1000).round());

    const steps = 20;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = targetVolume / steps;

    for (int i = 0; i <= steps; i++) {
      await player.setVolume(volumeStep * i);
      await Future.delayed(stepDuration);
    }
  }

  /// 淡出到指定音量
  Future<void> _fadeTo(AudioPlayer player, double targetVolume,
      [Duration? duration]) async {
    duration ??= Duration(milliseconds: (fadeTime * 1000).round());

    final currentVolume = player.volume;
    const steps = 20;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = (targetVolume - currentVolume) / steps;

    for (int i = 0; i <= steps; i++) {
      await player.setVolume(currentVolume + (volumeStep * i));
      await Future.delayed(stepDuration);
    }
  }

  /// 淡出并停止音频
  Future<void> _fadeOutAndStop(AudioPlayer player, [Duration? duration]) async {
    duration ??= Duration(milliseconds: (fadeTime * 1000).round());

    final currentVolume = player.volume;
    const steps = 20;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = currentVolume / steps;

    for (int i = 0; i <= steps; i++) {
      await player.setVolume(currentVolume - (volumeStep * i));
      await Future.delayed(stepDuration);
    }

    await player.stop();
  }

  /// 释放所有音频资源
  Future<void> dispose() async {
    try {
      // 停止所有播放器
      await _currentBackgroundMusic?.stop();
      await _currentEventAudio?.stop();
      await _currentSoundEffectAudio?.stop();

      // 释放所有缓存的播放器
      for (final player in _audioBufferCache.values) {
        await player.dispose();
      }

      _audioBufferCache.clear();
      _currentBackgroundMusic = null;
      _currentEventAudio = null;
      _currentSoundEffectAudio = null;
      _initialized = false;

      if (kDebugMode) {
        print('🎵 AudioEngine disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing audio engine: $e');
      }
    }
  }
}
