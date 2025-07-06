import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'web_storage.dart';
import '../core/logger.dart';

/// 存储适配器
/// 统一管理不同平台的存储方案，自动选择最适合的存储方式
class StorageAdapter {
  static bool _initialized = false;
  static bool _useWebStorage = false;
  
  /// 初始化存储适配器
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 在Web平台优先使用WebStorage
      if (kIsWeb) {
        await WebStorage.initialize();
        _useWebStorage = WebStorage.isStorageAvailable();
        
        if (_useWebStorage) {
          Logger.info('📦 Using WebStorage for web platform');
        } else {
          Logger.info('⚠️ WebStorage not available, falling back to SharedPreferences');
        }
      }
      
      // 如果不使用WebStorage，初始化SharedPreferences
      if (!_useWebStorage) {
        // SharedPreferences会在首次使用时自动初始化
        Logger.info('📦 Using SharedPreferences for storage');
      }
      
      _initialized = true;
      Logger.info('✅ StorageAdapter initialized successfully');
    } catch (e) {
      Logger.error('❌ Failed to initialize StorageAdapter: $e');
    }
  }

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.setString(key, value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(key, value);
      }
    } catch (e) {
      Logger.error('StorageAdapter.setString error for key $key: $e');
      return false;
    }
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getString(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.getString error for key $key: $e');
      return null;
    }
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.setInt(key, value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setInt(key, value);
      }
    } catch (e) {
      Logger.error('StorageAdapter.setInt error for key $key: $e');
      return false;
    }
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getInt(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getInt(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.getInt error for key $key: $e');
      return null;
    }
  }

  /// 存储双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.setDouble(key, value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setDouble(key, value);
      }
    } catch (e) {
      Logger.error('StorageAdapter.setDouble error for key $key: $e');
      return false;
    }
  }

  /// 获取双精度浮点数
  static Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getDouble(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getDouble(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.getDouble error for key $key: $e');
      return null;
    }
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.setBool(key, value);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setBool(key, value);
      }
    } catch (e) {
      Logger.error('StorageAdapter.setBool error for key $key: $e');
      return false;
    }
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getBool(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.getBool error for key $key: $e');
      return null;
    }
  }

  /// 存储JSON对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.setJson(key, value);
      } else {
        // SharedPreferences不直接支持JSON，转换为字符串
        final jsonString = jsonEncode(value);
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(key, jsonString);
      }
    } catch (e) {
      Logger.error('StorageAdapter.setJson error for key $key: $e');
      return false;
    }
  }

  /// 获取JSON对象
  static Future<Map<String, dynamic>?> getJson(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getJson(key);
      } else {
        // SharedPreferences不直接支持JSON，从字符串解析
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(key);
        if (jsonString == null) return null;
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      Logger.error('StorageAdapter.getJson error for key $key: $e');
      return null;
    }
  }

  /// 删除键值对
  static Future<bool> remove(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.remove(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.remove(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.remove error for key $key: $e');
      return false;
    }
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.clear();
      } else {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.clear();
      }
    } catch (e) {
      Logger.error('StorageAdapter.clear error: $e');
      return false;
    }
  }

  /// 获取所有键
  static Future<Set<String>> getKeys() async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.getKeys();
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getKeys();
      }
    } catch (e) {
      Logger.error('StorageAdapter.getKeys error: $e');
      return <String>{};
    }
  }

  /// 检查键是否存在
  static Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        return await WebStorage.containsKey(key);
      } else {
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(key);
      }
    } catch (e) {
      Logger.error('StorageAdapter.containsKey error for key $key: $e');
      return false;
    }
  }

  /// 获取存储信息
  static Future<Map<String, dynamic>> getStorageInfo() async {
    await _ensureInitialized();
    
    try {
      if (_useWebStorage) {
        final webInfo = await WebStorage.getStorageInfo();
        return {
          ...webInfo,
          'adapter': 'WebStorage',
        };
      } else {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        return {
          'platform': 'native',
          'adapter': 'SharedPreferences',
          'keyCount': keys.length,
          'keys': keys.toList(),
          'isAvailable': true,
        };
      }
    } catch (e) {
      Logger.error('StorageAdapter.getStorageInfo error: $e');
      return {
        'error': e.toString(),
        'adapter': _useWebStorage ? 'WebStorage' : 'SharedPreferences',
      };
    }
  }

  /// 确保适配器已初始化
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// 获取适配器状态
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'useWebStorage': _useWebStorage,
      'platform': kIsWeb ? 'web' : 'native',
    };
  }

  /// 测试存储功能
  static Future<bool> testStorage() async {
    try {
      const testKey = '__storage_test__';
      const testValue = 'test_value';
      
      // 测试字符串存储
      final setResult = await setString(testKey, testValue);
      if (!setResult) return false;
      
      final getValue = await getString(testKey);
      if (getValue != testValue) return false;
      
      // 清理测试数据
      await remove(testKey);
      
      Logger.info('✅ Storage test passed');
      return true;
    } catch (e) {
      Logger.error('❌ Storage test failed: $e');
      return false;
    }
  }
}
