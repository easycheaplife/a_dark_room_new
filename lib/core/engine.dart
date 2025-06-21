import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state_manager.dart';
import 'audio_engine.dart';
import 'notifications.dart';
import 'localization.dart';
import '../modules/room.dart';
import '../modules/outside.dart';
import '../modules/path.dart';
import '../modules/fabricator.dart';
import '../modules/ship.dart';
import '../modules/events.dart';
import 'logger.dart';

/// Engine是游戏的核心引擎，负责协调所有游戏系统
class Engine with ChangeNotifier {
  static final Engine _instance = Engine._internal();

  factory Engine() {
    return _instance;
  }

  Engine._internal();

  // 常量
  static const String siteUrl = "http://adarkroom.doublespeakgames.com";
  static const double version = 1.3;
  static const int maxStore = 99999999999999;
  static const int saveDisplay = 30 * 1000;

  // 游戏状态
  bool gameOver = false;
  bool keyPressed = false;
  bool keyLock = false;
  bool tabNavigation = true;
  bool restoreNavigation = false;

  // 获取本地化的技能信息
  Map<String, String> getPerk(String perkKey) {
    final localization = Localization();
    final keyMap = {
      'martial artist': 'martial_artist',
      'unarmed master': 'unarmed_master',
      'slow metabolism': 'slow_metabolism',
      'desert rat': 'desert_rat',
    };

    final localizedKey = keyMap[perkKey] ?? perkKey;

    return {
      'name': localization.translate('events.perks.$localizedKey.name'),
      'desc': localization.translate('events.perks.$localizedKey.desc'),
      'notify': localization.translate('events.perks.$localizedKey.notify'),
    };
  }

  // 选项
  Map<String, dynamic> options = {
    'debug': false,
    'log': false,
    'dropbox': false,
    'doubleTime': false,
  };

  // 活动模块
  dynamic activeModule;

  // 保存计时器
  Timer? _saveTimer;
  DateTime? _lastNotify;

