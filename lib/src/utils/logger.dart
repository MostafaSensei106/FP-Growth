/// Defines the logging levels for the application.
enum LogLevel {
  /// Detailed information, typically of interest only when diagnosing problems.
  debug,

  /// Informational messages that highlight the progress of the application at coarse-grained level.
  info,

  /// Potentially harmful situations.
  warning,

  /// Error events that might still allow the application to continue running.
  error,

  /// Severe error events that presumably lead the application to abort.
  critical,

  /// No logging output.
  none;

  /// Returns true if this level should be logged given the minimum level.
  bool shouldLog(LogLevel minLevel) =>
      index >= minLevel.index && minLevel != LogLevel.none;
}

/// A simple logger for the FP-Growth library.
///
/// This logger prints messages to the console based on a configurable log level.
class Logger {
  LogLevel _currentLevel;

  /// Creates a new [Logger] instance.
  ///
  /// [initialLevel] sets the minimum level for messages to be logged.
  /// Messages with a level lower than [initialLevel] will be ignored.
  Logger({LogLevel initialLevel = LogLevel.info})
    : _currentLevel = initialLevel;

  /// Gets the current minimum log level.
  LogLevel get currentLevel => _currentLevel;

  /// Sets the current minimum log level.
  set level(LogLevel newLevel) {
    _currentLevel = newLevel;
  }

  /// Logs a debug message.
  void debug(String message) => _log(LogLevel.debug, message);

  /// Logs an informational message.
  void info(String message) => _log(LogLevel.info, message);

  /// Logs a warning message.
  void warning(String message) => _log(LogLevel.warning, message);

  /// Logs an error message.
  void error(String message) => _log(LogLevel.error, message);

  /// Logs a critical message.
  void critical(String message) => _log(LogLevel.critical, message);

  /// Internal method to log a message with a specific level.
  void _log(LogLevel level, String message) {
    if (level.shouldLog(_currentLevel)) {
      final timestamp = DateTime.now().toIso8601String();
      final levelName = level.name.toUpperCase().padRight(8);
      print('[$timestamp] [$levelName] $message');
    }
  }

  /// Logs a message with custom formatting.
  void logWithPrefix(LogLevel level, String prefix, String message) {
    if (level.shouldLog(_currentLevel)) {
      final timestamp = DateTime.now().toIso8601String();
      final levelName = level.name.toUpperCase().padRight(8);
      print('[$timestamp] [$levelName] [$prefix] $message');
    }
  }

  /// Enables all logging levels.
  void enableAll() => _currentLevel = LogLevel.debug;

  /// Disables all logging.
  void disableAll() => _currentLevel = LogLevel.none;

  /// Returns true if the given level would be logged.
  bool isEnabled(LogLevel level) => level.shouldLog(_currentLevel);
}
