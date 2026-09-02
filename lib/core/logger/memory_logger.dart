import 'dart:collection';
import 'package:flutter/foundation.dart';

class MemoryLogger {
  static final MemoryLogger _instance = MemoryLogger._internal();
  factory MemoryLogger() => _instance;
  MemoryLogger._internal();

  static const _maxEntries = 500;
  final Queue<String> _entries = Queue<String>();

  List<String> get entries => List.unmodifiable(_entries);

  static Future<void> init() async {
    MemoryLogger().log('MemoryLogger initialized');
  }

  void log(String message) {
    final entry = '${DateTime.now().toIso8601String()}  $message';
    _entries.addLast(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    debugPrint(entry);
  }
}
