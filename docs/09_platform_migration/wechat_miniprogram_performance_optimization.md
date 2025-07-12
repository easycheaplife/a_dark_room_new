# A Dark Room 微信小程序性能优化指南

## 概述

本指南详细说明如何优化A Dark Room微信小程序内嵌H5的性能和用户体验，确保在微信环境中流畅运行。

## 性能优化策略

### 1. H5页面加载优化

#### 1.1 资源压缩和优化
```bash
# Flutter Web构建优化
flutter build web --release \
  --web-renderer html \
  --dart-define=flutter.web.use_skia=false \
  --dart-define=flutter.web.auto_detect=false \
  --source-maps

# 启用代码分割
flutter build web --release --split-debug-info=build/debug_info
```

#### 1.2 资源预加载
```html
<!-- 在web/index.html中添加关键资源预加载 -->
<link rel="preload" href="main.dart.js" as="script">
<link rel="preload" href="flutter_service_worker.js" as="script">
<link rel="dns-prefetch" href="//fonts.googleapis.com">
```

#### 1.3 缓存策略优化
```javascript
// 在web/flutter_service_worker.js中配置缓存策略
const CACHE_NAME = 'a-dark-room-v1.0.0';
const RESOURCES = {
  // 核心资源，长期缓存
  "main.dart.js": "hash1",
  "flutter.js": "hash2",
  // 游戏资源，可更新缓存
  "assets/images/": "hash3",
  "assets/audio/": "hash4"
};
```

### 2. 微信小程序端优化

#### 2.1 启动性能优化
```javascript
// app.js - 优化启动流程
App({
  onLaunch: function () {
    // 异步初始化非关键功能
    this.initializeAsync();

    // 预加载关键数据
    this.preloadCriticalData();
  },

  initializeAsync: function() {
    // 延迟初始化更新检查
    setTimeout(() => {
      this.checkForUpdate();
    }, 1000);
  },

  preloadCriticalData: function() {
    // 预加载游戏数据
    try {
      const gameData = wx.getStorageSync('gameData');
      if (gameData) {
        this.globalData.gameData = gameData;
      }
    } catch (e) {
      console.error('预加载数据失败:', e);
    }
  }
});
```

#### 2.2 内存管理优化
```javascript
// utils/storage.js - 优化存储管理
class StorageManager {
  // 使用节流避免频繁存储
  static throttledSave = this.throttle(this.saveGameData.bind(this), 1000);

  static throttle(func, delay) {
    let timeoutId;
    let lastExecTime = 0;
    return function (...args) {
      const currentTime = Date.now();

      if (currentTime - lastExecTime > delay) {
        func.apply(this, args);
        lastExecTime = currentTime;
      } else {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => {
          func.apply(this, args);
          lastExecTime = Date.now();
        }, delay - (currentTime - lastExecTime));
      }
    };
  }

  // 压缩存储数据
  static compressData(data) {
    try {
      // 移除不必要的字段
      const compressed = {
        ...data,
        timestamp: Date.now()
      };

      // 删除默认值
      Object.keys(compressed).forEach(key => {
        if (compressed[key] === null || compressed[key] === undefined) {
          delete compressed[key];
        }
      });

      return compressed;
    } catch (e) {
      console.error('数据压缩失败:', e);
      return data;
    }
  }
}
```

### 3. 通信性能优化

#### 3.1 消息批处理
```dart
// lib/utils/miniprogram_adapter.dart - 消息批处理
class MiniProgramAdapter {
  static List<Map<String, dynamic>> _messageQueue = [];
  static Timer? _batchTimer;

  static void postMessage(Map<String, dynamic> data) {
    if (!_isInMiniProgram) return;

    // 添加到消息队列
    _messageQueue.add(data);

    // 设置批处理定时器
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 100), _flushMessageQueue);
  }

  static void _flushMessageQueue() {
    if (_messageQueue.isEmpty) return;

    try {
      // 批量发送消息
      final batchMessage = {
        'type': 'batch',
        'messages': List.from(_messageQueue),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      js.context['wx']['miniProgram'].callMethod('postMessage', [
        js.JsObject.jsify({'data': batchMessage})
      ]);

      _messageQueue.clear();
      Logger.info('批量发送 ${_messageQueue.length} 条消息');
    } catch (e) {
      Logger.error('批量发送消息失败: $e');
    }
  }
}
```

