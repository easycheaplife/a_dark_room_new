import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import 'web_utils.dart';
import 'platform_adapter.dart';

/// 微信浏览器适配器
/// 专门处理微信浏览器的特殊需求和限制
class WeChatAdapter {
  static bool _initialized = false;
  static bool _isWeChatBrowser = false;

  /// 初始化微信适配器
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _isWeChatBrowser = WebUtils.isWeChatBrowser();

      if (_isWeChatBrowser) {
        await _initializeWeChatFeatures();
      }

      _initialized = true;
    } catch (e) {
      Logger.error('WeChatAdapter.initialize error: $e');
    }
  }

  /// 初始化微信特性
  static Future<void> _initializeWeChatFeatures() async {
    if (!kIsWeb) return;

    try {
      // 在移动端，这些功能不需要实现
      Logger.info('微信适配器已初始化（移动端模式）');
    } catch (e) {
      Logger.error('微信特性初始化失败: $e');
    }
  }

  /// 是否为微信浏览器
  static bool get isWeChatBrowser => _isWeChatBrowser;

  /// 配置微信分享
  static void configureShare({
    required String title,
    required String desc,
    String? link,
    String? imgUrl,
  }) {
    if (!kIsWeb || !_isWeChatBrowser) return;

    try {
      PlatformAdapter.configWeChatShare(
        title: title,
        desc: desc,
        link: link,
        imgUrl: imgUrl,
      );
    } catch (e) {
      Logger.error('微信分享配置失败: $e');
    }
  }

  /// 获取微信浏览器信息
  static Map<String, dynamic> getWeChatInfo() {
    return {
      'isWeChatBrowser': _isWeChatBrowser,
      'initialized': _initialized,
      'platform': kIsWeb ? 'web' : 'mobile',
    };
  }

  /// 检测微信浏览器功能支持
  static Map<String, bool> checkFeatureSupport() {
    return {
      'share': _isWeChatBrowser && kIsWeb,
      'audio': true, // 移动端默认支持
      'localStorage': true, // 使用SharedPreferences
      'canvas': true, // 移动端默认支持
      'webgl': true, // 移动端默认支持
    };
  }
}