  // 初始化引擎
  Future<void> init({Map<String, dynamic>? options}) async {
    this.options = {...this.options, ...?options};

    // 初始化状态管理器
    final sm = StateManager();

    // 先加载保存的游戏状态，然后初始化StateManager
    await sm.loadGame();
    sm.init();

    // 初始化音频引擎
    await AudioEngine().init();

    // 初始化通知
    NotificationManager().init();

    // 初始化本地化
    await Localization().init();

    // 初始化模块
    await Room().init();

    // 初始化事件系统
    Events().init();
    Logger.info('🎭 Events module initialized');

    // 检查是否应该初始化外部 - 只有在森林已解锁时才初始化
    if (sm.get('features.location.outside') == true) {
      Logger.info('🌲 Forest already unlocked, initializing Outside module');
      Outside().init();
    }

    // 检查是否应该初始化路径
    if (sm.get('stores.compass', true) != null &&
        sm.get('stores.compass', true) > 0) {
      Path().init();
    }

    // 检查是否应该初始化制造机
    if (sm.get('features.location.fabricator', true) == true) {
      Fabricator().init();
    }

    // 检查是否应该初始化飞船
    if (sm.get('features.location.spaceShip', true) == true) {
      Ship().init();
    }

    // 设置保存计时器
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) => saveGame());

    // 启动自动保存功能
    sm.startAutoSave();

    // 设置初始模块
    travelTo(Room());

    // 根据保存的设置设置音频
    toggleVolume(sm.get('config.soundOn', true) == true);

    // 开始收集收入
    Timer.periodic(const Duration(seconds: 1), (_) => sm.collectIncome());

    notifyListeners();
  }

  // 保存游戏
  Future<void> saveGame() async {
    await StateManager().saveGame();

    if (_lastNotify == null ||
        DateTime.now().difference(_lastNotify!).inMilliseconds > saveDisplay) {
      // 显示保存通知
      _lastNotify = DateTime.now();
      // 在原始游戏中，这会显示"已保存"消息的动画
    }
  }

  // 加载游戏
  Future<void> loadGame() async {
    try {
      await StateManager().loadGame();
      if (kDebugMode) {
        Logger.info('Game loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error loading game: $e');
      }

      // 初始化新游戏状态
      final sm = StateManager();
      sm.set('version', version);

      // 记录新游戏事件
      event('progress', 'new game');
    }
  }

  // 删除保存并重新开始
  Future<void> deleteSave({bool noReload = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Logger.info('🗑️ Game save state cleared');

      if (!noReload) {
        // 在Web上下文中，这会重新加载页面
        // 在Flutter中，我们将重新初始化游戏
        await init();
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error deleting save: $e');
      }
    }
  }

  // 临时方法：清除保存状态用于调试
  Future<void> clearSaveForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Logger.info('🗑️ Debug: Game save state cleared');
  }

  // 前往不同的模块
  void travelTo(dynamic module) {
    if (activeModule == module) {
      return;
    }

    // 更新活动模块
    activeModule = module;

    // 调用新模块的onArrival
    module.onArrival(1);

    // 打印模块的通知
    NotificationManager().printQueue(module.name);

    notifyListeners();
  }

  // 切换游戏音量
  Future<void> toggleVolume([bool? enabled]) async {
    final sm = StateManager();

    enabled ??= !(sm.get('config.soundOn', true) == true);

    sm.set('config.soundOn', enabled);

    if (enabled) {
      await AudioEngine().setMasterVolume(1.0);
    } else {
      await AudioEngine().setMasterVolume(0.0);
    }

    notifyListeners();
  }

  // 切换关灯模式
  void turnLightsOff() {
    final sm = StateManager();
    final lightsOff = sm.get('config.lightsOff', true) == true;

    sm.set('config.lightsOff', !lightsOff);

    notifyListeners();
  }

  // 切换超级模式（双倍速度）
  void triggerHyperMode() {
    options['doubleTime'] = !options['doubleTime'];

    StateManager().set('config.hyperMode', options['doubleTime']);

    notifyListeners();
  }

  // 记录事件
  void event(String category, String action) {
    // 在原始游戏中，这会发送分析
    // 现在，我们只在调试模式下记录
    if (kDebugMode) {
      Logger.info('Event: $category - $action');
    }
  }

  // 获取收入消息
  String getIncomeMsg(num value, int delay) {
    final prefix = value > 0 ? "+" : "";
    return "$prefix$value per ${delay}s";
  }

  // 设置间隔，支持双倍时间
  Timer setInterval(Function callback, int interval,
      {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      interval = (interval / 2).round();
    }

    return Timer.periodic(Duration(milliseconds: interval), (_) => callback());
  }

  // 设置超时，支持双倍时间
  Timer setTimeout(Function callback, int timeout, {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      timeout = (timeout / 2).round();
    }

    return Timer(Duration(milliseconds: timeout), () => callback());
  }

  // 处理按键按下事件
  void keyDown(KeyEvent event) {
    if (!keyPressed && !keyLock) {
      keyPressed = true;

      if (activeModule != null && activeModule.keyDown != null) {
        activeModule.keyDown(event);
      }
    }
  }

  // 处理按键释放事件
  void keyUp(KeyEvent event) {
    keyPressed = false;

    if (activeModule != null && activeModule.keyUp != null) {
      activeModule.keyUp(event);
    } else {
      // 处理导航键
      // 这将根据键码实现
    }

    if (restoreNavigation) {
      tabNavigation = true;
      restoreNavigation = false;
    }
  }

  // 导出/导入游戏存档
  Future<void> exportImport() async {
    // 在Flutter中，我们可以使用Events系统来显示导出/导入对话框
    // 这里先提供基础的导出/导入功能
  }

  // 生成Base64编码的存档 - 兼容原游戏格式
  Future<String> generateExport64() async {
    // 使用StateManager的导出功能，确保格式兼容
    final gameStateJson = StateManager().exportGameState();

    // 使用base64编码，与原游戏一致
    final bytes = utf8.encode(gameStateJson);
    String string64 = base64Encode(bytes);

    // 清理字符串（移除空格、点和换行符），与原游戏一致
    string64 = string64.replaceAll(RegExp(r'\s'), '');
    string64 = string64.replaceAll('.', '');
    string64 = string64.replaceAll('\n', '');

    return string64;
  }

  // 导出存档
  Future<String> export64() async {
    await saveGame();
    return await generateExport64();
  }

  // 导入存档 - 兼容原游戏格式
  Future<bool> import64(String string64) async {
    try {
      event('progress', 'import');

      // 清理输入字符串，与原游戏一致
      string64 = string64.replaceAll(RegExp(r'\s'), '');
      string64 = string64.replaceAll('.', '');
      string64 = string64.replaceAll('\n', '');

      // 解码Base64
      final bytes = base64Decode(string64);
      final decodedSave = utf8.decode(bytes);

      // 使用StateManager的导入功能
      final success = await StateManager().importGameState(decodedSave);

      if (success) {
        // 重新初始化游戏
        await init();
        if (kDebugMode) {
          Logger.info('✅ Save import successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          Logger.error('❌ Save import failed');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Error importing save: $e');
      }
      return false;
    }
  }

  // 确认删除存档
  void confirmDelete() {
    // 在Flutter中，这应该显示一个确认对话框
    // 现在我们直接调用deleteSave作为示例
    // 实际实现应该使用Events系统或者showDialog
  }

  // 分享游戏
  void share() {
    // 在Flutter中，这可以使用share包来实现
    // 现在只是记录事件
    event('share', 'game');
  }

  // 获取应用
  void getApp() {
    // 在Flutter中，这可以打开应用商店链接
    event('app', 'get');
  }

  // 检查是否开启了关灯模式
  bool isLightsOff() {
    final sm = StateManager();
    return sm.get('config.lightsOff', true) == true;
  }

  // 确认超级模式
  void confirmHyperMode() {
    if (!options['doubleTime']) {
      // 在实际实现中，这应该显示确认对话框
      // 现在直接触发超级模式
      triggerHyperMode();
    } else {
      triggerHyperMode();
    }
  }

  // 生成GUID
  String getGuid() {
    const chars = '0123456789abcdef';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';

    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        result += '-';
      }
      if (i == 12) {
        result += '4';
      } else if (i == 16) {
        result += chars[(random >> (i * 4)) & 0x3 | 0x8];
      } else {
        result += chars[(random >> (i * 4)) & 0xf];
      }
    }

    return result;
  }

  // 移动商店视图（在Flutter中可能不需要）
  void moveStoresView(dynamic topContainer, [int transitionDiff = 1]) {
    // 在Flutter中，布局由Widget树管理，这个方法可能不需要
    // 保留作为接口兼容性
  }

  // 更新滑块（在Flutter中可能不需要）
  void updateSlider() {
    // 在Flutter中，这由PageView或类似的Widget管理
  }

  // 更新外部滑块（在Flutter中可能不需要）
  void updateOuterSlider() {
    // 在Flutter中，这由PageView或类似的Widget管理
  }

  // 滑动事件处理
  void swipeLeft() {
    if (activeModule != null && activeModule.swipeLeft != null) {
      activeModule.swipeLeft();
    }
  }

  void swipeRight() {
    if (activeModule != null && activeModule.swipeRight != null) {
      activeModule.swipeRight();
    }
  }

  void swipeUp() {
    if (activeModule != null && activeModule.swipeUp != null) {
      activeModule.swipeUp();
    }
  }

  void swipeDown() {
    if (activeModule != null && activeModule.swipeDown != null) {
      activeModule.swipeDown();
    }
  }

  // 禁用/启用选择（在Flutter中可能不需要）
  void disableSelection() {
    // 在Web版本中用于禁用文本选择
    // 在Flutter中可能不需要
  }

  void enableSelection() {
    // 在Web版本中用于启用文本选择
    // 在Flutter中可能不需要
  }

  // 自动选择（在Flutter中可能不需要）
  void autoSelect(String selector) {
    // 在Web版本中用于自动选择文本
    // 在Flutter中可能不需要
  }

  // 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 处理状态更新事件
    notifyListeners();
  }

  // 切换语言
  void switchLanguage(String lang) {
    // 在Flutter中，这应该更新本地化设置
    event('language', lang);
  }

  // 保存语言设置
  Future<void> saveLanguage() async {
    // 在Flutter中，语言设置可以保存到SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // 这里可以保存当前语言设置
  }

  // 音频通知（延迟显示）
  void notifyAboutSound() {
    final sm = StateManager();
    if (sm.get('playStats.audioAlertShown') == true) {
      return;
    }

    // 告诉新用户现在有声音了！
    sm.set('playStats.audioAlertShown', true);

    // 在实际实现中，这应该显示一个事件对话框
    // 询问用户是否要启用音频
    event('audio', 'alert_shown');
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    AudioEngine().dispose();
    super.dispose();
  }
}
