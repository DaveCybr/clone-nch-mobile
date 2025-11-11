import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../models/attendance_model.dart';
import '../models/dashboard_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'dart:convert'; // for jsonEncode

class ApiService extends GetxService {
  late Dio _dio;
  final StorageService _storageService = Get.find<StorageService>();

  static String baseUrl = 'https://nch-be-staging.jtinova.com/api';

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status! < 500; // Accept semua status code < 500
        },
      ),
      // ✅ Tambahkan ini untuk debugging
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false, // ✅ Ubah ke false untuk log lebih detail
        maxWidth: 90,
      ),
    );

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // ✅ Log detail request
          developer.log('🌐 REQUEST: ${options.method} ${options.uri}');
          developer.log('📤 Headers: ${options.headers}');
          developer.log('📤 Body: ${options.data}');

          handler.next(options);
        },
        onResponse: (response, handler) {
          // ✅ Log detail response
          developer.log('✅ RESPONSE: ${response.statusCode}');
          developer.log('📥 Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          // ✅ Log detail error
          developer.log('❌ ERROR: ${error.type}');
          developer.log('❌ Message: ${error.message}');
          developer.log('❌ Response: ${error.response?.data}');

          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }
          handler.next(error);
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

  void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl; // Update dio juga
    print('Base URL updated to: $newBaseUrl');
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('=== LOGIN REQUEST START ===');
      developer.log('Email: $email');
      developer.log('Base URL: $baseUrl');
      developer.log('Full URL: $baseUrl/auth/login');

      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      developer.log('=== LOGIN RESPONSE ===');
      developer.log('Status Code: ${response.statusCode}');
      developer.log('Response Data: ${response.data}');

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      developer.log('=== DIO EXCEPTION ===');
      developer.log('Type: ${e.type}');
      developer.log('Message: ${e.message}');
      developer.log('Response: ${e.response?.data}');
      developer.log('Status Code: ${e.response?.statusCode}');

      throw _handleDioError(e);
    } catch (e, stackTrace) {
      developer.log('=== GENERAL EXCEPTION ===');
      developer.log('Error: $e');
      developer.log('StackTrace: $stackTrace');
      throw 'Terjadi kesalahan tidak terduga: $e';
    }
  }

  // Add these methods to your existing ApiService class

  /// Get teacher dashboard data
  Future<Map<String, dynamic>> getTeacherDashboard() async {
    try {
      final response = await _dio.get('/teacher/dashboard');
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
    } on DioException {
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
      developer.log(response.toString());

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

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

  // Tambahkan methods ini ke ApiService existing (lib/v2/app/data/services/api_service.dart)

  /// Get students by schedule for attendance
  Future<ScheduleDetailModel> getScheduleAttendance({
    required String scheduleId,
    String? date,
  }) async {
    developer.log(date!);
    try {
      final response = await _dio.get(
        '/teacher/schedule/$scheduleId/attendance',
        queryParameters: {'date': date},
      );

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response: data is null');
      }

      return ScheduleDetailModel.fromJson(response.data['data']);
    } catch (e, stackTrace) {
      developer.log('❌ Get schedule attendance error: $e');
      developer.log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Submit attendance for students
  Future<void> submitAttendance(AttendanceSubmissionModel submission) async {
    try {
      await _dio.post('/teacher/attendance', data: submission.toJson());
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
      final queryParams = {
        'subject_id': subjectId,
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
      };

      developer.log('🌐 API Request:');
      developer.log('  URL: /teacher/student/$studentId/attendance-history');
      developer.log('  Params: $queryParams');

      final response = await _dio.get(
        '/teacher/student/$studentId/attendance-history',
        queryParameters: queryParams,
      );

      // ✅ DEBUG: Print full response
      developer.log('📥 API Response Status: ${response.statusCode}');
      developer.log('📥 API Response Data:');
      developer.log(jsonEncode(response.data)); // Pretty print JSON

      // ✅ Check response structure
      final responseData = response.data;

      // Handle different response structures
      Map<String, dynamic> data;

      if (responseData is Map<String, dynamic>) {
        // Structure 1: { "data": {...} }
        if (responseData.containsKey('data')) {
          data = responseData['data'] as Map<String, dynamic>;
          developer.log('✅ Found data in response.data');
        }
        // Structure 2: Direct data
        else {
          data = responseData;
          developer.log('✅ Using response as direct data');
        }
      } else {
        throw Exception(
          'Invalid response format: expected Map, got ${responseData.runtimeType}',
        );
      }

      // ✅ DEBUG: Print data structure before parsing
      developer.log('📊 Parsing data structure:');
      developer.log('  - Has student key: ${data.containsKey('student')}');
      developer.log('  - Has summary key: ${data.containsKey('summary')}');
      developer.log('  - Has history key: ${data.containsKey('history')}');

      if (data.containsKey('summary')) {
        developer.log('  - Summary data: ${data['summary']}');
      }

      if (data.containsKey('history')) {
        final historyList = data['history'];
        developer.log('  - History is List: ${historyList is List}');
        developer.log(
          '  - History length: ${historyList is List ? historyList.length : 0}',
        );
      }

      // Parse model
      final history = StudentHistoryModel.fromJson(data);

      developer.log('✅ Model parsed successfully');
      return history;
    } on DioException catch (e) {
      developer.log('❌ DioException: ${e.message}');
      developer.log('   Response: ${e.response?.data}');
      developer.log('   Status Code: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      developer.log('❌ Unexpected error in getStudentAttendanceHistory: $e');
      developer.log('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get teacher's schedule (weekly/daily view)
  Future<Map<String, dynamic>> getTeacherScheduleList({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/schedule',
        queryParameters: {
          if (startDate != null)
            'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      return response.data['data'] as Map<String, dynamic>;
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
        data: {'status': status.value, 'notes': notes},
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

  /// Get schedules by date - IMPLEMENTASI YANG HILANG
  Future<List<dynamic>> getSchedulesByDate(DateTime date) async {
    try {
      final response = await _dio.get(
        '/teacher/schedules',
        queryParameters: {'date': date.toIso8601String().split('T')[0]},
      );
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<dynamic>> getAnnouncements({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/announcements',
        queryParameters: {'page': page, 'limit': limit},
      );

      developer.log('Announcements Response: ${response.data}');

      // Response adalah Map dengan struktur laravel pagination
      final responseData = response.data as Map<String, dynamic>;

      // Laravel pagination structure: { "data": { "data": [...], "current_page": 1, ... } }
      if (responseData['data'] != null) {
        final paginationData = responseData['data'];

        // Cek apakah 'data' adalah Map (pagination) atau List langsung
        if (paginationData is Map<String, dynamic>) {
          // Laravel pagination: data.data berisi array
          if (paginationData['data'] != null &&
              paginationData['data'] is List) {
            return paginationData['data'] as List<dynamic>;
          }
        } else if (paginationData is List) {
          // Data langsung berupa array
          return paginationData;
        }
      }

      // Struktur alternatif
      if (responseData['berita'] != null && responseData['berita'] is List) {
        return responseData['berita'] as List<dynamic>;
      }

      if (responseData['announcements'] != null &&
          responseData['announcements'] is List) {
        return responseData['announcements'] as List<dynamic>;
      }

      // Jika tidak ada yang cocok, kembalikan empty list
      developer.log('Unknown response structure, returning empty list');
      return [];
    } on DioException catch (e) {
      developer.log('DioException in getAnnouncements: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      developer.log('Unexpected error in getAnnouncements: $e');
      rethrow;
    }
  }

  /// Get teacher profile
  Future<Map<String, dynamic>> getTeacherProfile() async {
    try {
      final response = await _dio.get('/teacher/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update teacher profile
  Future<void> updateTeacherProfile(Map<String, dynamic> profileData) async {
    try {
      await _dio.put('/teacher/profile', data: profileData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get attendance summary for a specific date range
  Future<Map<String, dynamic>> getAttendanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/attendance-summary',
        queryParameters: {
          if (startDate != null)
            'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get attendance history with filters
  Future<List<dynamic>> getAttendanceHistory({
    String? classId,
    String? subjectId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/teacher/attendance-history',
        queryParameters: {
          if (classId != null) 'class_id': classId,
          if (subjectId != null) 'subject_id': subjectId,
          if (startDate != null)
            'start_date': startDate.toIso8601String().split('T')[0],
          if (endDate != null)
            'end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStudentDashboard() async {
    try {
      final response = await _dio.get('/student/dashboard');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get student schedules
  Future<List<dynamic>> getStudentSchedules({String? date}) async {
    try {
      developer.log('📅 Fetching student schedules for date: $date');

      final response = await _dio.get(
        '/student/schedules',
        queryParameters: {if (date != null) 'date': date},
      );

      developer.log('✅ Schedule Response Status: ${response.statusCode}');
      developer.log('📊 Full Response: ${jsonEncode(response.data)}');

      final responseData = response.data;

      // Handle different response structures
      if (responseData is Map<String, dynamic>) {
        developer.log('📋 Response is Map, checking structure...');
        developer.log('📋 Keys: ${responseData.keys}');

        // Structure 1: { "data": [...] }
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          developer.log('📋 Found "data" key, type: ${data.runtimeType}');

          if (data is List) {
            developer.log('✅ "data" is List with ${data.length} items');
            if (data.isNotEmpty) {
              developer.log('📄 First item sample: ${data.first}');
            }
            return data;
          } else if (data is Map && data.containsKey('data')) {
            // Laravel pagination: { "data": { "data": [...] } }
            developer.log('✅ Found nested pagination structure');
            final nestedData = data['data'];
            if (nestedData is List) {
              developer.log(
                '✅ Nested data is List with ${nestedData.length} items',
              );
              return nestedData;
            }
          } else if (data is Map && data.containsKey('schedules')) {
            // { "data": { "schedules": [...] } }
            developer.log('✅ Found "schedules" in data');
            final schedules = data['schedules'];
            if (schedules is List) {
              return schedules;
            }
          }
        }

        // Structure 2: { "schedules": [...] }
        if (responseData.containsKey('schedules')) {
          final schedules = responseData['schedules'];
          developer.log(
            '✅ Found "schedules" key, type: ${schedules.runtimeType}',
          );
          if (schedules is List) {
            developer.log(
              '✅ "schedules" is List with ${schedules.length} items',
            );
            if (schedules.isNotEmpty) {
              developer.log('📄 First item sample: ${schedules.first}');
            }
            return schedules;
          }
        }

        developer.log('⚠️ No known structure found in Map response');
        developer.log('⚠️ Available keys: ${responseData.keys.join(", ")}');
        return [];
      }

      // Direct list response
      if (responseData is List) {
        developer.log(
          '✅ Response is direct List: ${responseData.length} items',
        );
        if (responseData.isNotEmpty) {
          developer.log('📄 First item sample: ${responseData.first}');
        }
        return responseData;
      }

      developer.log(
        '⚠️ Unknown response structure: ${responseData.runtimeType}',
      );
      return [];
    } on DioException catch (e) {
      developer.log('❌ DioException in getStudentSchedules');
      developer.log('❌ Type: ${e.type}');
      developer.log('❌ Message: ${e.message}');
      developer.log('❌ Status Code: ${e.response?.statusCode}');
      developer.log('❌ Response Data: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      developer.log('❌ Unexpected error in getStudentSchedules: $e');
      developer.log('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get student attendance
  Future<Map<String, dynamic>> getStudentAttendance({
    String? date,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/student/attendance',
        queryParameters: {
          if (date != null) 'date': date,
          'page': page,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get student berita/announcements
  Future<List<dynamic>> getStudentBerita({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/student/berita',
        queryParameters: {'page': page},
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        final paginationData = responseData['data'];
        if (paginationData is Map<String, dynamic> &&
            paginationData['data'] != null) {
          return paginationData['data'] as List<dynamic>;
        } else if (paginationData is List) {
          return paginationData;
        }
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update FCM token to server
  Future<void> updateFCMToken(String fcmToken) async {
    try {
      developer.log('📤 Updating FCM token to server...');

      final response = await _dio.post(
        '/notification/update-fcm-token',
        data: {'fcm_token': fcmToken},
      );

      developer.log('✅ FCM token updated successfully');
      developer.log('Response: ${response.data}');
    } on DioException catch (e) {
      developer.log('❌ Error updating FCM token: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Delete FCM token from server (untuk logout)
  Future<void> deleteFCMToken() async {
    try {
      developer.log('🗑️ Deleting FCM token from server...');

      await _dio.delete('/notification/delete-fcm-token');

      developer.log('✅ FCM token deleted from server');
    } on DioException catch (e) {
      developer.log('❌ Error deleting FCM token: ${e.message}');
      // Don't throw error on delete, just log it
    }
  }

  /// Subscribe to notification topics
  Future<void> subscribeToTopics(List<String> topics) async {
    try {
      developer.log('📝 Subscribing to topics: $topics');

      await _dio.post(
        '/notification/subscribe-topics',
        data: {'topics': topics},
      );

      developer.log('✅ Subscribed to topics successfully');
    } on DioException catch (e) {
      developer.log('❌ Error subscribing to topics: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Test notification (untuk debugging)
  Future<void> sendTestNotification() async {
    try {
      developer.log('🧪 Sending test notification...');

      final response = await _dio.post('/notification/test');

      developer.log('✅ Test notification sent');
      developer.log('Response: ${response.data}');
    } on DioException catch (e) {
      developer.log('❌ Error sending test notification: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Get notification history
  Future<List<dynamic>> getNotificationHistory({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/notification/history',
        queryParameters: {'page': page},
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['data'] != null) {
        final paginationData = responseData['data'];
        if (paginationData is Map<String, dynamic> &&
            paginationData['data'] != null) {
          return paginationData['data'] as List<dynamic>;
        } else if (paginationData is List) {
          return paginationData;
        }
      }

      return [];
    } on DioException catch (e) {
      developer.log('❌ Error getting notification history: ${e.message}');
      throw _handleDioError(e);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put('/notification/$notificationId/read');
      developer.log('✅ Notification marked as read');
    } on DioException catch (e) {
      developer.log('❌ Error marking notification as read: ${e.message}');
      // Don't throw, just log
    }
  }

  /// Get berita detail by slug
  Future<Map<String, dynamic>> getBeritaDetail(String slug) async {
    try {
      final response = await _dio.get('/berita/$slug');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Tambahkan methods ini ke dalam class ApiService (setelah method getBeritaDetail)

  // ===== SECURITY MODULE METHODS =====

  /// Get security dashboard data
  Future<Map<String, dynamic>> getSecurityDashboard() async {
    try {
      final response = await _dio.get('/security/visits/dashboard');
      developer.log('Security Dashboard Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Scan QR Code - Get visit info
  Future<Map<String, dynamic>> scanQrCode(String barcode) async {
    developer.log('Barcodenya: ${barcode}');
    try {
      final response = await _dio.post(
        '/security/visits/scan',
        data: {'barcode': barcode},
      );
      developer.log('Scan QR Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Scan QR Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Check In visitor
  Future<Map<String, dynamic>> checkInVisitor({
    required String barcode,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/security/visits/check-in',
        data: {'barcode': barcode, if (notes != null) 'notes': notes},
      );
      developer.log('Check In Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Check In Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Check Out visitor
  Future<Map<String, dynamic>> checkOutVisitor({
    String? barcode,
    String? visitId,
    String? notes,
  }) async {
    try {
      if (barcode == null && visitId == null) {
        throw 'Barcode atau Visit ID harus diisi';
      }

      final response = await _dio.post(
        '/security/visits/check-out',
        data: {
          if (barcode != null) 'barcode': barcode,
          if (visitId != null) 'visit_id': visitId,
          if (notes != null) 'notes': notes,
        },
      );
      developer.log('Check Out Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Check Out Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Manual Check Out from dashboard (if visitor forgot to scan)
  Future<Map<String, dynamic>> manualCheckOut({
    required String visitId,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/security/visits/$visitId/manual-checkout',
        data: {if (notes != null) 'notes': notes},
      );
      developer.log('Manual Check Out Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Manual Check Out Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Get visit history with filters
  Future<Map<String, dynamic>> getVisitHistory({
    String? startDate,
    String? endDate,
    String? status,
    String? scheduleId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/security/visits/history',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (status != null) 'status': status,
          if (scheduleId != null) 'schedule_id': scheduleId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      developer.log('Visit History Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Visit History Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Check for overstay visitors (manual trigger or scheduled)
  Future<Map<String, dynamic>> checkOverstayVisitors() async {
    try {
      final response = await _dio.post('/visits/check-overstay');
      developer.log('Check Overstay Response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      developer.log('Check Overstay Error: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Get current visitors (today's active visitors)
  Future<List<dynamic>> getCurrentVisitors() async {
    try {
      final dashboard = await getSecurityDashboard();
      final data = dashboard['data'] as Map<String, dynamic>;
      return data['current_visitors'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get today's visit schedules
  Future<List<dynamic>> getTodaySchedules() async {
    try {
      final dashboard = await getSecurityDashboard();
      final data = dashboard['data'] as Map<String, dynamic>;
      return data['today_schedules'] as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get security stats
  Future<Map<String, dynamic>> getSecurityStats() async {
    try {
      final dashboard = await getSecurityDashboard();
      final data = dashboard['data'] as Map<String, dynamic>;
      return data['stats'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get parent/student visit schedules
  Future<Map<String, dynamic>> getParentVisitSchedules() async {
    try {
      final myVisitsResponse = await _dio.get(
        '/teacher/parent/visits/my-visits',
      );
      final availableSchedulesResponse = await _dio.get(
        '/teacher/parent/visits/available-schedules',
      );

      developer.log('📋 My Visits Response: ${myVisitsResponse.data}');
      developer.log(
        '📋 Available Schedules Response: ${availableSchedulesResponse.data}',
      );

      // Ambil data dengan aman
      final myVisitsData = myVisitsResponse.data['data'];
      final myVisitsList =
          (myVisitsData is Map && myVisitsData['data'] is List)
              ? myVisitsData['data'] as List<dynamic>
              : (myVisitsData is List ? myVisitsData : []);

      final availableSchedulesData = availableSchedulesResponse.data['data'];
      final availableSchedulesList =
          (availableSchedulesData is List) ? availableSchedulesData : [];

      return {
        'upcoming_visits': myVisitsList,
        'active_schedules': availableSchedulesList,
      };
    } on DioException catch (e) {
      developer.log('❌ Error getting visit schedules: ${e.message}');
      developer.log('❌ Status Code: ${e.response?.statusCode}');
      developer.log('❌ Response Body: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Get QR Code untuk visit log tertentu
  Future<Map<String, dynamic>> getVisitQRCode(String visitLogId) async {
    try {
      final response = await _dio.get(
        '/teacher/parent/visits/get-qr-code/$visitLogId',
      );

      developer.log('📋 QR Code Response: ${response.data}');

      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      developer.log('❌ Error getting QR code: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Update method di api_service.dart
  Future<Map<String, dynamic>> generateVisitQRCode({
    required String scheduleId,
    required String studentId,
    required String visitPurpose,
  }) async {
    try {
      final response = await _dio.post(
        '/teacher/parent/visits/generate-qr',
        data: {
          'visit_schedule_id': scheduleId, // ✅ Sesuaikan dengan backend
          'student_id': studentId,
          'visit_purpose': visitPurpose,
        },
      );

      developer.log('✅ Generate QR Response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      developer.log('❌ Error generating QR code: ${e.message}');
      developer.log('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  /// Cancel visit
  Future<void> cancelVisit(String visitId) async {
    try {
      await _dio.post('/teacher/parent/visits/$visitId/cancel');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get specific visit log detail
  Future<Map<String, dynamic>> getVisitLogDetail(String visitId) async {
    try {
      final response = await _dio.get('/parent/visit-log/$visitId');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Request new visit (jika ada fitur request dari parent)
  Future<Map<String, dynamic>> requestVisit({
    required String scheduleId,
    required String studentId,
    required String visitPurpose,
  }) async {
    try {
      final response = await _dio.post(
        '/parent/visit-request',
        data: {
          'schedule_id': scheduleId,
          'student_id': studentId,
          'visit_purpose': visitPurpose,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
