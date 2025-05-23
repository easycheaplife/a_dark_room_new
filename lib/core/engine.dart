import 'dart:async';
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

/// Engine is the main game engine that coordinates all game systems
class Engine with ChangeNotifier {
  static final Engine _instance = Engine._internal();

  factory Engine() {
    return _instance;
  }

  Engine._internal();

  // Constants
  static const String SITE_URL = "http://adarkroom.doublespeakgames.com";
  static const double VERSION = 1.4;
  static const int MAX_STORE = 99999999999999;
  static const int SAVE_DISPLAY = 30 * 1000;

  // Game state
  bool gameOver = false;
  bool keyPressed = false;
  bool keyLock = false;
  bool tabNavigation = true;
  bool restoreNavigation = false;

  // Options
  Map<String, dynamic> options = {
    'debug': false,
    'log': false,
    'dropbox': false,
    'doubleTime': false,
  };

  // Active module
  dynamic activeModule;

  // Save timer
  Timer? _saveTimer;
  DateTime? _lastNotify;

  // Initialize the engine
  Future<void> init({Map<String, dynamic>? options}) async {
    this.options = {...this.options, ...?options};

    // Initialize state manager
    final sm = StateManager();
    sm.init();

    // Initialize audio engine
    await AudioEngine().init();

    // Initialize notifications
    NotificationManager().init();

    // Initialize localization
    await Localization().init();

    // Load saved game
    await loadGame();

    // Initialize modules
    await Room().init();

    // Check if outside should be initialized
    if (sm.get('stores.wood') != null) {
      await Outside().init();
    }

    // Check if path should be initialized
    if (sm.get('stores.compass', true) != null &&
        sm.get('stores.compass', true) > 0) {
      await Path().init();
    }

    // Check if fabricator should be initialized
    if (sm.get('features.location.fabricator', true) == true) {
      await Fabricator().init();
    }

    // Check if ship should be initialized
    if (sm.get('features.location.spaceShip', true) == true) {
      await Ship().init();
    }

    // Set up save timer
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) => saveGame());

    // Set initial module
    travelTo(Room());

    // Set up audio based on saved settings
    toggleVolume(sm.get('config.soundOn', true) == true);

    // Start income collection
    Timer.periodic(const Duration(seconds: 1), (_) => sm.collectIncome());

    notifyListeners();
  }

  // Save the game
  Future<void> saveGame() async {
    await StateManager().saveGame();

    if (_lastNotify == null ||
        DateTime.now().difference(_lastNotify!).inMilliseconds > SAVE_DISPLAY) {
      // Show save notification
      _lastNotify = DateTime.now();
      // In the original game, this would animate a "saved" message
    }
  }

  // Load the game
  Future<void> loadGame() async {
    try {
      await StateManager().loadGame();
      if (kDebugMode) {
        print('Game loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game: $e');
      }

      // Initialize new game state
      final sm = StateManager();
      sm.set('version', VERSION);

      // Log new game event
      event('progress', 'new game');
    }
  }

  // Delete save and restart
  Future<void> deleteSave({bool noReload = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!noReload) {
        // In a web context, this would reload the page
        // In Flutter, we'll reinitialize the game
        await init();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting save: $e');
      }
    }
  }

  // Travel to a different module
  void travelTo(dynamic module) {
    if (activeModule == module) {
      return;
    }

    // Update active module
    activeModule = module;

    // Call onArrival on the new module
    module.onArrival(1);

    // Print notifications for the module
    NotificationManager().printQueue(module.name);

    notifyListeners();
  }

  // Toggle game volume
  Future<void> toggleVolume([bool? enabled]) async {
    final sm = StateManager();

    if (enabled == null) {
      enabled = !(sm.get('config.soundOn', true) == true);
    }

    sm.set('config.soundOn', enabled);

    if (enabled) {
      await AudioEngine().setMasterVolume(1.0);
    } else {
      await AudioEngine().setMasterVolume(0.0);
    }

    notifyListeners();
  }

  // Toggle lights off mode
  void turnLightsOff() {
    final sm = StateManager();
    final lightsOff = sm.get('config.lightsOff', true) == true;

    sm.set('config.lightsOff', !lightsOff);

    notifyListeners();
  }

  // Toggle hyper mode (double speed)
  void triggerHyperMode() {
    options['doubleTime'] = !options['doubleTime'];

    StateManager().set('config.hyperMode', options['doubleTime']);

    notifyListeners();
  }

  // Log an event
  void event(String category, String action) {
    // In the original game, this would send analytics
    // For now, we'll just log it in debug mode
    if (kDebugMode) {
      print('Event: $category - $action');
    }
  }

  // Get income message
  String getIncomeMsg(num value, int delay) {
    final prefix = value > 0 ? "+" : "";
    return "$prefix$value per ${delay}s";
  }

  // Set interval with double time support
  Timer setInterval(Function callback, int interval,
      {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      interval = (interval / 2).round();
    }

    return Timer.periodic(Duration(milliseconds: interval), (_) => callback());
  }

  // Set timeout with double time support
  Timer setTimeout(Function callback, int timeout, {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      timeout = (timeout / 2).round();
    }

    return Timer(Duration(milliseconds: timeout), () => callback());
  }

  // Handle key down events
  void keyDown(KeyEvent event) {
    if (!keyPressed && !keyLock) {
      keyPressed = true;

      if (activeModule != null && activeModule.keyDown != null) {
        activeModule.keyDown(event);
      }
    }
  }

  // Handle key up events
  void keyUp(KeyEvent event) {
    keyPressed = false;

    if (activeModule != null && activeModule.keyUp != null) {
      activeModule.keyUp(event);
    } else {
      // Handle navigation keys
      // This would be implemented based on the key codes
    }

    if (restoreNavigation) {
      tabNavigation = true;
      restoreNavigation = false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    AudioEngine().dispose();
    super.dispose();
  }
}
