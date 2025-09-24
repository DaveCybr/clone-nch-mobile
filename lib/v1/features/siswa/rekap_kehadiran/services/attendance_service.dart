import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final Dio _dio = Dio();

  Future<List<AttendanceModel>> getStudentAttendance() async {
    try {
      // Get student ID and token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Debug: Check all stored keys
      print('🔍 All SharedPreferences keys: ${prefs.getKeys().toList()}');

      final studentId = prefs.getString('student_id_uuid');
      final token = prefs.getString('auth_token');

      // Debug: Check various potential student ID keys
      print('🔍 student_id_uuid: $studentId');
      print('🔍 student_id: ${prefs.getString('student_id')}');
      print('🔍 user_id: ${prefs.getString('user_id')}');
      print('🔍 auth_token: ${token?.substring(0, 20) ?? 'null'}...');

      if (studentId == null) {
        throw Exception('Student ID tidak ditemukan. Silakan login ulang.');
      }

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      print('📊 Loading attendance for student: $studentId');

      final url =
          '${AppConfig.baseUrl}/mobile/student/attendance/history/$studentId';
      print('📊 Requesting URL: $url');
      print('📊 Token: ${token.substring(0, 20)}...');

      // Gunakan endpoint attendance history yang sudah tersedia
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        queryParameters: {'limit': 50},
      );

      if (response.statusCode == 200) {
        print('📊 Attendance API response received');
        final data = response.data;

        if (data != null &&
            data['results'] != null &&
            data['results']['data'] != null) {
          final List<dynamic> attendanceData = data['results']['data'];

          List<AttendanceModel> attendanceList =
              attendanceData.map((item) {
                // Parse data sesuai format dari backend
                return AttendanceModel.fromJson(item);
              }).toList();

          print(
            '📊 Successfully parsed ${attendanceList.length} attendance records',
          );
          return attendanceList;
        } else {
          print('📊 No attendance data found in response');
          return [];
        }
      } else {
        throw Exception(
          'Gagal mengambil data kehadiran. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('📍 DioException caught: ${e.response?.statusCode}');

      if (e.response?.statusCode == 404) {
        throw Exception(
          'Endpoint data kehadiran tidak ditemukan. Fitur belum tersedia di backend.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Akses ditolak. Silakan login ulang.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Coba lagi nanti.');
      } else {
        throw Exception('Gagal mengambil data kehadiran: ${e.message}');
      }
    } catch (e) {
      print('📍 General exception caught: $e');

      if (e is Exception) {
        // Untuk error yang sudah jelas, lempar ulang
        if (e.toString().contains('Student ID tidak ditemukan') ||
            e.toString().contains('Token tidak ditemukan') ||
            e.toString().contains('Data kehadiran belum tersedia') ||
            e.toString().contains('Endpoint data kehadiran tidak ditemukan')) {
          rethrow;
        }
      }

      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }
}
