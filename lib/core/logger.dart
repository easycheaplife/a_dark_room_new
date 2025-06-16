import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String tag = 'INFO'}) {
    if (kDebugMode) {
      print('[$tag] $message');
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
