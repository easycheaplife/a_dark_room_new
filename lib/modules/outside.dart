import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/notifications.dart';

/// Outside is the module for gathering resources outside the room
class Outside with ChangeNotifier {
  static final Outside _instance = Outside._internal();
  
  factory Outside() {
    return _instance;
  }
  
  Outside._internal();
  
  // Module name
  final String name = "Outside";
  
  // UI elements
  late Widget panel;
  late Widget tab;
  
  // Initialize the outside
  Future<void> init() async {
    final sm = StateManager();
    
    // Set up initial state if not already set
    if (sm.get('features.location.outside') == null) {
      sm.set('features.location.outside', true);
    }
    
    NotificationManager().notify(name, 'the sky is grey and the wind blows relentlessly');
    
    notifyListeners();
  }
  
  // Called when arriving at this module
  void onArrival(int transitionDiff) {
    // Update UI when arriving at this module
    notifyListeners();
  }
  
  // Update the village
  void updateVillage() {
    // Update village UI based on buildings and population
    notifyListeners();
  }
}
