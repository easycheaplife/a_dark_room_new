import 'dart:async';
import 'package:flutter/foundation.dart';
import 'visibility_manager.dart';
import 'logger.dart';

/// 全局进度管理器，用于管理所有进度按钮的状态
/// 使用ChangeNotifier来强制UI更新，绕过Flutter的渲染限制
class ProgressManager extends ChangeNotifier {
  static final ProgressManager _instance = ProgressManager._internal();
  factory ProgressManager() => _instance;
  ProgressManager._internal();

  // 存储所有活动的进度
  final Map<String, ProgressState> _activeProgresses = {};
  Timer? _globalUpdateTimer;

  /// 获取指定ID的进度状态
  ProgressState? getProgress(String id) => _activeProgresses[id];

  /// 检查是否有进度正在进行
  bool get hasActiveProgress => _activeProgresses.isNotEmpty;

  /// 开始一个新的进度
  void startProgress({
    required String id,
    required int duration,
    required VoidCallback onComplete,
  }) {
    Logger.info(
        '🚀 ProgressManager: Starting progress $id, duration: ${duration}ms');

    // 取消之前的进度（如果存在）
    if (_activeProgresses.containsKey(id)) {
      _cancelProgress(id);
    }

    // 创建新的进度状态
    final progressState = ProgressState(
      id: id,
      duration: duration,
      startTime: DateTime.now(),
      onComplete: onComplete,
    );

    _activeProgresses[id] = progressState;

    // 启动全局更新定时器（如果还没有启动）
    _ensureGlobalTimer();

    // 通知UI更新
    notifyListeners();
  }

  /// 取消指定的进度
  void cancelProgress(String id) {
    Logger.info('❌ ProgressManager: Cancelling progress $id');
    _cancelProgress(id);
  }

  void _cancelProgress(String id) {
    _activeProgresses.remove(id);

    // 如果没有活动进度了，停止全局定时器
    if (_activeProgresses.isEmpty) {
      _stopGlobalTimer();
    }

    // 通知UI更新（但要避免在dispose时调用）
    try {
      notifyListeners();
    } catch (e) {
      // 忽略在dispose时的错误
      Logger.info(
          '⚠️ ProgressManager: Ignored notifyListeners error during dispose: $e');
    }
  }

  /// 确保全局更新定时器正在运行
  void _ensureGlobalTimer() {
    if (_globalUpdateTimer != null) return;

    Logger.info('🔄 ProgressManager: Starting global update timer');

    _globalUpdateTimer = VisibilityManager().createPeriodicTimer(
        const Duration(milliseconds: 50),
        _updateAllProgresses,
        'ProgressManager.GlobalUpdate');
  }

  /// 停止全局更新定时器
  void _stopGlobalTimer() {
    if (_globalUpdateTimer != null) {
      Logger.info('⏹️ ProgressManager: Stopping global update timer');
      VisibilityManager().cancelTimer(_globalUpdateTimer!);
      _globalUpdateTimer = null;
    }
  }

  /// 更新所有进度
  void _updateAllProgresses() {
    if (_activeProgresses.isEmpty) {
      _stopGlobalTimer();
      return;
    }

    final now = DateTime.now();
    final completedProgresses = <String>[];

    // 更新所有进度
    for (final entry in _activeProgresses.entries) {
      final id = entry.key;
      final progress = entry.value;

      final elapsed = now.difference(progress.startTime);
      final newProgress =
          (elapsed.inMilliseconds / progress.duration).clamp(0.0, 1.0);

      progress.currentProgress = newProgress;

      // 检查是否完成
      if (newProgress >= 1.0) {
        completedProgresses.add(id);
      }
    }

    // 处理完成的进度
    for (final id in completedProgresses) {
      final progress = _activeProgresses[id]!;
      Logger.info('✅ ProgressManager: Progress $id completed');

      // 调用完成回调
      progress.onComplete();

      // 移除进度
      _activeProgresses.remove(id);
    }

    // 如果有变化，通知UI更新
    if (completedProgresses.isNotEmpty || _activeProgresses.isNotEmpty) {
      notifyListeners();
    }

    // 如果没有活动进度了，停止定时器
    if (_activeProgresses.isEmpty) {
      _stopGlobalTimer();
    }
  }

  @override
  void dispose() {
    _stopGlobalTimer();
    _activeProgresses.clear();
    super.dispose();
  }
}

/// 进度状态类
class ProgressState {
  final String id;
  final int duration;
  final DateTime startTime;
  final VoidCallback onComplete;
  double currentProgress;

  ProgressState({
    required this.id,
    required this.duration,
    required this.startTime,
    required this.onComplete,
    this.currentProgress = 0.0,
  });

  /// 获取进度百分比（0-100）
  int get progressPercent => (currentProgress * 100).toInt();

  /// 检查是否已完成
  bool get isCompleted => currentProgress >= 1.0;
}
