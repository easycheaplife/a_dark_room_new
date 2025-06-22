import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 页面可见性管理器
/// 处理页面失去焦点时的定时器暂停和恢复问题
class VisibilityManager {
  static final VisibilityManager _instance = VisibilityManager._internal();
  factory VisibilityManager() => _instance;
  VisibilityManager._internal();

  bool _isVisible = true;
  bool get isVisible => _isVisible;

  final List<Timer> _managedTimers = [];
  final Map<Timer, _TimerInfo> _timerInfoMap = {};
  
  StreamSubscription<html.Event>? _visibilitySubscription;
  StreamSubscription<html.Event>? _focusSubscription;
  StreamSubscription<html.Event>? _blurSubscription;

  /// 初始化可见性管理器
  void init() {
    Logger.info('🔧 VisibilityManager init() called, kIsWeb: $kIsWeb');

    if (!kIsWeb) {
      Logger.info('⚠️ VisibilityManager skipped - not web platform');
      return; // 只在Web平台启用
    }

    try {
      Logger.info('🔧 Setting up visibility listeners...');

      // 监听页面可见性变化
      _visibilitySubscription = html.document.onVisibilityChange.listen(_handleVisibilityChange);
      Logger.info('✅ Visibility change listener set up');

      // 监听窗口焦点变化
      _focusSubscription = html.window.onFocus.listen(_handleFocus);
      _blurSubscription = html.window.onBlur.listen(_handleBlur);
      Logger.info('✅ Focus/blur listeners set up');

      Logger.info('👁️ VisibilityManager initialized');
    } catch (e) {
      Logger.error('❌ VisibilityManager initialization failed: $e');
    }
  }

  /// 处理可见性变化
  void _handleVisibilityChange(html.Event event) {
    final isHidden = html.document.hidden ?? false;
    _updateVisibility(!isHidden);
  }

  /// 处理窗口获得焦点
  void _handleFocus(html.Event event) {
    _updateVisibility(true);
  }

  /// 处理窗口失去焦点
  void _handleBlur(html.Event event) {
    _updateVisibility(false);
  }

  /// 更新可见性状态
  void _updateVisibility(bool visible) {
    if (_isVisible == visible) return;

    _isVisible = visible;
    Logger.info('👁️ Page visibility changed: ${visible ? 'visible' : 'hidden'}');

    if (visible) {
      _resumeTimers();
    } else {
      _pauseTimers();
    }
  }

  /// 暂停所有管理的定时器
  void _pauseTimers() {
    Logger.info('⏸️ Pausing ${_managedTimers.length} managed timers');
    
    for (final timer in _managedTimers) {
      final info = _timerInfoMap[timer];
      if (info != null && timer.isActive) {
        info.pausedAt = DateTime.now();
        timer.cancel();
        Logger.info('⏸️ Paused timer: ${info.description}');
      }
    }
  }

  /// 恢复所有管理的定时器
  void _resumeTimers() {
    Logger.info('▶️ Resuming ${_managedTimers.length} managed timers');
    
    final timersToRestart = <_TimerInfo>[];
    
    for (final timer in List.from(_managedTimers)) {
      final info = _timerInfoMap[timer];
      if (info != null && info.pausedAt != null) {
        timersToRestart.add(info);
        _removeTimer(timer);
      }
    }

    for (final info in timersToRestart) {
      if (info.isPeriodic) {
        _createPeriodicTimer(info.duration, info.callback, info.description);
      } else {
        // 对于一次性定时器，计算剩余时间
        final elapsed = DateTime.now().difference(info.pausedAt!);
        final remaining = info.duration - elapsed;
        
        if (remaining.inMilliseconds > 0) {
          _createTimer(remaining, info.callback, info.description);
        } else {
          // 如果时间已过，立即执行
          info.callback();
        }
      }
      Logger.info('▶️ Resumed timer: ${info.description}');
    }
  }

  /// 创建受管理的定时器
  Timer createTimer(Duration duration, VoidCallback callback, [String? description]) {
    return _createTimer(duration, callback, description ?? 'unnamed timer');
  }

  /// 创建受管理的周期性定时器
  Timer createPeriodicTimer(Duration duration, VoidCallback callback, [String? description]) {
    return _createPeriodicTimer(duration, callback, description ?? 'unnamed periodic timer');
  }

  /// 内部创建定时器
  Timer _createTimer(Duration duration, VoidCallback callback, String description) {
    final timer = Timer(duration, callback);
    _addTimer(timer, duration, callback, description, false);
    return timer;
  }

  /// 内部创建周期性定时器
  Timer _createPeriodicTimer(Duration duration, VoidCallback callback, String description) {
    final timer = Timer.periodic(duration, (_) => callback());
    _addTimer(timer, duration, callback, description, true);
    return timer;
  }

  /// 添加定时器到管理列表
  void _addTimer(Timer timer, Duration duration, VoidCallback callback, String description, bool isPeriodic) {
    _managedTimers.add(timer);
    _timerInfoMap[timer] = _TimerInfo(
      duration: duration,
      callback: callback,
      description: description,
      isPeriodic: isPeriodic,
    );
    
    Logger.info('➕ Added managed timer: $description (${isPeriodic ? 'periodic' : 'one-time'})');
  }

  /// 移除定时器
  void _removeTimer(Timer timer) {
    _managedTimers.remove(timer);
    _timerInfoMap.remove(timer);
  }

  /// 取消定时器
  void cancelTimer(Timer timer) {
    timer.cancel();
    _removeTimer(timer);
    Logger.info('❌ Cancelled managed timer');
  }

  /// 清理所有定时器
  void dispose() {
    Logger.info('🧹 Disposing VisibilityManager');
    
    for (final timer in _managedTimers) {
      timer.cancel();
    }
    _managedTimers.clear();
    _timerInfoMap.clear();

    _visibilitySubscription?.cancel();
    _focusSubscription?.cancel();
    _blurSubscription?.cancel();
  }
}

/// 定时器信息
class _TimerInfo {
  final Duration duration;
  final VoidCallback callback;
  final String description;
  final bool isPeriodic;
  DateTime? pausedAt;

  _TimerInfo({
    required this.duration,
    required this.callback,
    required this.description,
    required this.isPeriodic,
  });
}
