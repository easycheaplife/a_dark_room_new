import 'package:flutter/foundation.dart';
import '../core/logger.dart';

// 条件导入：只在Web平台导入Web专用库
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web平台工具类
/// 提供Web平台特有的功能，如浏览器检测、本地存储等
class WebUtils {
  /// 检测是否为微信浏览器
  static bool isWeChatBrowser() {
    if (!kIsWeb) return false;
    
    try {
      final userAgent = html.window.navigator.userAgent;
      return userAgent.contains('MicroMessenger');
    } catch (e) {
      return false;
    }
  }

  /// 检测是否为移动设备浏览器
  static bool isMobileBrowser() {
    if (!kIsWeb) return false;
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') || 
             userAgent.contains('android') || 
             userAgent.contains('iphone') || 
             userAgent.contains('ipad');
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
      };
    }
    
    try {
      final userAgent = html.window.navigator.userAgent;
      return {
        'isWeb': true,
        'isWeChat': isWeChatBrowser(),
        'isMobile': isMobileBrowser(),
        'userAgent': userAgent,
        'platform': html.window.navigator.platform,
        'language': html.window.navigator.language,
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
      (html.window.document as dynamic).title = title;
    } catch (e) {
      // 忽略错误
    }
  }

  /// 获取当前URL
  static String getCurrentUrl() {
    if (!kIsWeb) return '';
    
    try {
      return html.window.location.href;
    } catch (e) {
      return '';
    }
  }

  /// 获取URL参数
  static Map<String, String> getUrlParameters() {
    if (!kIsWeb) return {};
    
    try {
      final uri = Uri.parse(html.window.location.href);
      return uri.queryParameters;
    } catch (e) {
      return {};
    }
  }

  /// 配置微信分享（需要微信JS-SDK）
  static void configWeChatShare({
    required String title,
    required String desc,
    String? link,
    String? imgUrl,
  }) {
    if (!kIsWeb || !isWeChatBrowser()) return;
    
    try {
      // 调用微信JS-SDK配置分享
      js.context.callMethod('configWeChatShare', [
        js.JsObject.jsify({
          'title': title,
          'desc': desc,
          'link': link ?? getCurrentUrl(),
          'imgUrl': imgUrl ?? '${html.window.location.origin}/icons/Icon-512.png',
        })
      ]);
    } catch (e) {
      // 如果微信JS-SDK未加载或配置失败，忽略错误
      Logger.error('WeChat share config failed: $e');
    }
  }

  /// 禁用页面的一些默认行为（适合游戏）
  static void disablePageDefaults() {
    if (!kIsWeb) return;
    
    try {
      // 禁用右键菜单
      html.window.document.onContextMenu.listen((event) {
        event.preventDefault();
      });
      
      // 禁用文本选择
      final body = (html.window.document as dynamic).body;
      if (body != null) {
        body.style.userSelect = 'none';
        body.style.webkitUserSelect = 'none';
      }
      
      // 禁用图片拖拽
      html.window.document.onDragStart.listen((event) {
        event.preventDefault();
      });
      
      // 禁用双击缩放（移动端）
      html.window.document.onTouchStart.listen((event) {
        if (event.touches!.length > 1) {
          event.preventDefault();
        }
      });
      
    } catch (e) {
      // 忽略错误
    }
  }

  /// 添加移动端优化的CSS
  static void addMobileOptimizations() {
    if (!kIsWeb) return;
    
    try {
      final style = html.window.document.createElement('style') as dynamic;
      style.text = '''
        /* 移动端优化 */
        body {
          -webkit-touch-callout: none;
          -webkit-user-select: none;
          -webkit-tap-highlight-color: transparent;
          touch-action: manipulation;
        }
        
        /* 防止移动端缩放 */
        * {
          -webkit-touch-callout: none;
          -webkit-user-select: none;
        }
        
        /* 优化触摸响应 */
        button, .clickable {
          touch-action: manipulation;
          -webkit-tap-highlight-color: transparent;
        }
        
        /* 微信浏览器特殊优化 */
        .wechat-optimized {
          -webkit-overflow-scrolling: touch;
        }
      ''';
      final head = (html.window.document as dynamic).head;
      if (head != null) {
        head.appendChild(style);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 检测是否支持触摸
  static bool isTouchDevice() {
    if (!kIsWeb) return false;
    
    try {
      return js.context.hasProperty('ontouchstart') ||
             (html.window.navigator.maxTouchPoints ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  /// 获取屏幕信息
  static Map<String, dynamic> getScreenInfo() {
    if (!kIsWeb) return {};
    
    try {
      final screen = html.window.screen as dynamic;
      return {
        'width': screen?.width ?? 0,
        'height': screen?.height ?? 0,
        'availWidth': screen?.availWidth ?? 0,
        'availHeight': screen?.availHeight ?? 0,
        'devicePixelRatio': html.window.devicePixelRatio,
        'orientation': screen?.orientation?.angle ?? 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
