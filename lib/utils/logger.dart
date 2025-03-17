import 'package:logger/logger.dart';

class LogEntry {
  final DateTime timestamp;
  final String message;
  final String? error;
  final Level level;

  LogEntry({
    required this.timestamp,
    required this.message,
    this.error,
    required this.level,
  });
}

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // 添加日志存储
  static final List<LogEntry> _logs = [];
  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void debug(String message) {
    _logger.d(message);
    _addLog(message, Level.debug);
  }

  static void info(String message) {
    _logger.i(message);
    _addLog(message, Level.info);
  }

  static void warning(String message) {
    _logger.w(message);
    _addLog(message, Level.warning);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
    _addLog(message, Level.error, error?.toString());
  }

  // 用于开发阶段的详细日志
  static void verbose(String message) {
    _logger.v(message);
    _addLog(message, Level.verbose);
  }

  // 用于生产环境中的关键日志
  static void wtf(String message) {
    _logger.wtf(message);
    _addLog(message, Level.wtf);
  }

  static void _addLog(String message, Level level, [String? error]) {
    _logs.add(LogEntry(
      timestamp: DateTime.now(),
      message: message,
      error: error,
      level: level,
    ));
  }

  static void clear() {
    _logs.clear();
  }
}
