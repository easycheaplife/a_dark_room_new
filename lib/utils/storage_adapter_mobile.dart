import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger.dart';
import 'dart:convert';

/// 移动端存储适配器
/// 使用SharedPreferences实现跨平台存储
class StorageAdapterMobile {
  static SharedPreferences? _prefs;
  
  /// 初始化存储
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Logger.info('移动端存储适配器初始化成功');
    } catch (e) {
      Logger.error('移动端存储适配器初始化失败: $e');
    }
  }

  /// 存储字符串
  static Future<void> setString(String key, String value) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setString(key, value);
      
      if (kDebugMode) {
        Logger.info('存储字符串: $key = $value');
      }
    } catch (e) {
      Logger.error('存储字符串失败 $key: $e');
    }
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getString(key);
      
      if (kDebugMode) {
        Logger.info('获取字符串: $key = $value');
      }
      
      return value;
    } catch (e) {
      Logger.error('获取字符串失败 $key: $e');
      return null;
    }
  }

  /// 存储整数
  static Future<void> setInt(String key, int value) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setInt(key, value);
      
      if (kDebugMode) {
        Logger.info('存储整数: $key = $value');
      }
    } catch (e) {
      Logger.error('存储整数失败 $key: $e');
    }
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getInt(key);
      
      if (kDebugMode) {
        Logger.info('获取整数: $key = $value');
      }
      
      return value;
    } catch (e) {
      Logger.error('获取整数失败 $key: $e');
      return null;
    }
  }

  /// 存储布尔值
  static Future<void> setBool(String key, bool value) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setBool(key, value);
      
      if (kDebugMode) {
        Logger.info('存储布尔值: $key = $value');
      }
    } catch (e) {
      Logger.error('存储布尔值失败 $key: $e');
    }
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getBool(key);
      
      if (kDebugMode) {
        Logger.info('获取布尔值: $key = $value');
      }
      
      return value;
    } catch (e) {
      Logger.error('获取布尔值失败 $key: $e');
      return null;
    }
  }

  /// 存储双精度浮点数
  static Future<void> setDouble(String key, double value) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setDouble(key, value);
      
      if (kDebugMode) {
        Logger.info('存储双精度浮点数: $key = $value');
      }
    } catch (e) {
      Logger.error('存储双精度浮点数失败 $key: $e');
    }
  }

  /// 获取双精度浮点数
  static Future<double?> getDouble(String key) async {
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getDouble(key);
      
      if (kDebugMode) {
        Logger.info('获取双精度浮点数: $key = $value');
      }
      
      return value;
    } catch (e) {
      Logger.error('获取双精度浮点数失败 $key: $e');
      return null;
    }
  }

  /// 存储JSON对象
  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await setString(key, jsonString);
      
      if (kDebugMode) {
        Logger.info('存储JSON对象: $key');
      }
    } catch (e) {
      Logger.error('存储JSON对象失败 $key: $e');
    }
  }

  /// 获取JSON对象
  static Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      
      final value = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (kDebugMode) {
        Logger.info('获取JSON对象: $key');
      }
      
      return value;
    } catch (e) {
      Logger.error('获取JSON对象失败 $key: $e');
      return null;
    }
  }

  /// 删除键值
  static Future<void> remove(String key) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.remove(key);
      
      if (kDebugMode) {
        Logger.info('删除键值: $key');
      }
    } catch (e) {
      Logger.error('删除键值失败 $key: $e');
    }
  }

  /// 清空所有数据
  static Future<void> clear() async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.clear();
      
      Logger.info('清空所有存储数据');
    } catch (e) {
      Logger.error('清空存储数据失败: $e');
    }
  }

  /// 获取所有键
  static Future<Set<String>> getKeys() async {
    try {
      if (_prefs == null) await initialize();
      final keys = _prefs?.getKeys() ?? <String>{};
      
      if (kDebugMode) {
        Logger.info('获取所有键: ${keys.length}个');
      }
      
      return keys;
    } catch (e) {
      Logger.error('获取所有键失败: $e');
      return <String>{};
    }
  }

  /// 检查键是否存在
  static Future<bool> containsKey(String key) async {
    try {
      if (_prefs == null) await initialize();
      final exists = _prefs?.containsKey(key) ?? false;
      
      if (kDebugMode) {
        Logger.info('检查键是否存在: $key = $exists');
      }
      
      return exists;
    } catch (e) {
      Logger.error('检查键是否存在失败 $key: $e');
      return false;
    }
  }

  /// 获取存储使用情况
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final keys = await getKeys();
      int totalSize = 0;
      
      for (String key in keys) {
        final value = await getString(key) ?? '';
        totalSize += key.length + value.length;
      }
      
      return {
        'keyCount': keys.length,
        'totalSize': totalSize,
        'platform': 'mobile',
        'storageType': 'SharedPreferences',
      };
    } catch (e) {
      Logger.error('获取存储使用情况失败: $e');
      return {
        'keyCount': 0,
        'totalSize': 0,
        'platform': 'mobile',
        'storageType': 'SharedPreferences',
        'error': e.toString(),
      };
    }
  }

  /// 测试存储功能
  static Future<bool> testStorage() async {
    try {
      const testKey = 'storage_test_key';
      const testValue = 'storage_test_value';
      
      await setString(testKey, testValue);
      final retrievedValue = await getString(testKey);
      await remove(testKey);
      
      final success = retrievedValue == testValue;
      Logger.info('存储功能测试: ${success ? '成功' : '失败'}');
      
      return success;
    } catch (e) {
      Logger.error('存储功能测试失败: $e');
      return false;
    }
  }
}
