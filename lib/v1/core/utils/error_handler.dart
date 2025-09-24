import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'logger.dart';

/// Global error handler for the application
class GlobalErrorHandler {
  static final List<ErrorHandler> _handlers = [];

  /// Add an error handler
  static void addHandler(ErrorHandler handler) {
    if (!_handlers.contains(handler)) {
      _handlers.add(handler);
    }
  }

  /// Remove an error handler
  static void removeHandler(ErrorHandler handler) {
    _handlers.remove(handler);
  }

  /// Handle general errors
  static void handleError(Object error, StackTrace? stackTrace) {
    try {
      // Log the error
      AppLogger.error(
        'Global error handled',
        error: error,
        stackTrace: stackTrace,
      );

      // Notify all registered handlers
      for (final handler in _handlers) {
        try {
          handler.onError(error, stackTrace);
        } catch (handlerError) {
          AppLogger.error('Error in error handler', error: handlerError);
        }
      }

      // Platform-specific error handling
      if (Platform.isAndroid) {
        _handleAndroidError(error, stackTrace);
      } else if (Platform.isIOS) {
        _handleIOSError(error, stackTrace);
      }
    } catch (e) {
      // Fallback error handling
      debugPrint('❌ Critical error in GlobalErrorHandler: $e');
    }
  }

  /// Handle Flutter-specific errors
  static void handleFlutterError(FlutterErrorDetails details) {
    try {
      AppLogger.error(
        'Flutter error handled',
        error: details.exception,
        stackTrace: details.stack,
      );

      // Notify handlers
      for (final handler in _handlers) {
        try {
          handler.onFlutterError(details);
        } catch (handlerError) {
          AppLogger.error(
            'Error in Flutter error handler',
            error: handlerError,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Critical error in Flutter error handler: $e');
    }
  }

  /// Handle network-related errors
  static void handleNetworkError(Object error, StackTrace? stackTrace) {
    try {
      AppLogger.error(
        'Network error handled',
        error: error,
        stackTrace: stackTrace,
      );

      // Notify handlers
      for (final handler in _handlers) {
        try {
          handler.onNetworkError(error, stackTrace);
        } catch (handlerError) {
          AppLogger.error(
            'Error in network error handler',
            error: handlerError,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Critical error in network error handler: $e');
    }
  }

  /// Android-specific error handling
  static void _handleAndroidError(Object error, StackTrace? stackTrace) {
    // Android-specific error logging or crash reporting can be added here
    debugPrint('📱 Android error: $error');
  }

  /// iOS-specific error handling
  static void _handleIOSError(Object error, StackTrace? stackTrace) {
    // iOS-specific error logging or crash reporting can be added here
    debugPrint('📱 iOS error: $error');
  }

  /// Get error type string for categorization
  static String getErrorType(Object error) {
    if (error is NetworkException) return 'NetworkException';
    if (error is AuthenticationException) return 'AuthenticationException';
    if (error is FormatException) return 'FormatException';
    if (error is TimeoutException) return 'TimeoutException';
    if (error is StateError) return 'StateError';
    if (error is ArgumentError) return 'ArgumentError';
    if (error is AssertionError) return 'AssertionError';
    if (error is FlutterError) return 'FlutterError';
    return error.runtimeType.toString();
  }

  /// Check if error is recoverable
  static bool isRecoverableError(Object error) {
    return error is NetworkException ||
        error is TimeoutException ||
        error is FormatException;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(Object error) {
    if (error is NetworkException) {
      return 'Terjadi masalah koneksi. Silakan coba lagi.';
    }
    if (error is AuthenticationException) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    if (error is TimeoutException) {
      return 'Koneksi terputus. Periksa jaringan Anda.';
    }
    if (error is FormatException) {
      return 'Format data tidak valid.';
    }
    if (error is StateError) {
      return 'Aplikasi dalam keadaan tidak valid.';
    }

    return 'Terjadi kesalahan tak terduga.';
  }
}

/// Interface for error handlers
abstract class ErrorHandler {
  void onError(Object error, StackTrace? stackTrace) {}
  void onFlutterError(FlutterErrorDetails details) {}
  void onNetworkError(Object error, StackTrace? stackTrace) {}
}

/// Custom exceptions
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const NetworkException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthenticationException extends NetworkException {
  const AuthenticationException(String message)
    : super(message, statusCode: 401);
}

class ServerException extends NetworkException {
  const ServerException(String message, int statusCode)
    : super(message, statusCode: statusCode);
}

class ConnectivityException extends NetworkException {
  const ConnectivityException() : super('No internet connection');
}

/// Default error handler implementation
class DefaultErrorHandler implements ErrorHandler {
  @override
  void onError(Object error, StackTrace? stackTrace) {
    // Default error handling logic
    debugPrint('🔥 Default error handler: $error');
  }

  @override
  void onFlutterError(FlutterErrorDetails details) {
    // Default Flutter error handling
    debugPrint('🔥 Default Flutter error handler: ${details.exception}');
  }

  @override
  void onNetworkError(Object error, StackTrace? stackTrace) {
    // Default network error handling
    debugPrint('🌐 Default network error handler: $error');
  }
}
