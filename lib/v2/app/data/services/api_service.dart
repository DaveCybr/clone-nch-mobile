import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../models/attendance_model.dart';
import '../models/dashboard_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  // Base URL - sesuaikan dengan server Laravel Anda
  static const String baseUrl = 'https://be.nurulchotib.com/api';

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    if (Get.arguments != null && Get.arguments['debug'] == true) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  void _handleUnauthorized() {
    _storageService.clearAll();
    Get.offAllNamed('/login');
  }

  // Auth endpoints sesuai dengan struktur database JTI NCH
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // Expected response structure:
      // {
      //   "success": true,
      //   "message": "Login successful",
      //   "token": "your-jwt-token",
      //   "user": {
      //     "id": "uuid",
      //     "name": "User Name",
      //     "email": "user@email.com",
      //     "roles": [{"name": "teacher"}],
      //     "employee": {...} // if teacher
      //   }
      // }

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Add these methods to your existing ApiService class

  /// Get teacher dashboard data
  Future<Map<String, dynamic>> getTeacherDashboard() async {
    try {
      final response = await _dio.get('/teacher/dashboard');

      // Expected response structure:
      // {
      //   "success": true,
      //   "stats": {
      //     "total_students": 250,
      //     "total_classes": 12,
      //     "today_tasks": 8,
      //     "total_announcements": 3
      //   },
      //   "today_schedules": [...],
      //   "prayer_times": [...],
      //   "announcements": [...],
      //   "teacher": {...}
      // }

      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get teacher statistics
  Future<Map<String, dynamic>> getTeacherStats() async {
    try {
      final response = await _dio.get('/teacher/stats');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get today's prayer times
  Future<List<dynamic>> getPrayerTimes() async {
    try {
      final response = await _dio.get('/prayer-times');
      return response.data['prayer_times'] as List<dynamic>;
    } on DioException catch (e) {
      // Return default prayer times if API fails
      return PrayerTimeModel.getDefaultTimes()
          .map(
            (e) => {
              'name': e.name,
              'time': e.time,
              'arabic_name': e.arabicName,
              'is_passed': e.isPassed,
            },
          )
          .toList();
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/me');

      // Expected response:
      // {
      //   "success": true,
      //   "user": {...}
      // }
      developer.log(response.toString());

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Dashboard data untuk teacher
  // Future<Map<String, dynamic>> getTeacherDashboard() async {
  //   try {
  //     final response = await _dio.get('/teacher/dashboard');
  //     return response.data;
  //   } on DioException catch (e) {
  //     throw _handleDioError(e);
  //   }
  // }

  // Get schedules for teacher
  Future<List<dynamic>> getTeacherSchedules({String? date}) async {
    try {
      final response = await _dio.get(
        '/teacher/schedules',
        queryParameters: {if (date != null) 'date': date},
      );
      return response.data['schedules'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get students in teacher's classes
  Future<List<dynamic>> getTeacherStudents({String? classId}) async {
    try {
      final response = await _dio.get(
        '/teacher/students',
        queryParameters: {if (classId != null) 'class_id': classId},
      );
      return response.data['students'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get announcements
  Future<List<dynamic>> getAnnouncements({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/announcements',
        queryParameters: {'page': page},
      );
      return response.data['berita'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Tambahkan methods ini ke ApiService existing (lib/v2/app/data/services/api_service.dart)

  /// Get students by schedule for attendance
  Future<ScheduleDetailModel> getScheduleAttendance({
    required String scheduleId,
    DateTime? date,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/schedule/$scheduleId/attendance',
        queryParameters: {
          if (date != null) 'date': date.toIso8601String().split('T')[0],
        },
      );

      return ScheduleDetailModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Submit attendance for students
  Future<void> submitAttendance(AttendanceSubmissionModel submission) async {
    try {
      await _dio.post(
        '/teacher/attendance',
        data: submission.toJson(),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get teacher's classes and students
  Future<List<TeacherClassModel>> getTeacherClasses() async {
    try {
      final response = await _dio.get('/teacher/classes');
      return (response.data['data'] as List)
          .map((e) => TeacherClassModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get student attendance history
  Future<StudentHistoryModel> getStudentAttendanceHistory({
    required String studentId,
    required String subjectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/student/$studentId/attendance-history',
        queryParameters: {
          'subject_id': subjectId,
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      return StudentHistoryModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get teacher's schedule (weekly/daily view)
  Future<List<dynamic>> getTeacherScheduleList({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/schedule',
        queryParameters: {
          if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      return response.data['data'] as List;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update attendance record
  Future<void> updateAttendance({
    required String attendanceId,
    required AttendanceStatus status,
    String? notes,
  }) async {
    try {
      await _dio.put(
        '/teacher/attendance/$attendanceId',
        data: {
          'status': status.value,
          'notes': notes,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انقطاع الاتصال - Koneksi timeout. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Terjadi kesalahan';
        if (statusCode == 401) {
          return 'البريد الإلكتروني أو كلمة المرور خاطئة - Email atau password salah';
        } else if (statusCode == 422) {
          return 'البيانات غير صالحة - Data yang dimasukkan tidak valid';
        } else if (statusCode == 500) {
          return 'خطأ في الخادم - Server sedang bermasalah. Coba lagi nanti.';
        }
        return message;
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب - Permintaan dibatalkan';
      case DioExceptionType.connectionError:
        return 'لا يمكن الاتصال بالخادم - Tidak dapat terhubung ke server';
      default:
        return 'حدث خطأ غير متوقع - Terjadi kesalahan tidak terduga';
    }
  }

  // Getter for dio instance
  Dio get dio => _dio;
}
