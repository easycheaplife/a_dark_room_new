import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localization handles translations and language settings
class Localization with ChangeNotifier {
  static final Localization _instance = Localization._internal();
  
  factory Localization() {
    return _instance;
  }
  
  Localization._internal();
  
  // Current language
  String _currentLanguage = 'en';
  
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
  Map<String, String> _translations = {};
  
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
      return savedLang ?? 'en';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved language: $e');
      }
      return 'en';
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
      language = 'en';
    }
    
    try {
      // Load translations from asset file
      String jsonString = await rootBundle.loadString('assets/lang/$language.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      // Convert to string map
      _translations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      
      // Update current language
      _currentLanguage = language;
      await saveLanguage(language);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading language $language: $e');
      }
      
      // Fallback to English if there's an error
      if (language != 'en') {
        await loadLanguage('en');
      } else {
        // If even English fails, use an empty translation map
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
  
  // Translate a string
  String translate(String key, [List<dynamic>? args]) {
    String translation = _translations[key] ?? key;
    
    // Replace placeholders with arguments
    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        translation = translation.replaceAll('{$i}', args[i].toString());
      }
    }
    
    return translation;
  }
  
  // Shorthand for translate
  String call(String key, [List<dynamic>? args]) {
    return translate(key, args);
  }
}
