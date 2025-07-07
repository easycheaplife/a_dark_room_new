import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import 'platform_adapter.dart';

/// Web平台工具类
/// 提供Web平台特有的功能，如浏览器检测、本地存储等
class WebUtils {
  /// 检测是否为微信浏览器
  static bool isWeChatBrowser() {
    return PlatformAdapter.isWeChatBrowser();
  }

  /// 检测是否为移动设备浏览器
  static bool isMobileBrowser() {
    return PlatformAdapter.isMobileBrowser();
  }

  /// 获取浏览器信息
  static Map<String, dynamic> getBrowserInfo() {
    return PlatformAdapter.getBrowserInfo();
  }

  /// 设置页面标题
  static void setPageTitle(String title) {
    PlatformAdapter.setPageTitle(title);
  }

  /// 获取当前URL
  static String getCurrentUrl() {
    return PlatformAdapter.getCurrentUrl();
  }

  /// 获取URL参数
  static Map<String, String> getUrlParameters() {
    if (!kIsWeb) return {};

    try {
      final uri = Uri.parse(getCurrentUrl());
      return uri.queryParameters;
    } catch (e) {
      return {};
    }
  }

  /// 配置微信分享
  static void configWeChatShare({
    required String title,
    required String desc,
    String? link,
    String? imgUrl,
  }) {
    PlatformAdapter.configWeChatShare(
      title: title,
      desc: desc,
      link: link,
      imgUrl: imgUrl,
    );
  }

  /// 禁用页面的一些默认行为（适合游戏）
  static void disablePageDefaults() {
    PlatformAdapter.disablePageDefaults();
  }

  /// 添加移动端优化的CSS
  static void addMobileOptimizations() {
    PlatformAdapter.addMobileOptimizations();
  }

  /// 检测是否支持触摸
  static bool isTouchDevice() {
    return PlatformAdapter.isTouchDevice();
  }

  /// 获取屏幕信息
  static Map<String, dynamic> getScreenInfo() {
    return PlatformAdapter.getScreenInfo();
  }

  /// 检测是否支持本地存储
  static bool supportsLocalStorage() {
    return PlatformAdapter.supportsLocalStorage();
  }

  /// 检测是否支持Web Audio API
  static bool supportsWebAudio() {
    return PlatformAdapter.supportsWebAudio();
  }

  /// 检测Canvas支持
  static bool supportsCanvas() {
    return PlatformAdapter.supportsCanvas();
  }

  /// 检测WebGL支持
  static bool supportsWebGL() {
    return PlatformAdapter.supportsWebGL();
  }

  /// 检测是否为移动设备
  static bool isMobileDevice() {
    return PlatformAdapter.isMobileDevice();
  }
}
