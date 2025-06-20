import 'package:flutter/foundation.dart';
import 'localization.dart';

class Logger {
  // 获取当前语言设置
  static String get _currentLanguage {
    try {
      return Localization().currentLanguage;
    } catch (e) {
      return 'zh'; // 默认中文
    }
  }

  // 本地化日志消息
  static String _localizeMessage(String message) {
    try {
      final localization = Localization();

      // 定义日志消息的本地化映射
      final logMessages = {
        'zh': {
          'Game loading successful': '游戏加载成功',
          'Error loading game': '加载游戏时出错',
          'Game save state cleared': '游戏保存状态已清除',
          'Error deleting save': '删除保存时出错',
          'Archive import successful': '存档导入成功',
          'Archive import failed': '存档导入失败',
          'Error importing archive': '导入存档时出错',
          'Player died': '玩家死亡',
          'Returned to dark room': '返回小黑屋',
          'Moving': '移动',
          'Triggered village event': '触发村庄事件',
          'Found executioner device': '发现执行者装置',
          'Equipment status saved': '装备状态已保存',
          'Initializing World module': '初始化世界模块',
          'Setting world feature as unlocked': '设置世界功能为已解锁',
          'Switching to World module': '切换到世界模块',
          'embark() completed': 'embark() 完成',
          'embark() error': 'embark() 错误',
          'Error stack': '错误堆栈',
          'Cannot save empty state': '无法保存空状态',
          'Saving data length': '保存数据长度',
          'Saving data preview': '保存数据预览',
          'Error loading game state': '加载游戏错误',
          'Upgrading save to': '升级存档到',
          'Export game state failed': '导出游戏状态失败',
          'Import data format invalid': '导入数据格式无效',
          'canEmbark': '可以出发',
          'Embark button clicked': '出发按钮被点击',
          'mapSearch: Invalid map data': 'mapSearch: 地图数据无效',
          'mapSearch error': 'mapSearch错误',
          'move() - state is null, cannot move': 'move() - state为null，无法移动',
          'move() - Player is dead, cannot move': 'move() - 玩家已死亡，无法移动',
          'doSpace() call completed': 'doSpace()调用完成',
          'Error clearing equipment': '清空装备时出错',
        },
        'en': {
          '游戏加载成功': 'Game loading successful',
          '加载游戏时出错': 'Error loading game',
          '游戏保存状态已清除': 'Game save state cleared',
          '删除保存时出错': 'Error deleting save',
          '存档导入成功': 'Archive import successful',
          '存档导入失败': 'Archive import failed',
          '导入存档时出错': 'Error importing archive',
          '玩家死亡': 'Player died',
          '返回小黑屋': 'Returned to dark room',
          '移动': 'Moving',
          '触发村庄事件': 'Triggered village event',
          '发现执行者装置': 'Found executioner device',
          '装备状态已保存': 'Equipment status saved',
          '初始化世界模块': 'Initializing World module',
          '设置世界功能为已解锁': 'Setting world feature as unlocked',
          '切换到世界模块': 'Switching to World module',
          'embark() 完成': 'embark() completed',
          'embark() 错误': 'embark() error',
          '错误堆栈': 'Error stack',
          '无法保存空状态': 'Cannot save empty state',
          '保存数据长度': 'Saving data length',
          '保存数据预览': 'Saving data preview',
          '加载游戏错误': 'Error loading game',
          '升级存档到': 'Upgrading save to',
          '导出游戏状态失败': 'Export game state failed',
          '导入数据格式无效': 'Import data format invalid',
          '可以出发': 'canEmbark',
          '出发按钮被点击': 'Embark button clicked',
          'mapSearch: 地图数据无效': 'mapSearch: Invalid map data',
          'mapSearch错误': 'mapSearch error',
          'move() - state为null，无法移动': 'move() - state is null, cannot move',
          'move() - 玩家已死亡，无法移动': 'move() - Player is dead, cannot move',
          'doSpace()调用完成': 'doSpace() call completed',
          '清空装备时出错': 'Error clearing equipment',
        }
      };

      // 获取当前语言的消息映射
      final currentLangMessages = logMessages[_currentLanguage] ?? {};

      // 查找本地化消息
      String localizedMessage = message;

      // 首先尝试直接匹配
      if (currentLangMessages.containsKey(message)) {
        localizedMessage = currentLangMessages[message]!;
      } else {
        // 尝试部分匹配（去掉表情符号和特殊字符）
        final cleanMessage = message
            .replaceAll(RegExp(r'[🔍✅❌⚠️🎮💾🏭🪵🔥🎭💀🏠🌲🌍🎒🎯🚶🔮]'), '')
            .trim();
        if (currentLangMessages.containsKey(cleanMessage)) {
          // 保留原始表情符号，只替换文字部分
          final emojis = RegExp(r'[🔍✅❌⚠️🎮💾🏭🪵🔥🎭💀🏠🌲🌍🎒🎯🚶🔮]')
              .allMatches(message)
              .map((m) => m.group(0))
              .join(' ');
          localizedMessage =
              '$emojis ${currentLangMessages[cleanMessage]!}'.trim();
        }
      }

      return localizedMessage;
    } catch (e) {
      return message; // 如果本地化失败，返回原始消息
    }
  }

  // 根据语言过滤日志
  static bool _shouldShowLog(String message) {
    if (_currentLanguage == 'zh') {
      // 中文模式下，过滤掉英文日志
      // 检查消息是否包含英文字符（排除数字、符号等）
      final englishPattern = RegExp(r'[a-zA-Z]');
      final chinesePattern = RegExp(r'[\u4e00-\u9fff]');

      // 如果包含英文字母但不包含中文，则过滤掉
      if (englishPattern.hasMatch(message) &&
          !chinesePattern.hasMatch(message)) {
        // 但保留一些重要的系统日志
        if (message.contains('StateManager') ||
            message.contains('🔍') ||
            message.contains('✅') ||
            message.contains('❌') ||
            message.contains('⚠️') ||
            message.contains('🎮') ||
            message.contains('💾') ||
            message.contains('🏭') ||
            message.contains('🪵') ||
            message.contains('🔥') ||
            message.contains('🎭')) {
          return true;
        }
        return false;
      }
    }
    return true;
  }

  static void log(String message, {String tag = 'INFO'}) {
    if (kDebugMode && _shouldShowLog(message)) {
      final localizedMessage = _localizeMessage(message);
      print('[$tag] $localizedMessage');
    }
  }

  static void error(String message) {
    log(message, tag: 'ERROR');
  }

  static void warn(String message) {
    log(message, tag: 'WARN');
  }

  static void info(String message) {
    log(message, tag: 'INFO');
  }

  static void debug(String message) {
    log(message, tag: 'DEBUG');
  }
}
