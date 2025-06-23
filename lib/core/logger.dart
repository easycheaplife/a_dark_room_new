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

      // 定义消息键映射表
      final messageKeyMap = {
        'Game loading successful': 'logger.game_loading_successful',
        'Error loading game': 'logger.error_loading_game',
        'Game save state cleared': 'logger.game_save_state_cleared',
        'Error deleting save': 'logger.error_deleting_save',
        'Archive import successful': 'logger.archive_import_successful',
        'Archive import failed': 'logger.archive_import_failed',
        'Error importing archive': 'logger.error_importing_archive',
        'Player died': 'logger.player_died',
        'Returned to dark room': 'logger.returned_to_dark_room',
        'Moving': 'logger.moving',
        'Triggered village event': 'logger.triggered_village_event',
        'Found executioner device': 'logger.found_executioner_device',
        'Equipment status saved': 'logger.equipment_status_saved',
        'Initializing World module': 'logger.initializing_world_module',
        'Setting world feature as unlocked':
            'logger.setting_world_feature_as_unlocked',
        'Switching to World module': 'logger.switching_to_world_module',
        'embark() completed': 'logger.embark_completed',
        'embark() error': 'logger.embark_error',
        'Error stack': 'logger.error_stack',
        'Cannot save empty state': 'logger.cannot_save_empty_state',
        'Saving data length': 'logger.saving_data_length',
        'Saving data preview': 'logger.saving_data_preview',
        'Error loading game state': 'logger.error_loading_game_state',
        'Upgrading save to': 'logger.upgrading_save_to',
        'Export game state failed': 'logger.export_game_state_failed',
        'Import data format invalid': 'logger.import_data_format_invalid',
        'canEmbark': 'logger.can_embark',
        'Embark button clicked': 'logger.embark_button_clicked',
        'mapSearch: Invalid map data': 'logger.map_search_invalid_map_data',
        'mapSearch error': 'logger.map_search_error',
        'move() - state is null, cannot move':
            'logger.move_state_is_null_cannot_move',
        'move() - Player is dead, cannot move':
            'logger.move_player_is_dead_cannot_move',
        'doSpace() call completed': 'logger.do_space_call_completed',
        'Error clearing equipment': 'logger.error_clearing_equipment',
      };

      // 查找本地化消息
      String localizedMessage = message;

      // 首先尝试直接匹配
      if (messageKeyMap.containsKey(message)) {
        localizedMessage = localization.translate(messageKeyMap[message]!);
      } else {
        // 尝试部分匹配（去掉表情符号和特殊字符）
        final cleanMessage = message
            .replaceAll(RegExp(r'[🔍✅❌⚠️🎮💾🏭🪵🔥🎭💀🏠🌲🌍🎒🎯🚶🔮]'), '')
            .trim();
        if (messageKeyMap.containsKey(cleanMessage)) {
          // 保留原始表情符号，只替换文字部分
          final emojis = RegExp(r'[🔍✅❌⚠️🎮💾🏭🪵🔥🎭💀🏠🌲🌍🎒🎯🚶🔮]')
              .allMatches(message)
              .map((m) => m.group(0))
              .join(' ');
          final translatedText =
              localization.translate(messageKeyMap[cleanMessage]!);
          localizedMessage = '$emojis $translatedText'.trim();
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
