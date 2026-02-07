import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppErrorReporter {
  static bool _initialized = false;
  static const String _logFileName = 'promarket_errors.log';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return true;
    };
  }

  static Future<void> report(Object error, StackTrace? stackTrace) async {
    final message = _formatError(error, stackTrace);
    debugPrint(message);
    await _appendToFile(message);
  }

  static Future<void> logMessage(String message) async {
    final entry = '[${DateTime.now().toIso8601String()}] $message';
    debugPrint(entry);
    await _appendToFile(entry);
  }

  static String _formatError(Object error, StackTrace? stackTrace) {
    final timestamp = DateTime.now().toIso8601String();
    final stack = stackTrace == null ? '' : '\n$stackTrace';
    return '[$timestamp] ERROR: $error$stack';
  }

  static Future<void> _appendToFile(String message) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');
      await file.writeAsString('$message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write error log: $e');
    }
  }
}
