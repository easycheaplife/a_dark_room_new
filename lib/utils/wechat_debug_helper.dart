import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/logger.dart';

/// 微信WebView调试助手
/// 专门用于诊断和解决微信环境下的问题
class WeChatDebugHelper {
  static const String _logPrefix = '🔍 WeChatDebug';
  
  /// 收集完整的环境诊断信息
  static Map<String, dynamic> collectDiagnosticInfo() {
    if (!kIsWeb) {
      return {'error': 'Not running on web platform'};
    }

    try {
      final info = <String, dynamic>{};
      
      // 基础环境信息
      info['timestamp'] = DateTime.now().toIso8601String();
      info['userAgent'] = html.window.navigator.userAgent;
      info['url'] = html.window.location.href;
      info['origin'] = html.window.location.origin;
      info['protocol'] = html.window.location.protocol;
      info['host'] = html.window.location.host;
      
      // 微信环境检测
      info['isWeChatBrowser'] = _isWeChatBrowser();
      info['isMiniProgramWebView'] = _isMiniProgramWebView();
      info['isWeChatWork'] = _isWeChatWork();
      info['isWeChatDevTools'] = _isWeChatDevTools();
      
      // 浏览器能力检测
      info['capabilities'] = _checkBrowserCapabilities();
      
      // JavaScript环境检测
      info['jsEnvironment'] = _checkJavaScriptEnvironment();
      
      // 网络状态检测
      info['networkInfo'] = _checkNetworkInfo();
      
      // 性能信息
      info['performanceInfo'] = _checkPerformanceInfo();
      
      // 错误信息收集
      info['errors'] = _collectErrorInfo();
      
      Logger.info('$_logPrefix 诊断信息收集完成');
      return info;
      
    } catch (e) {
      Logger.error('$_logPrefix 收集诊断信息失败: $e');
      return {'error': e.toString()};
    }
  }

  /// 检测微信浏览器
  static bool _isWeChatBrowser() {
    try {
      final userAgent = html.window.navigator.userAgent;
      return userAgent.contains('MicroMessenger');
    } catch (e) {
      return false;
    }
  }

  /// 检测微信小程序WebView
  static bool _isMiniProgramWebView() {
    try {
      return js.context.hasProperty('wx') && 
             js.context['wx'].hasProperty('miniProgram');
    } catch (e) {
      return false;
    }
  }

  /// 检测企业微信
  static bool _isWeChatWork() {
    try {
      final userAgent = html.window.navigator.userAgent;
      return userAgent.contains('wxwork');
    } catch (e) {
      return false;
    }
  }

  /// 检测微信开发者工具
  static bool _isWeChatDevTools() {
    try {
      final userAgent = html.window.navigator.userAgent;
      return userAgent.contains('wechatdevtools');
    } catch (e) {
      return false;
    }
  }

