import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/notifications.dart';

/// Path is the module for exploring the world
class Path with ChangeNotifier {
  static final Path _instance = Path._internal();
  
  factory Path() {
    return _instance;
  }
  
  Path._internal();
  
  // Module name
  final String name = "Path";
  
  // UI elements
  late Widget panel;
  late Widget tab;
  
  // Initialize the path
  Future<void> init() async {
    final sm = StateManager();
    
    // Set up initial state if not already set
    if (sm.get('features.location.path') == null) {
      sm.set('features.location.path', true);
    }
    
    NotificationManager().notify(name, 'a dusty path leads through the forest');
    
    notifyListeners();
  }
  
  // Called when arriving at this module
  void onArrival(int transitionDiff) {
    // Update UI when arriving at this module
    notifyListeners();
  }
  
  // Open the path
  void openPath() {
    NotificationManager().notify(name, 'the compass points east');
    notifyListeners();
  }
}
