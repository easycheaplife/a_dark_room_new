import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/notifications.dart';

/// Ship is the module for the spaceship
class Ship with ChangeNotifier {
  static final Ship _instance = Ship._internal();
  
  factory Ship() {
    return _instance;
  }
  
  Ship._internal();
  
  // Module name
  final String name = "Ship";
  
  // UI elements
  late Widget panel;
  late Widget tab;
  
  // Initialize the ship
  Future<void> init() async {
    final sm = StateManager();
    
    // Set up initial state if not already set
    if (sm.get('features.location.spaceShip') == null) {
      sm.set('features.location.spaceShip', true);
    }
    
    NotificationManager().notify(name, 'the ship\'s systems hum quietly');
    
    notifyListeners();
  }
  
  // Called when arriving at this module
  void onArrival(int transitionDiff) {
    // Update UI when arriving at this module
    notifyListeners();
  }
}
