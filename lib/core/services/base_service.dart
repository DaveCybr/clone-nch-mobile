import 'package:dio/dio.dart';
import '../config/app_config.dart';

abstract class BaseService {
  Dio? _dio;

  Dio get dio {
    if (_dio == null) {
      _createDioInstance();
    }
    return _dio!;
  }

  void _createDioInstance() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // Method untuk refresh Dio instance ketika URL berubah
  void refreshDioInstance() {
    _dio?.close();
    _dio = null;
    _createDioInstance();
  }

  // Method untuk menambahkan token ke header
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Method untuk menghapus token dari header
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}
