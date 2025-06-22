import 'package:flutter/services.dart';
import 'logger.dart';

/// 平台可见性管理器抽象基类
abstract class PlatformVisibilityManager {
  /// 初始化平台特定的可见性监听
  void init(Function(bool) onVisibilityChanged);
  
  /// 清理资源
  void dispose();
}

/// 移动平台的可见性管理器实现
class MobileVisibilityManager implements PlatformVisibilityManager {
  Function(bool)? _onVisibilityChanged;

  @override
  void init(Function(bool) onVisibilityChanged) {
    _onVisibilityChanged = onVisibilityChanged;
    
    Logger.info('🔧 Setting up mobile visibility listeners...');

    try {
      // 在移动平台上，我们监听应用生命周期变化
      SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
      Logger.info('✅ Mobile lifecycle listener set up');
    } catch (e) {
      Logger.error('❌ Mobile visibility manager setup failed: $e');
    }
  }

  /// 处理应用生命周期变化
  Future<String?> _handleLifecycleMessage(String? message) async {
    Logger.info('📱 Lifecycle state changed: $message');
    
    switch (message) {
      case 'AppLifecycleState.resumed':
        _onVisibilityChanged?.call(true);
        break;
      case 'AppLifecycleState.paused':
      case 'AppLifecycleState.inactive':
      case 'AppLifecycleState.detached':
        _onVisibilityChanged?.call(false);
        break;
    }
    
    return null;
  }

  @override
  void dispose() {
    SystemChannels.lifecycle.setMessageHandler(null);
    _onVisibilityChanged = null;
  }
}

/// 创建平台特定的可见性管理器
PlatformVisibilityManager createPlatformVisibilityManager() {
  return MobileVisibilityManager();
}
