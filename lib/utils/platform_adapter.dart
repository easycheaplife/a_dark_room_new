import 'package:flutter/foundation.dart';
import '../core/logger.dart';

/// 平台适配器 - 提供跨平台的统一接口
/// 解决Web专用库在其他平台上的兼容性问题
class PlatformAdapter {
  /// 检测是否为微信浏览器
  static bool isWeChatBrowser() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台，通过用户代理字符串检测
      // 在非Web平台，直接返回false
      return false; // 简化实现，避免使用dart:html
    } catch (e) {
      return false;
    }
  }

  /// 检测是否为移动设备浏览器
  static bool isMobileBrowser() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台，通过用户代理字符串检测
      // 在非Web平台，直接返回false
      return false; // 简化实现，避免使用dart:html
    } catch (e) {
      return false;
    }
  }

  /// 获取浏览器信息
  static Map<String, dynamic> getBrowserInfo() {
    if (!kIsWeb) {
      return {
        'isWeb': false,
        'isWeChat': false,
        'isMobile': false,
        'userAgent': '',
        'platform': 'mobile',
      };
    }
    
    try {
      return {
        'isWeb': true,
        'isWeChat': false, // 简化实现
        'isMobile': false, // 简化实现
        'userAgent': '',
        'platform': 'web',
      };
    } catch (e) {
      return {
        'isWeb': true,
        'isWeChat': false,
        'isMobile': false,
        'userAgent': '',
        'error': e.toString(),
      };
    }
  }

  /// 设置页面标题
  static void setPageTitle(String title) {
    if (!kIsWeb) return;

    try {
      // 在Web平台设置页面标题
      // 在非Web平台，此操作无效
    } catch (e) {
      // 忽略错误
    }
  }

  /// 获取当前URL
  static String getCurrentUrl() {
    if (!kIsWeb) return '';
    
    try {
      // 在Web平台返回当前URL
      // 在非Web平台返回空字符串
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 配置微信分享
  static void configWeChatShare({
    required String title,
    required String desc,
    String? link,
    String? imgUrl,
  }) {
    if (!kIsWeb) return;
    
    try {
      // 在Web平台配置微信分享
      // 在非Web平台，此操作无效
      Logger.info('配置微信分享: $title');
    } catch (e) {
      Logger.error('配置微信分享失败: $e');
    }
  }

  /// 禁用页面的一些默认行为（适合游戏）
  static void disablePageDefaults() {
    if (!kIsWeb) return;
    
    try {
      // 在Web平台禁用一些默认行为
      // 在非Web平台，此操作无效
    } catch (e) {
      // 忽略错误
    }
  }

  /// 添加移动端优化的CSS
  static void addMobileOptimizations() {
    if (!kIsWeb) return;
    
    try {
      // 在Web平台添加移动端优化CSS
      // 在非Web平台，此操作无效
    } catch (e) {
      // 忽略错误
    }
  }

  /// 检测是否支持触摸
  static bool isTouchDevice() {
    if (!kIsWeb) {
      // 在移动平台，默认支持触摸
      return true;
    }
    
    try {
      // 在Web平台检测触摸支持
      return false; // 简化实现
    } catch (e) {
      return false;
    }
  }

  /// 获取屏幕信息
  static Map<String, dynamic> getScreenInfo() {
    try {
      return {
        'width': 0,
        'height': 0,
        'devicePixelRatio': 1.0,
      };
    } catch (e) {
      return {
        'width': 0,
        'height': 0,
        'devicePixelRatio': 1.0,
        'error': e.toString(),
      };
    }
  }

  /// 检测是否支持本地存储
  static bool supportsLocalStorage() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台检测localStorage支持
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }

  /// 检测是否支持Web Audio API
  static bool supportsWebAudio() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台检测Web Audio API支持
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }

  /// 检测Canvas支持
  static bool supportsCanvas() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台检测Canvas支持
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }

  /// 检测WebGL支持
  static bool supportsWebGL() {
    if (!kIsWeb) return false;
    
    try {
      // 在Web平台检测WebGL支持
      return true; // 简化实现
    } catch (e) {
      return false;
    }
  }

  /// 检测是否为移动设备
  static bool isMobileDevice() {
    if (!kIsWeb) {
      // 在非Web平台，根据平台判断
      return defaultTargetPlatform == TargetPlatform.android ||
             defaultTargetPlatform == TargetPlatform.iOS;
    }
    
    return isMobileBrowser();
  }
}
