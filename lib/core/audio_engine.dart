import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

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

  // Web音频解锁状态
  bool _webAudioUnlocked = false;

  /// 初始化音频引擎
  Future<void> init() async {
    try {
      _initialized = true;
      if (kDebugMode) {
        print('🎵 AudioEngine initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing audio engine: $e');
      }
      _initialized = false;
    }
  }

  /// 解锁Web音频（需要用户交互触发）
  Future<void> unlockWebAudio() async {
    if (!kIsWeb || _webAudioUnlocked) return;

    try {
      // 创建并播放一个静音音频来解锁音频上下文
      final unlockPlayer = AudioPlayer();
      await unlockPlayer.setVolume(0.0);

      // 尝试播放一个短暂的静音音频
      await unlockPlayer.setAsset('assets/audio/light-fire.flac');
      await unlockPlayer.play();
      await unlockPlayer.stop();
      await unlockPlayer.dispose();

      _webAudioUnlocked = true;
      if (kDebugMode) {
        print('🔓 Web audio unlocked');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to unlock web audio: $e');
      }
      // 即使失败也标记为已尝试解锁，避免重复尝试
      _webAudioUnlocked = true;
    }
  }

  /// 加载音频文件
  Future<AudioPlayer> loadAudioFile(String src) async {
    if (_audioBufferCache.containsKey(src)) {
      if (kDebugMode) {
        print('🎵 Using cached audio file: $src');
      }
      return _audioBufferCache[src]!;
    }

    try {
      final player = AudioPlayer();

      if (kDebugMode) {
        print('🎵 Loading audio file: assets/$src');
      }

      await player.setAsset('assets/$src');
      _audioBufferCache[src] = player;

      if (kDebugMode) {
        print('🎵 Successfully loaded audio file: $src');
      }

      return player;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading audio file $src: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }

      // 在Web平台，可能需要特殊处理
      if (kIsWeb) {
        if (kDebugMode) {
          print('🌐 Web platform detected, creating empty player for: $src');
        }
      }

      // 返回一个空的播放器作为占位符
      final player = AudioPlayer();
      _audioBufferCache[src] = player;
      return player;
    }
  }

  /// 播放音效
  Future<void> playSound(String src) async {
    if (!_initialized) {
      if (kDebugMode) {
        print('❌ AudioEngine not initialized, cannot play sound: $src');
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

      // 播放完成后清理引用
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentSoundEffectAudio == player) {
            _currentSoundEffectAudio = null;
          }
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
    if (!_initialized) return;

    // Web平台需要先解锁音频
    if (kIsWeb && !_webAudioUnlocked) {
      await unlockWebAudio();
    }

    try {
      final player = await loadAudioFile(src);

      // 淡出当前背景音乐
      if (_currentBackgroundMusic != null && _currentBackgroundMusic!.playing) {
        await _fadeOutAndStop(_currentBackgroundMusic!);
      }

      // 设置新的背景音乐
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0.0);
      await player.seek(Duration.zero);
      await player.play();

      // 淡入新音乐
      await _fadeIn(player, _masterVolume);

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
