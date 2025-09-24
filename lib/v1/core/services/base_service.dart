import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';

// Custom exceptions untuk better error handling
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  NetworkException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthenticationException extends NetworkException {
  AuthenticationException(String message) : super(message, statusCode: 401);
}

class ServerException extends NetworkException {
  ServerException(String message, int statusCode)
    : super(message, statusCode: statusCode);
}

class ConnectivityException extends NetworkException {
  ConnectivityException() : super('No internet connection');
}

abstract class BaseService {
  Dio? _dio;
  bool _disposed = false;
  final Connectivity _connectivity = Connectivity();

  Dio get dio {
    if (_disposed) {
      throw StateError('Service has been disposed');
    }
    if (_dio == null) {
      _createDioInstance();
    }
    return _dio!;
  }

  void _createDioInstance() {
    if (_disposed) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl ?? '',
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _addInterceptors();
  }

  void _addInterceptors() {
    if (_dio == null || _disposed) return;

    // Request interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check connectivity before making request
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: ConnectivityException(),
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }

          // Add auth token if available
          if (AppConfig.token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${AppConfig.token}';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiry
          if (error.response?.statusCode == 401) {
            AppConfig.clearToken();
            handler.next(error);
            return;
          }

          // Retry logic for network errors
          if (_shouldRetry(error)) {
            try {
              final retryResponse = await _retryRequest(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (e) {
              // If retry fails, continue with original error
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    int retryCount = 0;

    while (retryCount < AppConfig.maxRetries) {
      try {
        await Future.delayed(
          Duration(milliseconds: AppConfig.retryDelayMs * (retryCount + 1)),
        );
        return await _dio!.fetch(requestOptions);
      } catch (e) {
        retryCount++;
        if (retryCount >= AppConfig.maxRetries) {
          rethrow;
        }
      }
    }

    throw DioException(
      requestOptions: requestOptions,
      error: 'Max retries exceeded',
      type: DioExceptionType.unknown,
    );
  }

  // Method untuk refresh Dio instance ketika URL berubah
  void refreshDioInstance() {
    if (_disposed) return;

    _dio?.close(force: true);
    _dio = null;
    _createDioInstance();
  }

  // Method untuk menambahkan token ke header
  void setAuthToken(String token) {
    if (_disposed || _dio == null) return;

    if (AppConfig.setToken(token)) {
      _dio!.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // Method untuk menghapus token dari header
  void clearAuthToken() {
    if (_disposed || _dio == null) return;

    AppConfig.clearToken();
    _dio!.options.headers.remove('Authorization');
  }

  // Enhanced error handling method
  Exception handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown server error';

        switch (statusCode) {
          case 401:
            return AuthenticationException(
              'Authentication failed. Please login again.',
            );
          case 403:
            return NetworkException(
              'Access forbidden. You don\'t have permission.',
            );
          case 404:
            return NetworkException('Resource not found.');
          case 422:
            return NetworkException('Validation error: $message');
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException(
              'Server error. Please try again later.',
              statusCode!,
            );
          default:
            return NetworkException(
              'Server error: $message',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return NetworkException('Request was cancelled.');

      case DioExceptionType.connectionError:
        if (e.error is ConnectivityException) {
          return e.error as ConnectivityException;
        }
        return NetworkException(
          'Connection error. Please check your internet connection.',
        );

      default:
        return NetworkException('An unexpected error occurred: ${e.message}');
    }
  }

  // Method untuk check connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Cleanup method
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _dio?.close(force: true);
    _dio = null;
  }

  // Method untuk check apakah service sudah disposed
  bool get isDisposed => _disposed;
}
