/// 平台可见性管理器抽象基类
abstract class PlatformVisibilityManager {
  /// 初始化平台特定的可见性监听
  void init(Function(bool) onVisibilityChanged);
  
  /// 清理资源
  void dispose();
}

/// 创建平台特定的可见性管理器
PlatformVisibilityManager createPlatformVisibilityManager() {
  throw UnsupportedError('Platform not supported');
}
