import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// StateManager (SM) is the central state management system for the game
/// It replaces the JavaScript $SM object from the original game
class StateManager with ChangeNotifier {
  static final StateManager _instance = StateManager._internal();
  
  factory StateManager() {
    return _instance;
  }
  
  StateManager._internal();
  
  // Game state
  Map<String, dynamic> _state = {};
  
  // Getters
  Map<String, dynamic> get state => _state;
  
  // Initialize the state manager
  void init() {
    if (_state.isEmpty) {
      _state = {
        'version': 1.4,
        'stores': {},
        'income': {},
        'game': {
          'fire': {'value': 0},
          'temperature': {'value': 0},
          'builder': {'level': -1},
          'buildings': {},
        },
        'features': {
          'location': {
            'room': true,
          },
        },
        'playStats': {},
        'config': {
          'lightsOff': false,
          'hyperMode': false,
          'soundOn': true,
        },
      };
      notifyListeners();
    }
  }
  
  // Get a value from the state
  dynamic get(String path, [bool nullIfMissing = false]) {
    List<String> parts = path.split('.');
    dynamic current = _state;
    
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      
      // Handle array notation like "stores['wood']"
      if (part.contains('[') && part.contains(']')) {
        int startBracket = part.indexOf('[');
        int endBracket = part.indexOf(']');
        
        String objName = part.substring(0, startBracket);
        String key = part.substring(startBracket + 2, endBracket - 1);
        
        if (current[objName] == null) {
          if (nullIfMissing) return null;
          return 0;
        }
        
        current = current[objName];
        
        if (current[key] == null) {
          if (nullIfMissing) return null;
          return 0;
        }
        
        current = current[key];
      } else {
        if (current[part] == null) {
          if (nullIfMissing) return null;
          if (i == parts.length - 1 && part == 'value') {
            return 0;
          }
          return 0;
        }
        
        current = current[part];
      }
    }
    
    return current;
  }
  
  // Set a value in the state
  void set(String path, dynamic value, [bool noNotify = false]) {
    List<String> parts = path.split('.');
    dynamic current = _state;
    
    for (int i = 0; i < parts.length - 1; i++) {
      String part = parts[i];
      
      // Handle array notation like "stores['wood']"
      if (part.contains('[') && part.contains(']')) {
        int startBracket = part.indexOf('[');
        int endBracket = part.indexOf(']');
        
        String objName = part.substring(0, startBracket);
        String key = part.substring(startBracket + 2, endBracket - 1);
        
        if (current[objName] == null) {
          current[objName] = {};
        }
        
        current = current[objName];
        
        if (current[key] == null) {
          current[key] = {};
        }
        
        current = current[key];
      } else {
        if (current[part] == null) {
          current[part] = {};
        }
        
        current = current[part];
      }
    }
    
    String lastPart = parts.last;
    
    // Handle array notation for the last part
    if (lastPart.contains('[') && lastPart.contains(']')) {
      int startBracket = lastPart.indexOf('[');
      int endBracket = lastPart.indexOf(']');
      
      String objName = lastPart.substring(0, startBracket);
      String key = lastPart.substring(startBracket + 2, endBracket - 1);
      
      if (current[objName] == null) {
        current[objName] = {};
      }
      
      current = current[objName];
      current[key] = value;
    } else {
      current[lastPart] = value;
    }
    
    if (!noNotify) {
      notifyListeners();
    }
  }
  
  // Add a value to an existing value in the state
  void add(String path, dynamic value, [bool noNotify = false]) {
    dynamic current = get(path);
    
    if (current == null) {
      set(path, value, noNotify);
    } else if (current is num && value is num) {
      set(path, current + value, noNotify);
    } else if (current is String && value is String) {
      set(path, current + value, noNotify);
    } else if (current is List && value is List) {
      List newList = List.from(current);
      newList.addAll(value);
      set(path, newList, noNotify);
    } else if (current is Map && value is Map) {
      Map newMap = Map.from(current);
      newMap.addAll(value);
      set(path, newMap, noNotify);
    }
  }
  
  // Set multiple values at once
  void setM(String path, Map<String, dynamic> values, [bool noNotify = false]) {
    for (String key in values.keys) {
      set('$path["$key"]', values[key], true);
    }
    
    if (!noNotify) {
      notifyListeners();
    }
  }
  
  // Get a numeric value from the state
  num num(String path, dynamic object) {
    if (object != null && object.type == 'building') {
      return get('game.buildings["$path"]', true) ?? 0;
    }
    return get('stores["$path"]', true) ?? 0;
  }
  
  // Set income for a resource
  void setIncome(String source, Map<String, dynamic> options) {
    if (_state['income'] == null) {
      _state['income'] = {};
    }
    
    _state['income'][source] = options;
    notifyListeners();
  }
  
  // Collect income from all sources
  void collectIncome() {
    if (_state['income'] == null) return;
    
    for (String source in _state['income'].keys) {
      Map<String, dynamic> income = _state['income'][source];
      
      if (income['stores'] != null) {
        for (String store in income['stores'].keys) {
          add('stores["$store"]', income['stores'][store]);
        }
      }
    }
  }
  
  // Save the game state
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonState = jsonEncode(_state);
      await prefs.setString('gameState', jsonState);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game: $e');
      }
    }
  }
  
  // Load the game state
  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonState = prefs.getString('gameState');
      
      if (jsonState != null) {
        _state = jsonDecode(jsonState);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game: $e');
      }
    }
  }
  
  // Update old state format to new format
  void updateOldState() {
    // This would handle migrations between versions
    // For now, it's a placeholder
  }
  
  // Start thieves event
  void startThieves() {
    set('game.thieves', true);
    // Additional logic would be implemented in the events system
  }
}
