import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'audio_engine.dart';
import 'logger.dart';

/// Web音频适配器
/// 专门处理Web平台的音频解锁和用户交互问题，特别针对远程部署环境优化
class WebAudioAdapter {
  static bool _userInteracted = false;
  static bool _audioUnlocked = false;
  static bool _remoteDeploymentMode = false;
  static Timer? _retryTimer;

  /// 检测是否为远程部署环境
  static bool get isRemoteDeployment {
    if (!kIsWeb) return false;

    // 检查当前URL是否为远程部署
    try {
      final currentUrl = Uri.base.toString();
      _remoteDeploymentMode = !currentUrl.contains('localhost') &&
          !currentUrl.contains('127.0.0.1') &&
          !currentUrl.contains('file://');

      if (kDebugMode) {
        print(
            '🌐 Remote deployment mode: $_remoteDeploymentMode (URL: $currentUrl)');
      }

      return _remoteDeploymentMode;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error detecting deployment mode: $e');
      }
      return false;
    }
  }

  /// 处理用户交互，解锁音频
  static Future<void> handleUserInteraction() async {
    if (!kIsWeb || _userInteracted) return;

    try {
      if (kDebugMode) {
        print('👆 User interaction detected, attempting audio unlock...');
      }

      // 在远程部署环境下，使用更积极的解锁策略
      if (isRemoteDeployment) {
        await _handleRemoteDeploymentUnlock();
      } else {
        await AudioEngine().unlockWebAudio();
      }

      _userInteracted = true;
      _audioUnlocked = true;

      if (kDebugMode) {
        print('👆 User interaction processed, audio unlocked');
      }
      Logger.info('👆 User interaction processed, audio unlocked');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling user interaction: $e');
      }
      Logger.error('❌ Error handling user interaction: $e');

      // 在远程部署环境下，设置重试机制
      if (isRemoteDeployment && _retryTimer == null) {
        _scheduleRetry();
      }
    }
  }

  /// 处理远程部署环境的音频解锁
  static Future<void> _handleRemoteDeploymentUnlock() async {
    if (kDebugMode) {
      print('🌐 Handling remote deployment audio unlock...');
    }

    // 多重解锁策略
    final futures = <Future>[];

    // 策略1: 标准解锁
    futures.add(AudioEngine().unlockWebAudio());

    // 策略2: 延迟解锁
    futures.add(Future.delayed(const Duration(milliseconds: 500), () async {
      await AudioEngine().unlockWebAudio();
    }));

    // 策略3: 多次尝试解锁
    futures.add(Future.delayed(const Duration(milliseconds: 1000), () async {
      for (int i = 0; i < 3; i++) {
        try {
          await AudioEngine().unlockWebAudio();
          break;
        } catch (e) {
          if (kDebugMode) {
            print('🔄 Retry attempt ${i + 1} failed: $e');
          }
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
          }
        }
      }
    }));

    // 等待任意一个策略成功
    try {
      await Future.any(futures);
      if (kDebugMode) {
        print('🌐 Remote deployment audio unlock successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ All remote deployment unlock strategies failed: $e');
      }
      rethrow;
    }
  }

  /// 安排重试解锁
  static void _scheduleRetry() {
    _retryTimer = Timer(const Duration(seconds: 2), () async {
      if (!_audioUnlocked) {
        if (kDebugMode) {
          print('🔄 Retrying audio unlock...');
        }
        try {
          await handleUserInteraction();
        } catch (e) {
          if (kDebugMode) {
            print('❌ Retry failed: $e');
          }
        }
      }
      _retryTimer = null;
    });
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
