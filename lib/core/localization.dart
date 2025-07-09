import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localization handles translations and language settings
class Localization with ChangeNotifier {
  static Localization? _instance;

  factory Localization() {
    _instance ??= Localization._internal();
    return _instance!;
  }

  Localization._internal();

  /// 重置单例实例（仅用于测试）
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  // Current language
  String _currentLanguage = 'zh';

  // Available languages
  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
  };

  // Translations
  Map<String, dynamic> _translations = {};

  // Getters
  String get currentLanguage => _currentLanguage;
  Map<String, String> get availableLanguages => _availableLanguages;

  // Initialize localization
  Future<void> init() async {
    await loadLanguage(await getSavedLanguage());
  }

  // Get saved language from preferences
  Future<String> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language');
      return savedLang ?? 'zh';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved language: $e');
      }
      return 'zh';
    }
  }

  // Save language to preferences
  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving language: $e');
      }
    }
  }

  // Load a language
  Future<void> loadLanguage(String language) async {
    if (!_availableLanguages.containsKey(language)) {
      language = 'zh';
    }

    try {
      // Load translations from asset file
      String jsonString =
          await rootBundle.loadString('assets/lang/$language.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Store the full JSON structure
      _translations = jsonMap;

      // Update current language
      _currentLanguage = language;
      await saveLanguage(language);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading language $language: $e');
      }

      // Fallback to Chinese if there's an error
      if (language != 'zh') {
        await loadLanguage('zh');
      } else {
        // If even Chinese fails, use an empty translation map
        _translations = {};
        notifyListeners();
      }
    }
  }

  // Switch to a different language
  Future<void> switchLanguage(String language) async {
    if (language != _currentLanguage) {
      await loadLanguage(language);
    }
  }

  // Translate a string with support for nested keys
  String translate(String key, [List<dynamic>? args]) {
    // First try direct key lookup (for keys that already include category like "fabricator.title")
    dynamic directValue = _getNestedValue(key);
    if (directValue != null && directValue is String) {
      String result = directValue;

      // Replace placeholders with arguments
      if (args != null && args.isNotEmpty) {
        for (int i = 0; i < args.length; i++) {
          result = result.replaceAll('{$i}', args[i].toString());
        }
      }

      return result;
    }

    // Try different translation categories for keys without category prefix
    List<String> categories = [
      'ui.buttons',
      'ui',
      'buildings',
      'crafting',
      'world.crafting',
      'resources',
      'workers',
      'weapons',
      'skills',
      'events',
      'messages',
      'logs',
      'game_states', // 添加游戏状态类别，用于陷阱掉落消息等
      'fabricator' // 添加制造器类别
    ];

    for (String category in categories) {
      String fullKey = '$category.$key';
      dynamic value = _getNestedValue(fullKey);

      if (value != null && value is String) {
        String result = value;

        // Replace placeholders with arguments
        if (args != null && args.isNotEmpty) {
          for (int i = 0; i < args.length; i++) {
            result = result.replaceAll('{$i}', args[i].toString());
          }
        }

        return result;
      }
    }

    // Return the key itself if no translation found
    return key;
  }

  // Translate log messages using the logs category
  String translateLog(String logKey, [List<dynamic>? args]) {
    return translate('logs.$logKey', args);
  }

  // Get nested value from translations using dot notation
  dynamic _getNestedValue(String key) {
    List<String> keys = key.split('.');
    dynamic current = _translations;

    for (String k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }

    return current;
  }

  // Shorthand for translate
  String call(String key, [List<dynamic>? args]) {
    return translate(key, args);
  }

  @override
  void dispose() {
    _translations.clear();
    super.dispose();
  }
}