#### 3.2 数据传输优化
```dart
// 优化大数据传输
class DataOptimizer {
  static Map<String, dynamic> optimizeGameData(Map<String, dynamic> data) {
    final optimized = <String, dynamic>{};

    // 只传输变化的数据
    data.forEach((key, value) {
      if (_hasChanged(key, value)) {
        optimized[key] = _compressValue(value);
      }
    });

    return optimized;
  }

  static dynamic _compressValue(dynamic value) {
    if (value is Map) {
      // 压缩嵌套对象
      return value.map((k, v) => MapEntry(k, _compressValue(v)));
    } else if (value is List) {
      // 压缩数组
      return value.map(_compressValue).toList();
    } else if (value is double) {
      // 限制浮点数精度
      return double.parse(value.toStringAsFixed(2));
    }
    return value;
  }
}
```

### 4. 用户体验优化

#### 4.1 加载状态优化
```javascript
// pages/game/game.js - 优化加载体验
Page({
  data: {
    loadingProgress: 0,
    loadingText: '正在初始化...'
  },

  buildH5Url: function() {
    this.updateLoadingProgress(20, '正在构建页面...');

    // 模拟加载进度
    const progressSteps = [
      { progress: 40, text: '正在加载资源...' },
      { progress: 60, text: '正在连接服务器...' },
      { progress: 80, text: '正在初始化游戏...' },
      { progress: 100, text: '加载完成！' }
    ];

    progressSteps.forEach((step, index) => {
      setTimeout(() => {
        this.updateLoadingProgress(step.progress, step.text);
      }, (index + 1) * 500);
    });
  },

  updateLoadingProgress: function(progress, text) {
    this.setData({
      loadingProgress: progress,
      loadingText: text
    });
  }
});
```

#### 4.2 错误处理优化
```javascript
// 智能重试机制
class RetryManager {
  static retryCount = 0;
  static maxRetries = 3;
  static retryDelay = 1000;

  static async retryWithBackoff(operation, context) {
    for (let i = 0; i < this.maxRetries; i++) {
      try {
        return await operation();
      } catch (error) {
        console.error(`操作失败 (尝试 ${i + 1}/${this.maxRetries}):`, error);

        if (i === this.maxRetries - 1) {
          // 最后一次尝试失败，显示用户友好的错误信息
          this.showUserFriendlyError(error, context);
          throw error;
        }

        // 指数退避延迟
        await this.delay(this.retryDelay * Math.pow(2, i));
      }
    }
  }

  static delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  static showUserFriendlyError(error, context) {
    let message = '操作失败，请重试';

    if (error.message.includes('network')) {
      message = '网络连接异常，请检查网络后重试';
    } else if (error.message.includes('timeout')) {
      message = '请求超时，请稍后重试';
    }

    wx.showModal({
      title: '提示',
      content: message,
      showCancel: true,
      confirmText: '重试',
      cancelText: '取消',
      success: (res) => {
        if (res.confirm && context.onRetry) {
          context.onRetry();
        }
      }
    });
  }
}
```

### 5. 内存和性能监控