  /// 检查浏览器能力
  static Map<String, dynamic> _checkBrowserCapabilities() {
    try {
      return {
        'webgl': _checkWebGLSupport(),
        'webassembly': _checkWebAssemblySupport(),
        'serviceWorker': _checkServiceWorkerSupport(),
        'localStorage': _checkLocalStorageSupport(),
        'sessionStorage': _checkSessionStorageSupport(),
        'indexedDB': _checkIndexedDBSupport(),
        'webAudio': _checkWebAudioSupport(),
        'canvas': _checkCanvasSupport(),
        'fetch': _checkFetchSupport(),
        'promises': _checkPromiseSupport(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 检查JavaScript环境
  static Map<String, dynamic> _checkJavaScriptEnvironment() {
    try {
      return {
        'hasWindow': js.context.hasProperty('window'),
        'hasDocument': js.context.hasProperty('document'),
        'hasNavigator': js.context.hasProperty('navigator'),
        'hasLocation': js.context.hasProperty('location'),
        'hasConsole': js.context.hasProperty('console'),
        'hasWx': js.context.hasProperty('wx'),
        'hasFlutter': js.context.hasProperty('flutter'),
        'hasFlutterBootstrap': js.context.hasProperty('_flutter'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 检查网络信息
  static Map<String, dynamic> _checkNetworkInfo() {
    try {
      final info = <String, dynamic>{};
      
      // 连接信息
      if (js.context['navigator'].hasProperty('connection')) {
        final connection = js.context['navigator']['connection'];
        info['effectiveType'] = connection['effectiveType'];
        info['downlink'] = connection['downlink'];
        info['rtt'] = connection['rtt'];
      }
      
      // 在线状态
      info['onLine'] = js.context['navigator']['onLine'];
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 检查性能信息
  static Map<String, dynamic> _checkPerformanceInfo() {
    try {
      final info = <String, dynamic>{};
      
      if (js.context.hasProperty('performance')) {
        final performance = js.context['performance'];
        
        // 内存信息
        if (performance.hasProperty('memory')) {
          final memory = performance['memory'];
          info['memory'] = {
            'usedJSHeapSize': memory['usedJSHeapSize'],
            'totalJSHeapSize': memory['totalJSHeapSize'],
            'jsHeapSizeLimit': memory['jsHeapSizeLimit'],
          };
        }
        
        // 导航时间
        if (performance.hasProperty('timing')) {
          final timing = performance['timing'];
          info['timing'] = {
            'navigationStart': timing['navigationStart'],
            'loadEventEnd': timing['loadEventEnd'],
            'domContentLoadedEventEnd': timing['domContentLoadedEventEnd'],
          };
        }
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 收集错误信息
  static List<Map<String, dynamic>> _collectErrorInfo() {
    // 这里可以收集已知的错误信息
    return [];
  }

  // 各种能力检测方法
  static bool _checkWebGLSupport() {
    try {
      final canvas = html.CanvasElement();
      return canvas.getContext('webgl') != null || 
             canvas.getContext('experimental-webgl') != null;
    } catch (e) {
      return false;
    }
  }

  static bool _checkWebAssemblySupport() {
    try {
      return js.context.hasProperty('WebAssembly');
    } catch (e) {
      return false;
    }
  }

  static bool _checkServiceWorkerSupport() {
    try {
      return js.context['navigator'].hasProperty('serviceWorker');
    } catch (e) {
      return false;
    }
  }

  static bool _checkLocalStorageSupport() {
    try {
      html.window.localStorage['test'] = 'test';
      html.window.localStorage.remove('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _checkSessionStorageSupport() {
    try {
      html.window.sessionStorage['test'] = 'test';
      html.window.sessionStorage.remove('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool _checkIndexedDBSupport() {
    try {
      return js.context.hasProperty('indexedDB');
    } catch (e) {
      return false;
    }
  }

  static bool _checkWebAudioSupport() {
    try {
      return js.context.hasProperty('AudioContext') || 
             js.context.hasProperty('webkitAudioContext');
    } catch (e) {
      return false;
    }
  }

  static bool _checkCanvasSupport() {
    try {
      final canvas = html.CanvasElement();
      return canvas.getContext('2d') != null;
    } catch (e) {
      return false;
    }
  }

  static bool _checkFetchSupport() {
    try {
      return js.context.hasProperty('fetch');
    } catch (e) {
      return false;
    }
  }

  static bool _checkPromiseSupport() {
    try {
      return js.context.hasProperty('Promise');
    } catch (e) {
      return false;
    }
  }

  /// 发送诊断信息到小程序
  static void sendDiagnosticToMiniProgram() {
    if (!_isMiniProgramWebView()) return;

    try {
      final diagnosticInfo = collectDiagnosticInfo();
      
      js.context['wx']['miniProgram'].callMethod('postMessage', [
        js.JsObject.jsify({
          'data': {
            'type': 'diagnostic',
            'info': diagnosticInfo,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        })
      ]);
      
      Logger.info('$_logPrefix 诊断信息已发送到小程序');
    } catch (e) {
      Logger.error('$_logPrefix 发送诊断信息失败: $e');
    }
  }

  /// 输出诊断报告到控制台
  static void printDiagnosticReport() {
    final info = collectDiagnosticInfo();
    final report = const JsonEncoder.withIndent('  ').convert(info);
    
    Logger.info('$_logPrefix 诊断报告:');
    Logger.info(report);
  }
}
