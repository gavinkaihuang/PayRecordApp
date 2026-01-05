import 'dart:collection';

class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry(this.message) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] $message';
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  
  // Expose as unmodifiable info if needed, or copy
  List<LogEntry> get logs => UnmodifiableListView(_logs);

  void addLog(String message) {
    // Keep logs within reasonable size if memory is concern, e.g. 500
    if (_logs.length >= 1000) {
      _logs.removeAt(0);
    }
    final entry = LogEntry(message);
    _logs.add(entry);
    
    // Also print to console for dev
    print(entry.toString());
  }

  void clearLogs() {
    _logs.clear();
  }
}
