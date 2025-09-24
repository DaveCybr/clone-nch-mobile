import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:io';

/// Centralized logging utility for the application
class AppLogger {
  static Logger? _logger;
  static final List<LogRecord> _logBuffer = [];
  static StreamSubscription<LogRecord>? _logSubscription;
  static bool _initialized = false;

  /// Initialize the logger
  static void initialize() {
    if (_initialized) return;

    _logger = Logger('NCH_Mobile');

    // Set log level based on build mode
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    // Setup log listener
    _logSubscription = Logger.root.onRecord.listen(_handleLogRecord);

    _initialized = true;
    info('Logger initialized');
  }

  /// Handle log records
  static void _handleLogRecord(LogRecord record) {
    // Add to buffer
    _logBuffer.add(record);

    // Keep buffer size manageable
    if (_logBuffer.length > 1000) {
      _logBuffer.removeRange(0, 500);
    }

    // Format and output log
    final message = _formatLogMessage(record);

    if (kDebugMode) {
      debugPrint(message);
    }

    // Write to file in release mode (if needed)
    if (kReleaseMode) {
      _writeToFile(message);
    }
  }

  /// Format log message
  static String _formatLogMessage(LogRecord record) {
    final timestamp = record.time.toIso8601String();
    final level = record.level.name.padRight(7);
    final logger = record.loggerName.padRight(12);
    final message = record.message;

    var formatted = '$timestamp [$level] $logger: $message';

    if (record.error != null) {
      formatted += '\n  Error: ${record.error}';
    }

    if (record.stackTrace != null) {
      final stackLines = record.stackTrace.toString().split('\n');
      final relevantLines = stackLines.take(5).join('\n    ');
      formatted += '\n  Stack:\n    $relevantLines';
    }

    return formatted;
  }

  /// Write log to file (for release builds)
  static Future<void> _writeToFile(String message) async {
    try {
      // Implementation for file logging would go here
      // For now, we'll skip this to avoid additional complexity
    } catch (e) {
      // Silently fail to avoid recursive logging
    }
  }

  /// Log info message
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger?.info(message, error, stackTrace);
  }

  /// Log debug message
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger?.fine(message, error, stackTrace);
  }

  /// Log warning message
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger?.warning(message, error, stackTrace);
  }

  /// Log error message
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger?.severe(message, error, stackTrace);
  }

  /// Log config message
  static void config(String message, {Object? error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger?.config(message, error, stackTrace);
  }

  /// Log verbose message (only in debug mode)
  static void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _ensureInitialized();
      _logger?.finest(message, error, stackTrace);
    }
  }

  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Get log buffer for debugging
  static List<LogRecord> getLogBuffer() {
    return List.unmodifiable(_logBuffer);
  }

  /// Clear log buffer
  static void clearLogBuffer() {
    _logBuffer.clear();
  }

  /// Dispose logger resources
  static void dispose() {
    _logSubscription?.cancel();
    _logSubscription = null;
    _logger = null;
    _initialized = false;
    _logBuffer.clear();
  }

  /// Get formatted log history
  static String getFormattedLogs() {
    return _logBuffer.map(_formatLogMessage).join('\n');
  }

  /// Export logs (for debugging or support)
  static Future<String?> exportLogs() async {
    try {
      final logs = getFormattedLogs();
      if (logs.isEmpty) return null;

      // In a real implementation, you might save to a file or share
      return logs;
    } catch (e) {
      error('Failed to export logs', error: e);
      return null;
    }
  }

  /// Log network request
  static void logNetworkRequest(
    String method,
    String url, {
    Map<String, dynamic>? data,
  }) {
    debug('🌐 $method $url', error: data != null ? 'Data: $data' : null);
  }

  /// Log network response
  static void logNetworkResponse(
    String method,
    String url,
    int statusCode, {
    dynamic data,
  }) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    debug(
      '$emoji $method $url - $statusCode',
      error: data != null ? 'Response: $data' : null,
    );
  }

  /// Log user action
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    info(
      '👤 User action: $action',
      error: context != null ? 'Context: $context' : null,
    );
  }

  /// Log performance metric
  static void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    final ms = duration.inMilliseconds;
    info(
      '⚡ Performance: $operation took ${ms}ms',
      error: context != null ? 'Context: $context' : null,
    );
  }

  /// Log navigation event
  static void logNavigation(String from, String to) {
    info('🧭 Navigation: $from -> $to');
  }

  /// Log lifecycle event
  // static void logLifecycle(String event, {String? details}) {
  //   info('🔄 Lifecycle: $event${details != null ? ' - $details' : '
}
