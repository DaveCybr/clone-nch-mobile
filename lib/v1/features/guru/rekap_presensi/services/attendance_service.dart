import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tambah_presensi/models/attendance_model.dart';
import '../../../../core/config/app_config.dart';

class AttendanceService {
  late final Dio _dio;

  AttendanceService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      ),
    );

    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authorization header if token exists in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('Debug: Request ${options.method} ${options.path}');
          print('Debug: Headers: ${options.headers}');
          print('Debug: Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('Debug: Response ${response.statusCode}: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print(
            'Debug: Error ${error.response?.statusCode}: ${error.response?.data}',
          );
          handler.next(error);
        },
      ),
    );
  }

  Future<List<AttendanceModel>> getAttendances({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/attendance',
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': search,
          'status': status,
        },
      );

      final List<dynamic> data = response.data['results']['data'] ?? [];
      return data.map((item) => AttendanceModel.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AttendanceModel> createAttendance(AttendanceModel attendance) async {
    try {
      final response = await _dio.post(
        '/attendance',
        data: attendance.toJson(),
      );
      return AttendanceModel.fromJson(response.data['result']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AttendanceModel>> createBulkAttendance(
    List<AttendanceModel> attendances,
  ) async {
    try {
      // Pastikan semua attendance memiliki schedule_id dan date yang sama
      if (attendances.isEmpty) {
        throw Exception('Tidak ada data attendance untuk disimpan');
      }

      final firstAttendance = attendances.first;
      final scheduleId = firstAttendance.scheduleId.toString();
      final date =
          firstAttendance.attendanceTime.toIso8601String().split(
            'T',
          )[0]; // YYYY-MM-DD format

      // Group attendances by status
      Map<String, List<String>> groupedByStatus = {};

      for (var attendance in attendances) {
        final status = attendance.status;
        if (!groupedByStatus.containsKey(status)) {
          groupedByStatus[status] = [];
        }
        groupedByStatus[status]!.add(attendance.studentId.toString());
      }

      List<AttendanceModel> allCreatedAttendances = [];

      // Send request for each status group
      for (var entry in groupedByStatus.entries) {
        final status = entry.key;
        final studentIds = entry.value;

        final requestData = {
          'schedule_id': scheduleId,
          'date': date,
          'status': status,
          'student_ids': studentIds,
        };

        print('Debug: Sending request data: $requestData');

        final response = await _dio.post(
          '/mobile/teacher/schedule/student/attendance',
          data: requestData,
        );

        print('Debug: Received response: ${response.data}');

        // Parse response berdasarkan struktur yang dikembalikan API
        if (response.data != null && response.data is Map) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap['status'] == 'success') {
            final responseData = responseMap['data'];
            if (responseData != null && responseData is Map) {
              final dataMap = responseData as Map<String, dynamic>;
              if (dataMap['attendances'] != null &&
                  dataMap['attendances'] is List) {
                final List<dynamic> attendanceList =
                    dataMap['attendances'] as List<dynamic>;
                try {
                  for (int i = 0; i < attendanceList.length; i++) {
                    final item = attendanceList[i];
                    print(
                      'Debug: Processing attendance item $i: $item (${item.runtimeType})',
                    );

                    if (item is Map<String, dynamic>) {
                      final attendance = AttendanceModel.fromJson(item);
                      allCreatedAttendances.add(attendance);
                    } else {
                      print(
                        'Debug: Unexpected attendance item type at index $i: ${item.runtimeType}',
                      );
                      print('Debug: Item content: $item');
                      throw Exception(
                        'Invalid attendance data format at index $i',
                      );
                    }
                  }
                } catch (e) {
                  print('Debug: Error parsing attendance list: $e');
                  print('Debug: Attendance list: $attendanceList');
                  print('Debug: List length: ${attendanceList.length}');
                  rethrow;
                }
              } else {
                print('Debug: No attendances data in response or wrong type');
                print(
                  'Debug: attendances field: ${dataMap['attendances']} (${dataMap['attendances'].runtimeType})',
                );
              }
            } else {
              print('Debug: Response data is null or not a map');
              print(
                'Debug: responseData: $responseData (${responseData.runtimeType})',
              );
            }
          } else {
            print('Debug: API returned error status: ${responseMap}');
            final message = responseMap['message'];
            throw Exception(message ?? 'Unknown error from API');
          }
        } else {
          print('Debug: Response data is null or not a map');
          print(
            'Debug: response.data: ${response.data} (${response.data.runtimeType})',
          );
          throw Exception('Invalid response format');
        }
      }

      return allCreatedAttendances;
    } on DioException catch (e) {
      print('Debug: DioException in createBulkAttendance: $e');
      print('Debug: Response data: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Debug: General exception in createBulkAttendance: $e');
      print('Debug: Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<AttendanceModel> updateAttendance(
    int id,
    AttendanceModel attendance,
  ) async {
    try {
      final response = await _dio.put(
        '/attendance/$id',
        data: attendance.toJson(),
      );
      return AttendanceModel.fromJson(response.data['result']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await _dio.delete('/attendance/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Helper method to handle Dio errors
  dynamic _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with an error
      throw Exception(error.response?.data['message'] ?? 'Terjadi kesalahan');
    } else {
      // Network or other error
      throw Exception('Gagal terhubung ke server');
    }
  }
}
