import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import 'web_utils.dart';

// 条件导入：只在Web平台导入Web专用库
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

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

  /// 是否为微信浏览器
  static bool get isWeChatBrowser => _isWeChatBrowser;

  /// 初始化微信特有功能
  static Future<void> _initializeWeChatFeatures() async {
    if (!kIsWeb || !_isWeChatBrowser) return;
    
    try {
      // 配置微信浏览器特有的样式
      _addWeChatStyles();
      
      // 处理微信浏览器的特殊事件
      _handleWeChatEvents();
      
      // 配置微信分享
      _configureWeChatShare();
      
      // 处理微信浏览器的音频限制
      _handleAudioRestrictions();
      
      Logger.info('WeChat browser features initialized');
    } catch (e) {
      Logger.error('_initializeWeChatFeatures error: $e');
    }
  }

  /// 添加微信浏览器特有样式
  static void _addWeChatStyles() {
    if (!kIsWeb) return;
    
    try {
      final style = html.document.createElement('style') as html.StyleElement;
      style.text = '''
        /* 微信浏览器特殊优化 */
        body {
          /* 防止微信浏览器的下拉刷新 */
          overscroll-behavior: none;
          /* 优化滚动性能 */
          -webkit-overflow-scrolling: touch;
        }
        
        /* 微信浏览器中的输入框优化 */
        input, textarea {
          /* 防止微信浏览器自动缩放 */
          font-size: 16px !important;
        }
        
        /* 微信浏览器中的按钮优化 */
        button, .btn {
          /* 增大触摸区域 */
          min-height: 44px;
          /* 防止微信浏览器的默认样式 */
          -webkit-appearance: none;
          border-radius: 4px;
        }
        
        /* 微信浏览器中的链接优化 */
        a {
          /* 防止微信浏览器的默认高亮 */
          -webkit-tap-highlight-color: transparent;
        }
        
        /* 微信浏览器中的图片优化 */
        img {
          /* 防止微信浏览器的图片长按菜单 */
          -webkit-touch-callout: none;
          pointer-events: none;
        }
        
        /* 微信浏览器中的文本选择优化 */
        .game-content {
          /* 防止微信浏览器的文本选择 */
          -webkit-user-select: none;
          user-select: none;
        }
        
        /* 微信浏览器中的滚动条优化 */
        ::-webkit-scrollbar {
          width: 0px;
          background: transparent;
        }
      ''';
      final head = (html.document as dynamic).head;
      if (head != null) {
        head.appendChild(style);
      }
    } catch (e) {
      Logger.error('_addWeChatStyles error: $e');
    }
  }

  /// 处理微信浏览器特殊事件
  static void _handleWeChatEvents() {
    if (!kIsWeb) return;
    
    try {
      // 处理微信浏览器的返回按钮
      html.window.addEventListener('popstate', (event) {
        // 可以在这里处理微信浏览器的返回逻辑
        Logger.info('WeChat browser back button pressed');
      });
      
      // 处理微信浏览器的页面可见性变化
      html.document.addEventListener('visibilitychange', (event) {
        if (html.document.hidden == true) {
          // 页面隐藏时暂停游戏
          _pauseGame();
        } else {
          // 页面显示时恢复游戏
          _resumeGame();
        }
      });
      
      // 处理微信浏览器的网络状态变化
      html.window.addEventListener('online', (event) {
        Logger.info('WeChat browser: Network online');
      });

      html.window.addEventListener('offline', (event) {
        Logger.info('WeChat browser: Network offline');
      });
      
    } catch (e) {
      Logger.error('_handleWeChatEvents error: $e');
    }
  }

  /// 配置微信分享
  static void _configureWeChatShare() {
    if (!kIsWeb) return;
    
    try {
      // 配置默认分享信息
      final shareConfig = {
        'title': 'A Dark Room - 黑暗房间',
        'desc': '一个引人入胜的文字冒险游戏，快来体验吧！',
        'link': html.window.location.href,
        'imgUrl': '${html.window.location.origin}/icons/Icon-512.png',
      };
      
      // 调用全局的微信分享配置函数
      if (js.context.hasProperty('configWeChatShare')) {
        js.context.callMethod('configWeChatShare', [js.JsObject.jsify(shareConfig)]);
      }
    } catch (e) {
      Logger.error('_configureWeChatShare error: $e');
    }
  }

  /// 处理微信浏览器的音频限制
  static void _handleAudioRestrictions() {
    if (!kIsWeb) return;
    
    try {
      // 微信浏览器需要用户交互才能播放音频
      // 这里可以添加首次点击时解锁音频的逻辑
      html.document.addEventListener('touchstart', (event) {
        _unlockAudio();
      }, true);

      html.document.addEventListener('click', (event) {
        _unlockAudio();
      }, true);
      
    } catch (e) {
      Logger.error('_handleAudioRestrictions error: $e');
    }
  }

  /// 解锁音频播放
  static void _unlockAudio() {
    if (!kIsWeb) return;
    
    try {
      // 创建一个静音的音频上下文来解锁音频
      if (js.context.hasProperty('AudioContext') || js.context.hasProperty('webkitAudioContext')) {
        final audioContext = js.context.hasProperty('AudioContext') 
            ? js.JsObject(js.context['AudioContext'])
            : js.JsObject(js.context['webkitAudioContext']);
        
        // 创建一个短暂的静音音频
        final oscillator = audioContext.callMethod('createOscillator');
        final gainNode = audioContext.callMethod('createGain');
        
        oscillator.callMethod('connect', [gainNode]);
        gainNode.callMethod('connect', [audioContext['destination']]);
        
        gainNode['gain']['value'] = 0; // 静音
        oscillator.callMethod('start', [0]);
        oscillator.callMethod('stop', [0.1]);
        
        Logger.info('Audio unlocked for WeChat browser');
      }
    } catch (e) {
      Logger.error('_unlockAudio error: $e');
    }
  }

  /// 暂停游戏
  static void _pauseGame() {
    try {
      // 这里可以添加暂停游戏的逻辑
      Logger.info('Game paused (WeChat browser hidden)');
    } catch (e) {
      Logger.error('_pauseGame error: $e');
    }
  }

  /// 恢复游戏
  static void _resumeGame() {
    try {
      // 这里可以添加恢复游戏的逻辑
      Logger.info('Game resumed (WeChat browser visible)');
    } catch (e) {
      Logger.error('_resumeGame error: $e');
    }
  }

  /// 获取微信浏览器版本信息
  static Map<String, dynamic> getWeChatInfo() {
    if (!kIsWeb || !_isWeChatBrowser) {
      return {'isWeChat': false};
    }
    
    try {
      final userAgent = html.window.navigator.userAgent;
      final wechatMatch = RegExp(r'MicroMessenger/(\d+\.\d+\.\d+)').firstMatch(userAgent);
      
      return {
        'isWeChat': true,
        'version': wechatMatch?.group(1) ?? 'unknown',
        'userAgent': userAgent,
        'platform': html.window.navigator.platform,
        'language': html.window.navigator.language,
      };
    } catch (e) {
      return {
        'isWeChat': true,
        'error': e.toString(),
      };
    }
  }

  /// 检查微信浏览器功能支持
  static Map<String, bool> checkFeatureSupport() {
    if (!kIsWeb || !_isWeChatBrowser) {
      return {};
    }
    
    try {
      return {
        'localStorage': _checkLocalStorageSupport(),
        'webAudio': _checkWebAudioSupport(),
        'canvas': _checkCanvasSupport(),
        'webGL': _checkWebGLSupport(),
        'touch': _checkTouchSupport(),
      };
    } catch (e) {
      return {'error': true};
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

  static bool _checkWebAudioSupport() {
    return js.context.hasProperty('AudioContext') || js.context.hasProperty('webkitAudioContext');
  }

  static bool _checkCanvasSupport() {
    try {
      final canvas = html.document.createElement('canvas') as html.CanvasElement;
      return canvas.getContext('2d') != null;
    } catch (e) {
      return false;
    }
  }

  static bool _checkWebGLSupport() {
    try {
      final canvas = html.document.createElement('canvas') as html.CanvasElement;
      return canvas.getContext('webgl') != null || canvas.getContext('experimental-webgl') != null;
    } catch (e) {
      return false;
    }
  }

  static bool _checkTouchSupport() {
    return js.context.hasProperty('ontouchstart') || (html.window.navigator.maxTouchPoints ?? 0) > 0;
  }
}
