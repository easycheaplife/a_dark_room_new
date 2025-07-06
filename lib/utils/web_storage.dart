import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 条件导入：只在Web平台导入Web专用库
import 'dart:html' as html;
import 'dart:convert';

/// Web存储工具类
/// 提供跨平台的存储解决方案，在Web平台使用localStorage，其他平台使用SharedPreferences
class WebStorage {
  static SharedPreferences? _prefs;
  
  /// 初始化存储
  static Future<void> initialize() async {
    if (!kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    try {
      if (kIsWeb) {
        // Web平台使用localStorage
        html.window.localStorage[key] = value;
        return true;
      } else {
        // 其他平台使用SharedPreferences
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.setString(key, value);
      }
    } catch (e) {
      print('WebStorage.setString error: $e');
      return false;
    }
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    try {
      if (kIsWeb) {
        // Web平台使用localStorage
        return html.window.localStorage[key];
      } else {
        // 其他平台使用SharedPreferences
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getString(key);
      }
    } catch (e) {
      print('WebStorage.getString error: $e');
      return null;
    }
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    return await setString(key, value.toString());
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return int.tryParse(stringValue);
  }

  /// 存储双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    return await setString(key, value.toString());
  }

  /// 获取双精度浮点数
  static Future<double?> getDouble(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return double.tryParse(stringValue);
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    return await setString(key, value.toString());
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return stringValue.toLowerCase() == 'true';
  }

  /// 存储JSON对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      print('WebStorage.setJson error: $e');
      return false;
    }
  }

  /// 获取JSON对象
  static Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('WebStorage.getJson error: $e');
      return null;
    }
  }

  /// 删除键值对
  static Future<bool> remove(String key) async {
    try {
      if (kIsWeb) {
        // Web平台使用localStorage
        html.window.localStorage.remove(key);
        return true;
      } else {
        // 其他平台使用SharedPreferences
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.remove(key);
      }
    } catch (e) {
      print('WebStorage.remove error: $e');
      return false;
    }
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    try {
      if (kIsWeb) {
        // Web平台清空localStorage
        html.window.localStorage.clear();
        return true;
      } else {
        // 其他平台清空SharedPreferences
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.clear();
      }
    } catch (e) {
      print('WebStorage.clear error: $e');
      return false;
    }
  }

  /// 获取所有键
  static Future<Set<String>> getKeys() async {
    try {
      if (kIsWeb) {
        // Web平台获取localStorage的所有键
        return html.window.localStorage.keys.toSet();
      } else {
        // 其他平台获取SharedPreferences的所有键
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getKeys();
      }
    } catch (e) {
      print('WebStorage.getKeys error: $e');
      return <String>{};
    }
  }

  /// 检查键是否存在
  static Future<bool> containsKey(String key) async {
    try {
      if (kIsWeb) {
        // Web平台检查localStorage
        return html.window.localStorage.containsKey(key);
      } else {
        // 其他平台检查SharedPreferences
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.containsKey(key);
      }
    } catch (e) {
      print('WebStorage.containsKey error: $e');
      return false;
    }
  }

  /// 获取存储大小（仅Web平台支持）
  static int getStorageSize() {
    if (!kIsWeb) return 0;
    
    try {
      int totalSize = 0;
      for (String key in html.window.localStorage.keys) {
        final value = html.window.localStorage[key] ?? '';
        totalSize += key.length + value.length;
      }
      return totalSize;
    } catch (e) {
      print('WebStorage.getStorageSize error: $e');
      return 0;
    }
  }

  /// 检查存储是否可用
  static bool isStorageAvailable() {
    if (!kIsWeb) return true; // 非Web平台默认可用
    
    try {
      // 测试localStorage是否可用
      const testKey = '__storage_test__';
      html.window.localStorage[testKey] = 'test';
      html.window.localStorage.remove(testKey);
      return true;
    } catch (e) {
      print('WebStorage.isStorageAvailable error: $e');
      return false;
    }
  }

  /// 获取存储信息
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final keys = await getKeys();
    return {
      'platform': kIsWeb ? 'web' : 'native',
      'keyCount': keys.length,
      'keys': keys.toList(),
      'storageSize': kIsWeb ? getStorageSize() : -1,
      'isAvailable': isStorageAvailable(),
    };
  }
}
