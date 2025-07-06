import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// 条件导入：只在Web平台导入Web专用库
import 'dart:html' as html;
import 'dart:js' as js;

/// 性能优化工具类
/// 提供各种性能优化功能，包括资源预加载、懒加载、内存管理等
class PerformanceOptimizer {
  static bool _initialized = false;
  static final Map<String, dynamic> _cache = {};
  static final List<String> _preloadedImages = [];
  
  /// 初始化性能优化器
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb) {
        await _initializeWebOptimizations();
      }
      
      _initialized = true;
      print('PerformanceOptimizer initialized');
    } catch (e) {
      print('PerformanceOptimizer.initialize error: $e');
    }
  }

  /// 初始化Web平台性能优化
  static Future<void> _initializeWebOptimizations() async {
    if (!kIsWeb) return;
    
    try {
      // 预加载关键资源
      await _preloadCriticalResources();
      
      // 设置资源缓存策略
      _setupResourceCaching();
      
      // 优化渲染性能
      _optimizeRendering();
      
      // 监控性能指标
      _monitorPerformance();
      
    } catch (e) {
      print('_initializeWebOptimizations error: $e');
    }
  }

  /// 预加载关键资源
  static Future<void> _preloadCriticalResources() async {
    if (!kIsWeb) return;
    
    try {
      // 预加载图标
      final iconUrls = [
        'icons/Icon-192.png',
        'icons/Icon-512.png',
        'icons/Icon-maskable-192.png',
        'icons/Icon-maskable-512.png',
      ];
      
      for (String url in iconUrls) {
        await _preloadImage(url);
      }
      
      // 预加载字体（如果有的话）
      // await _preloadFonts();
      
      print('Critical resources preloaded: ${_preloadedImages.length} images');
    } catch (e) {
      print('_preloadCriticalResources error: $e');
    }
  }

  /// 预加载图片
  static Future<void> _preloadImage(String url) async {
    if (!kIsWeb || _preloadedImages.contains(url)) return;
    
    try {
      final img = html.ImageElement();
      final completer = Completer<void>();
      
      img.onLoad.listen((_) {
        _preloadedImages.add(url);
        completer.complete();
      });
      
      img.onError.listen((_) {
        print('Failed to preload image: $url');
        completer.complete();
      });
      
      img.src = url;
      
      // 设置超时
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      await completer.future;
    } catch (e) {
      print('_preloadImage error for $url: $e');
    }
  }

  /// 设置资源缓存策略
  static void _setupResourceCaching() {
    if (!kIsWeb) return;
    
    try {
      // 设置缓存头（通过meta标签）
      final meta = html.document.createElement('meta') as html.MetaElement;
      meta.httpEquiv = 'Cache-Control';
      meta.content = 'public, max-age=31536000'; // 1年缓存
      final head = (html.document as dynamic).head;
      if (head != null) {
        head.appendChild(meta);
      }
      
      // 启用Service Worker（如果可用）
      if (js.context.hasProperty('navigator') && 
          js.context['navigator'].hasProperty('serviceWorker')) {
        // 这里可以注册Service Worker来实现更精细的缓存控制
        print('Service Worker available for advanced caching');
      }
      
    } catch (e) {
      print('_setupResourceCaching error: $e');
    }
  }

  /// 优化渲染性能
  static void _optimizeRendering() {
    if (!kIsWeb) return;
    
    try {
      // 启用硬件加速
      final style = html.document.createElement('style') as html.StyleElement;
      style.text = '''
        /* 硬件加速优化 */
        flutter-view, flt-glass-pane {
          transform: translateZ(0);
          will-change: transform;
        }
        
        /* 减少重绘 */
        .game-container {
          contain: layout style paint;
        }
        
        /* 优化滚动性能 */
        .scrollable {
          -webkit-overflow-scrolling: touch;
          overflow-scrolling: touch;
        }
        
        /* 减少合成层 */
        .static-content {
          will-change: auto;
        }
      ''';
      final head = (html.document as dynamic).head;
      if (head != null) {
        head.appendChild(style);
      }
      
    } catch (e) {
      print('_optimizeRendering error: $e');
    }
  }

  /// 监控性能指标
  static void _monitorPerformance() {
    if (!kIsWeb) return;
    
    try {
      // 监控页面加载性能
      html.window.addEventListener('load', (_) {
        _logPerformanceMetrics();
      });
      
      // 监控内存使用（如果可用）
      if (js.context.hasProperty('performance') && 
          js.context['performance'].hasProperty('memory')) {
        Timer.periodic(const Duration(minutes: 1), (_) {
          _logMemoryUsage();
        });
      }
      
    } catch (e) {
      print('_monitorPerformance error: $e');
    }
  }

  /// 记录性能指标
  static void _logPerformanceMetrics() {
    if (!kIsWeb) return;
    
    try {
      final performance = js.context['performance'];
      if (performance != null) {
        final navigation = performance['timing'];
        if (navigation != null) {
          final loadTime = navigation['loadEventEnd'] - navigation['navigationStart'];
          final domReady = navigation['domContentLoadedEventEnd'] - navigation['navigationStart'];
          
          print('Performance metrics:');
          print('  - Page load time: ${loadTime}ms');
          print('  - DOM ready time: ${domReady}ms');
        }
      }
    } catch (e) {
      print('_logPerformanceMetrics error: $e');
    }
  }

  /// 记录内存使用情况
  static void _logMemoryUsage() {
    if (!kIsWeb) return;
    
    try {
      final performance = js.context['performance'];
      if (performance != null && performance.hasProperty('memory')) {
        final memory = performance['memory'];
        final used = memory['usedJSHeapSize'];
        final total = memory['totalJSHeapSize'];
        final limit = memory['jsHeapSizeLimit'];
        
        print('Memory usage:');
        print('  - Used: ${(used / 1024 / 1024).toStringAsFixed(2)}MB');
        print('  - Total: ${(total / 1024 / 1024).toStringAsFixed(2)}MB');
        print('  - Limit: ${(limit / 1024 / 1024).toStringAsFixed(2)}MB');
        
        // 如果内存使用超过80%，触发垃圾回收建议
        if (used / limit > 0.8) {
          print('⚠️ High memory usage detected, consider cleanup');
          _suggestMemoryCleanup();
        }
      }
    } catch (e) {
      print('_logMemoryUsage error: $e');
    }
  }

  /// 建议内存清理
  static void _suggestMemoryCleanup() {
    try {
      // 清理缓存
      _cache.clear();
      
      // 强制垃圾回收（如果可用）
      if (js.context.hasProperty('gc')) {
        js.context.callMethod('gc');
      }
      
      print('Memory cleanup suggested');
    } catch (e) {
      print('_suggestMemoryCleanup error: $e');
    }
  }

  /// 懒加载图片组件
  static Widget lazyImage({
    required String src,
    String? placeholder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return FutureBuilder<void>(
      future: _preloadImage(src),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Image.network(
            src,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
            },
          );
        } else {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: placeholder != null
                ? Image.asset(placeholder, fit: fit)
                : const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  /// 缓存数据
  static void cacheData(String key, dynamic data) {
    _cache[key] = data;
  }

  /// 获取缓存数据
  static T? getCachedData<T>(String key) {
    return _cache[key] as T?;
  }

  /// 清理缓存
  static void clearCache() {
    _cache.clear();
  }

  /// 获取性能统计信息
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'initialized': _initialized,
      'cacheSize': _cache.length,
      'preloadedImages': _preloadedImages.length,
      'platform': kIsWeb ? 'web' : 'native',
    };
  }

  /// 优化Flutter Widget树
  static Widget optimizeWidget(Widget child) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// 延迟执行任务
  static Future<void> deferTask(VoidCallback task, {Duration delay = const Duration(milliseconds: 100)}) async {
    await Future.delayed(delay);
    task();
  }
}
