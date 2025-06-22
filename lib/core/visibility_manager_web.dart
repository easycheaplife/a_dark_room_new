import 'dart:async';
import 'dart:html' as html;
import 'logger.dart';

/// 平台可见性管理器抽象基类
abstract class PlatformVisibilityManager {
  /// 初始化平台特定的可见性监听
  void init(Function(bool) onVisibilityChanged);
  
  /// 清理资源
  void dispose();
}

/// Web平台的可见性管理器实现
class WebVisibilityManager implements PlatformVisibilityManager {
  StreamSubscription<html.Event>? _visibilitySubscription;
  StreamSubscription<html.Event>? _focusSubscription;
  StreamSubscription<html.Event>? _blurSubscription;
  
  Function(bool)? _onVisibilityChanged;

  @override
  void init(Function(bool) onVisibilityChanged) {
    _onVisibilityChanged = onVisibilityChanged;
    
    Logger.info('🔧 Setting up web visibility listeners...');

    try {
      // 监听页面可见性变化
      _visibilitySubscription = html.document.onVisibilityChange.listen(_handleVisibilityChange);
      Logger.info('✅ Visibility change listener set up');

      // 监听窗口焦点变化
      _focusSubscription = html.window.onFocus.listen(_handleFocus);
      _blurSubscription = html.window.onBlur.listen(_handleBlur);
      Logger.info('✅ Focus/blur listeners set up');
    } catch (e) {
      Logger.error('❌ Web visibility manager setup failed: $e');
    }
  }

  /// 处理可见性变化
  void _handleVisibilityChange(html.Event event) {
    final isHidden = html.document.hidden ?? false;
    _onVisibilityChanged?.call(!isHidden);
  }

  /// 处理窗口获得焦点
  void _handleFocus(html.Event event) {
    _onVisibilityChanged?.call(true);
  }

  /// 处理窗口失去焦点
  void _handleBlur(html.Event event) {
    _onVisibilityChanged?.call(false);
  }

  @override
  void dispose() {
    _visibilitySubscription?.cancel();
    _focusSubscription?.cancel();
    _blurSubscription?.cancel();
    _onVisibilityChanged = null;
  }
}

/// 创建平台特定的可见性管理器
PlatformVisibilityManager createPlatformVisibilityManager() {
  return WebVisibilityManager();
}
