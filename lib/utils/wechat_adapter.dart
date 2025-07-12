import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import 'web_utils.dart';
import 'platform_adapter.dart';

// 条件导入，只在Web平台导入js库
import 'dart:js' as js;
import 'dart:convert' show jsonEncode;

/// 微信浏览器适配器
/// 专门处理微信浏览器的特殊需求和限制
/// 支持微信小程序内嵌H5环境
class WeChatAdapter {
  static bool _initialized = false;
  static bool _isWeChatBrowser = false;
  static bool _isInMiniProgram = false;

  /// 初始化微信适配器
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _isWeChatBrowser = WebUtils.isWeChatBrowser();
      _isInMiniProgram = _detectMiniProgramEnvironment();

      if (_isWeChatBrowser || _isInMiniProgram) {
        await _initializeWeChatFeatures();
      }

      _initialized = true;
      Logger.info('微信适配器初始化完成 - 微信浏览器: $_isWeChatBrowser, 小程序环境: $_isInMiniProgram');
    } catch (e) {
      Logger.error('WeChatAdapter.initialize error: $e');
    }
  }

  /// 检测是否在微信小程序环境中
  static bool _detectMiniProgramEnvironment() {
    if (!kIsWeb) return false;

    try {
      // 检测微信小程序环境
      return js.context.hasProperty('wx') &&
             js.context['wx'].hasProperty('miniProgram');
    } catch (e) {
      Logger.error('检测微信小程序环境失败: $e');
      return false;
    }
  }

  /// 初始化微信特性
  static Future<void> _initializeWeChatFeatures() async {
    if (!kIsWeb) return;

    try {
      // 设置全局错误处理
      _setupGlobalErrorHandling();

      // 配置微信环境优化
      _configureWeChatOptimizations();

      // 设置调试信息收集
      _setupDebugInfoCollection();

      Logger.info('微信特性初始化完成');
    } catch (e) {
      Logger.error('微信特性初始化失败: $e');
    }
  }

  /// 设置全局错误处理
  static void _setupGlobalErrorHandling() {
    try {
      // 设置Flutter错误处理回调
      js.context['handleFlutterError'] = js.allowInterop((String error, String context) {
        Logger.error('Flutter错误 [$context]: $error');

        // 发送错误信息到小程序
        if (_isInMiniProgram) {
          postMessageToMiniProgram({
            'type': 'error',
            'context': context,
            'error': error,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });

      Logger.info('全局错误处理已设置');
    } catch (e) {
      Logger.error('设置全局错误处理失败: $e');
    }
  }

  /// 配置微信环境优化
  static void _configureWeChatOptimizations() {
    try {
      // 这里可以添加微信环境下的特殊优化
      Logger.info('微信环境优化已配置');
    } catch (e) {
      Logger.error('配置微信环境优化失败: $e');
    }
  }

  /// 设置调试信息收集
  static void _setupDebugInfoCollection() {
    try {
      // 收集环境信息
      final envInfo = {
        'userAgent': js.context['navigator']['userAgent'],
        'url': js.context['location']['href'],
        'isWeChatBrowser': _isWeChatBrowser,
        'isInMiniProgram': _isInMiniProgram,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      Logger.info('环境信息: ${jsonEncode(envInfo)}');

      // 发送环境信息到小程序
      if (_isInMiniProgram) {
        postMessageToMiniProgram({
          'type': 'environmentInfo',
          'info': envInfo,
        });
      }

    } catch (e) {
      Logger.error('设置调试信息收集失败: $e');
    }
  }

  /// 是否为微信浏览器
  static bool get isWeChatBrowser => _isWeChatBrowser;

  /// 是否在微信小程序环境中
  static bool get isInMiniProgram => _isInMiniProgram;

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

  /// 向微信小程序发送消息
  static void postMessageToMiniProgram(Map<String, dynamic> data) {
    if (!kIsWeb || !_isInMiniProgram) {
      Logger.info('不在微信小程序环境中，无法发送消息');
      return;
    }

    try {
      final message = {'data': data};
      js.context['wx']['miniProgram'].callMethod('postMessage', [
        js.JsObject.jsify(message)
      ]);
      Logger.info('向微信小程序发送消息: ${jsonEncode(data)}');
    } catch (e) {
      Logger.error('向微信小程序发送消息失败: $e');
    }
  }

  /// 导航回微信小程序页面
  static void navigateBackToMiniProgram() {
    if (!kIsWeb || !_isInMiniProgram) {
      Logger.info('不在微信小程序环境中，无法导航');
      return;
    }

    try {
      js.context['wx']['miniProgram'].callMethod('navigateBack');
      Logger.info('导航回微信小程序页面');
    } catch (e) {
      Logger.error('导航回微信小程序失败: $e');
    }
  }

  /// 保存游戏数据到微信小程序
  static void saveGameDataToMiniProgram(Map<String, dynamic> gameData) {
    postMessageToMiniProgram({
      'type': 'saveGame',
      'gameData': gameData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 请求从微信小程序加载游戏数据
  static void requestGameDataFromMiniProgram() {
    postMessageToMiniProgram({
      'type': 'loadGame',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 获取微信浏览器信息
  static Map<String, dynamic> getWeChatInfo() {
    return {
      'isWeChatBrowser': _isWeChatBrowser,
      'isInMiniProgram': _isInMiniProgram,
      'initialized': _initialized,
      'platform': kIsWeb ? 'web' : 'mobile',
      'environment': _isInMiniProgram ? 'miniprogram' : (_isWeChatBrowser ? 'wechat' : 'other'),
    };
  }

  /// 检测微信浏览器功能支持
  static Map<String, bool> checkFeatureSupport() {
    return {
      'share': _isWeChatBrowser && kIsWeb,
      'miniProgramCommunication': _isInMiniProgram && kIsWeb,
      'audio': true, // 移动端默认支持
      'localStorage': true, // 使用SharedPreferences
      'canvas': true, // 移动端默认支持
      'webgl': true, // 移动端默认支持
      'postMessage': _isInMiniProgram,
      'navigation': _isInMiniProgram,
    };
  }
}
