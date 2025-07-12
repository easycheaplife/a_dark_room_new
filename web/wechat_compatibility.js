/**
 * 微信环境Flutter Web兼容性配置
 * 专门处理微信浏览器和小程序WebView的兼容性问题
 */

(function() {
  'use strict';

  // 微信环境检测
  const WeChatDetector = {
    isWeChat: function() {
      return /MicroMessenger/i.test(navigator.userAgent);
    },
    
    isMiniProgram: function() {
      return window.wx && window.wx.miniProgram;
    },
    
    isWeChatWork: function() {
      return /wxwork/i.test(navigator.userAgent);
    },
    
    isWeChatDevTools: function() {
      return /wechatdevtools/i.test(navigator.userAgent);
    },
    
    getWeChatVersion: function() {
      const match = navigator.userAgent.match(/MicroMessenger\/(\d+\.\d+\.\d+)/);
      return match ? match[1] : 'unknown';
    }
  };

  // 微信环境配置
  const WeChatConfig = {
    // 强制使用HTML渲染器（微信环境兼容性更好）
    forceHtmlRenderer: true,
    
    // 禁用Service Worker（微信环境可能不支持）
    disableServiceWorker: true,
    
    // 禁用WebGL（避免兼容性问题）
    disableWebGL: true,
    
    // 启用详细日志
    enableVerboseLogging: true,
    
    // 错误上报到小程序
    reportErrorsToMiniProgram: true
  };

  // 微信环境初始化
  function initializeWeChatEnvironment() {
    if (!WeChatDetector.isWeChat()) {
      console.log('非微信环境，跳过微信兼容性配置');
      return;
    }

    console.log('🔥 检测到微信环境，应用兼容性配置');
    console.log('微信版本:', WeChatDetector.getWeChatVersion());
    console.log('小程序环境:', WeChatDetector.isMiniProgram());
    console.log('企业微信:', WeChatDetector.isWeChatWork());
    console.log('开发者工具:', WeChatDetector.isWeChatDevTools());

    // 1. 禁用Service Worker
    if (WeChatConfig.disableServiceWorker && 'serviceWorker' in navigator) {
      disableServiceWorker();
    }

    // 2. 配置Flutter渲染器
    configureFlutterRenderer();

    // 3. 设置错误处理
    setupErrorHandling();

    // 4. 优化资源加载
    optimizeResourceLoading();

    // 5. 发送环境信息到小程序
    if (WeChatDetector.isMiniProgram()) {
      sendEnvironmentInfoToMiniProgram();
    }
  }

  // 禁用Service Worker
  function disableServiceWorker() {
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
      registrations.forEach(function(registration) {
        registration.unregister().then(function(success) {
          if (success) {
            console.log('✅ 已禁用Service Worker for 微信环境');
          }
        });
      });
    }).catch(function(error) {
      console.warn('Service Worker处理失败:', error);
    });
  }

  // 配置Flutter渲染器
  function configureFlutterRenderer() {
    // 确保_flutter对象存在
    window._flutter = window._flutter || {};
    
    // 设置构建配置
    if (!window._flutter.buildConfig) {
      window._flutter.buildConfig = {
        engineRevision: "cb4b5fff73850b2e42bd4de7cb9a4310a78ac40d",
        builds: [{
          compileTarget: "dart2js",
          renderer: "html", // 强制使用HTML渲染器
          mainJsPath: "main.dart.js"
        }]
      };
    } else if (window._flutter.buildConfig.builds) {
      // 修改现有配置
      window._flutter.buildConfig.builds.forEach(function(build) {
        if (build.renderer === 'canvaskit' || build.renderer === 'auto') {
          build.renderer = 'html';
          console.log('✅ 已切换到HTML渲染器 for 微信环境');
        }
      });
    }
  }

  // 设置错误处理
  function setupErrorHandling() {
    // 全局错误处理
    window.addEventListener('error', function(event) {
      const errorInfo = {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error ? event.error.toString() : 'Unknown error',
        userAgent: navigator.userAgent,
        timestamp: new Date().toISOString()
      };

      console.error('🚨 微信环境Flutter错误:', errorInfo);

      // 发送到小程序
      if (WeChatConfig.reportErrorsToMiniProgram && WeChatDetector.isMiniProgram()) {
        try {
          window.wx.miniProgram.postMessage({
            data: {
              type: 'flutter_error',
              ...errorInfo
            }
          });
        } catch (e) {
          console.error('发送错误信息到小程序失败:', e);
        }
      }
    });

    // Promise错误处理
    window.addEventListener('unhandledrejection', function(event) {
      const errorInfo = {
        reason: event.reason ? event.reason.toString() : 'Unknown promise rejection',
        userAgent: navigator.userAgent,
        timestamp: new Date().toISOString()
      };

      console.error('🚨 微信环境Promise错误:', errorInfo);

      if (WeChatConfig.reportErrorsToMiniProgram && WeChatDetector.isMiniProgram()) {
        try {
          window.wx.miniProgram.postMessage({
            data: {
              type: 'flutter_promise_error',
              ...errorInfo
            }
          });
        } catch (e) {
          console.error('发送Promise错误信息到小程序失败:', e);
        }
      }
    });
  }

  // 优化资源加载
  function optimizeResourceLoading() {
    // 预加载关键资源
    const criticalResources = [
      'main.dart.js',
      'flutter.js'
    ];

    criticalResources.forEach(function(resource) {
      const link = document.createElement('link');
      link.rel = 'preload';
      link.as = 'script';
      link.href = resource;
      document.head.appendChild(link);
    });
  }

  // 发送环境信息到小程序
  function sendEnvironmentInfoToMiniProgram() {
    const envInfo = {
      type: 'environment_info',
      isWeChat: WeChatDetector.isWeChat(),
      isMiniProgram: WeChatDetector.isMiniProgram(),
      isWeChatWork: WeChatDetector.isWeChatWork(),
      isWeChatDevTools: WeChatDetector.isWeChatDevTools(),
      wechatVersion: WeChatDetector.getWeChatVersion(),
      userAgent: navigator.userAgent,
      url: window.location.href,
      timestamp: new Date().toISOString(),
      capabilities: {
        webgl: checkWebGLSupport(),
        webassembly: checkWebAssemblySupport(),
        serviceWorker: 'serviceWorker' in navigator,
        localStorage: checkLocalStorageSupport()
      }
    };

    try {
      window.wx.miniProgram.postMessage({
        data: envInfo
      });
      console.log('✅ 环境信息已发送到小程序');
    } catch (e) {
      console.error('发送环境信息到小程序失败:', e);
    }
  }

  // 能力检测函数
  function checkWebGLSupport() {
    try {
      const canvas = document.createElement('canvas');
      return !!(canvas.getContext('webgl') || canvas.getContext('experimental-webgl'));
    } catch (e) {
      return false;
    }
  }

  function checkWebAssemblySupport() {
    try {
      return typeof WebAssembly === 'object';
    } catch (e) {
      return false;
    }
  }

  function checkLocalStorageSupport() {
    try {
      localStorage.setItem('test', 'test');
      localStorage.removeItem('test');
      return true;
    } catch (e) {
      return false;
    }
  }

  // 页面加载完成后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeWeChatEnvironment);
  } else {
    initializeWeChatEnvironment();
  }

  // 暴露给全局使用
  window.WeChatCompatibility = {
    detector: WeChatDetector,
    config: WeChatConfig,
    initialize: initializeWeChatEnvironment
  };

})();
