import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../models/attendance_model.dart';

class RekapKehadiranService {
  late Dio _dio;

  RekapKehadiranService() {
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

    // Add token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          print('❌ Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('bearer_token');

      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  Future<List<AttendanceModel>> getStudentAttendance({
    required String studentId,
    String? month,
    String? year,
    String? status,
    int limit = 50,
  }) async {
    try {
      print('📡 Fetching attendance for student: $studentId');

      // Build query parameters
      Map<String, dynamic> queryParams = {'limit': limit, 'paginate': false};

      if (month != null && month != '0') {
        queryParams['month'] = month;
      }
      if (year != null && year.isNotEmpty) {
        queryParams['year'] = year;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      print('📡 Query params: $queryParams');

      // Menggunakan endpoint student attendance history yang sudah tersedia
      final response = await _dio.get(
        '/mobile/student/attendance/history/$studentId',
        queryParameters: queryParams,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data keys: ${response.data?.keys}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['results'] != null && data['results']['data'] != null) {
          List<dynamic> attendanceList = data['results']['data'];

          print('📡 Found ${attendanceList.length} attendance records');

          return attendanceList
              .map((json) => AttendanceModel.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      throw Exception('Gagal mengambil data kehadiran: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats({
    required String studentId,
    String? month,
    String? year,
  }) async {
    try {
      final attendanceList = await getStudentAttendance(
        studentId: studentId,
        month: month,
        year: year,
      );

      Map<String, int> stats = {'HADIR': 0, 'SAKIT': 0, 'IZIN': 0, 'ALPHA': 0};

      for (var attendance in attendanceList) {
        stats[attendance.status] = (stats[attendance.status] ?? 0) + 1;
      }

      int totalDays = attendanceList.length;
      int hadirCount = stats['HADIR'] ?? 0;
      double percentage = totalDays > 0 ? (hadirCount / totalDays) * 100 : 0.0;

      return {
        'stats': stats,
        'total_days': totalDays,
        'hadir_count': hadirCount,
        'percentage': percentage,
      };
    } catch (e) {
      print('❌ Error getting attendance stats: $e');
      throw Exception('Gagal mengambil statistik kehadiran: $e');
    }
  }
}
