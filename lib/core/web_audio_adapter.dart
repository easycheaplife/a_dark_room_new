import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_engine.dart';
import 'logger.dart';

/// Web音频适配器
/// 专门处理Web平台的音频解锁和用户交互问题
class WebAudioAdapter {
  static bool _userInteracted = false;
  static bool _audioUnlocked = false;

  /// 处理用户交互，解锁音频
  static Future<void> handleUserInteraction() async {
    if (!kIsWeb || _userInteracted) return;

    try {
      await AudioEngine().unlockWebAudio();
      _userInteracted = true;
      _audioUnlocked = true;
      
      if (kDebugMode) {
        print('👆 User interaction detected, audio unlocked');
      }
      Logger.info('👆 User interaction detected, audio unlocked');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling user interaction: $e');
      }
      Logger.error('❌ Error handling user interaction: $e');
    }
  }

  /// 检查音频是否已解锁
  static bool get isAudioUnlocked => _audioUnlocked;

  /// 检查用户是否已交互
  static bool get hasUserInteracted => _userInteracted;

  /// 重置状态（用于测试）
  static void reset() {
    _userInteracted = false;
    _audioUnlocked = false;
  }

  /// 初始化Web音频适配器
  static Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      Logger.info('🎵 Initializing WebAudioAdapter');
      
      // 在Web平台，音频需要用户交互才能播放
      // 这里只是初始化，实际解锁在用户交互时进行
      
      if (kDebugMode) {
        print('🎵 WebAudioAdapter initialized');
      }
      Logger.info('🎵 WebAudioAdapter initialized');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing WebAudioAdapter: $e');
      }
      Logger.error('❌ Error initializing WebAudioAdapter: $e');
    }
  }
}