#### 5.1 性能监控
```dart
// lib/utils/performance_monitor.dart
class PerformanceMonitor {
  static final Map<String, int> _timers = {};
  static final List<Map<String, dynamic>> _metrics = [];

  static void startTimer(String name) {
    _timers[name] = DateTime.now().millisecondsSinceEpoch;
  }

  static void endTimer(String name) {
    final startTime = _timers[name];
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      _recordMetric(name, duration);
      _timers.remove(name);
    }
  }

  static void _recordMetric(String name, int duration) {
    _metrics.add({
      'name': name,
      'duration': duration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // 保持最近100条记录
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    // 如果性能异常，发送到小程序
    if (duration > 5000) { // 超过5秒
      MiniProgramAdapter.postMessage({
        'type': 'performanceWarning',
        'metric': name,
        'duration': duration,
      });
    }
  }

  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    // 计算平均性能
    final groupedMetrics = <String, List<int>>{};
    for (final metric in _metrics) {
      final name = metric['name'] as String;
      final duration = metric['duration'] as int;
      groupedMetrics.putIfAbsent(name, () => []).add(duration);
    }

    groupedMetrics.forEach((name, durations) {
      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final max = durations.reduce((a, b) => a > b ? a : b);
      final min = durations.reduce((a, b) => a < b ? a : b);

      report[name] = {
        'average': avg.round(),
        'max': max,
        'min': min,
        'count': durations.length,
      };
    });

    return report;
  }
}
```

#### 5.2 内存监控
```javascript
// utils/memory_monitor.js
class MemoryMonitor {
  static startMonitoring() {
    // 每30秒检查一次内存使用
    setInterval(() => {
      this.checkMemoryUsage();
    }, 30000);
  }

  static checkMemoryUsage() {
    try {
      const storageInfo = wx.getStorageInfoSync();
      const memoryWarningThreshold = 8 * 1024 * 1024; // 8MB

      if (storageInfo.currentSize > memoryWarningThreshold) {
        console.warn('存储使用量过高:', storageInfo);
        this.cleanupStorage();
      }
    } catch (e) {
      console.error('内存检查失败:', e);
    }
  }

  static cleanupStorage() {
    try {
      // 清理过期的备份数据
      const info = wx.getStorageInfoSync();
      const backupKeys = info.keys.filter(key => key.startsWith('gameDataBackup_'));

      // 只保留最新的2个备份
      backupKeys.sort((a, b) => {
        const timeA = parseInt(a.split('_')[1]);
        const timeB = parseInt(b.split('_')[1]);
        return timeB - timeA;
      });

      for (let i = 2; i < backupKeys.length; i++) {
        wx.removeStorageSync(backupKeys[i]);
        console.log('清理过期备份:', backupKeys[i]);
      }
    } catch (e) {
      console.error('存储清理失败:', e);
    }
  }
}
```

## 性能基准测试

### 1. 加载性能目标
- 首屏加载时间：< 3秒
- 交互响应时间：< 100ms
- 内存使用：< 50MB
- 存储使用：< 10MB

### 2. 测试方法
```javascript
// 性能测试脚本
const performanceTest = {
  async testLoadingTime() {
    const startTime = Date.now();

    // 模拟页面加载
    await this.loadGamePage();

    const loadTime = Date.now() - startTime;
    console.log('页面加载时间:', loadTime, 'ms');

    return loadTime < 3000; // 3秒内
  },

  async testMemoryUsage() {
    const initialMemory = this.getMemoryUsage();

    // 模拟游戏操作
    await this.simulateGameplay();

    const finalMemory = this.getMemoryUsage();
    const memoryIncrease = finalMemory - initialMemory;

    console.log('内存增长:', memoryIncrease, 'MB');

    return memoryIncrease < 20; // 20MB内
  }
};
```

## 部署优化建议

### 1. CDN配置
```nginx
# nginx配置示例
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";

    # 启用Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

### 2. 服务器优化
```bash
# 启用HTTP/2
server {
    listen 443 ssl http2;

    # 启用服务器推送
    location / {
        http2_push /main.dart.js;
        http2_push /flutter.js;
    }
}
```

通过这些优化措施，可以显著提升微信小程序内嵌H5的性能和用户体验。