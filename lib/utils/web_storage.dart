import '../core/logger.dart';
import 'storage_adapter_mobile.dart';

/// Web存储工具类
/// 提供跨平台的存储解决方案，统一使用SharedPreferences
class WebStorage {
  /// 初始化存储
  static Future<void> initialize() async {
    await StorageAdapterMobile.initialize();
  }

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    try {
      await StorageAdapterMobile.setString(key, value);
      return true;
    } catch (e) {
      Logger.error('WebStorage.setString error: $e');
      return false;
    }
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    try {
      return await StorageAdapterMobile.getString(key);
    } catch (e) {
      Logger.error('WebStorage.getString error: $e');
      return null;
    }
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    try {
      await StorageAdapterMobile.setInt(key, value);
      return true;
    } catch (e) {
      Logger.error('WebStorage.setInt error: $e');
      return false;
    }
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    try {
      return await StorageAdapterMobile.getInt(key);
    } catch (e) {
      Logger.error('WebStorage.getInt error: $e');
      return null;
    }
  }

  /// 存储双精度浮点数
  static Future<bool> setDouble(String key, double value) async {
    try {
      await StorageAdapterMobile.setDouble(key, value);
      return true;
    } catch (e) {
      Logger.error('WebStorage.setDouble error: $e');
      return false;
    }
  }

  /// 获取双精度浮点数
  static Future<double?> getDouble(String key) async {
    try {
      return await StorageAdapterMobile.getDouble(key);
    } catch (e) {
      Logger.error('WebStorage.getDouble error: $e');
      return null;
    }
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    try {
      await StorageAdapterMobile.setBool(key, value);
      return true;
    } catch (e) {
      Logger.error('WebStorage.setBool error: $e');
      return false;
    }
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    try {
      return await StorageAdapterMobile.getBool(key);
    } catch (e) {
      Logger.error('WebStorage.getBool error: $e');
      return null;
    }
  }

  /// 存储JSON对象
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      await StorageAdapterMobile.setJson(key, value);
      return true;
    } catch (e) {
      Logger.error('WebStorage.setJson error: $e');
      return false;
    }
  }

  /// 获取JSON对象
  static Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      return await StorageAdapterMobile.getJson(key);
    } catch (e) {
      Logger.error('WebStorage.getJson error: $e');
      return null;
    }
  }

  /// 删除键值
  static Future<bool> remove(String key) async {
    try {
      await StorageAdapterMobile.remove(key);
      return true;
    } catch (e) {
      Logger.error('WebStorage.remove error: $e');
      return false;
    }
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    try {
      await StorageAdapterMobile.clear();
      return true;
    } catch (e) {
      Logger.error('WebStorage.clear error: $e');
      return false;
    }
  }

  /// 获取所有键
  static Future<Set<String>> getKeys() async {
    try {
      return await StorageAdapterMobile.getKeys();
    } catch (e) {
      Logger.error('WebStorage.getKeys error: $e');
      return <String>{};
    }
  }

  /// 检查键是否存在
  static Future<bool> containsKey(String key) async {
    try {
      return await StorageAdapterMobile.containsKey(key);
    } catch (e) {
      Logger.error('WebStorage.containsKey error: $e');
      return false;
    }
  }

  /// 获取存储使用情况
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      return await StorageAdapterMobile.getStorageInfo();
    } catch (e) {
      Logger.error('WebStorage.getStorageInfo error: $e');
      return {
        'keyCount': 0,
        'totalSize': 0,
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }

  /// 测试存储功能
  static Future<bool> testStorage() async {
    try {
      return await StorageAdapterMobile.testStorage();
    } catch (e) {
      Logger.error('WebStorage.testStorage error: $e');
      return false;
    }
  }
}
