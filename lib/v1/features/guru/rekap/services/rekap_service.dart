import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../core/services/base_service.dart';
import '../../../../core/config/backdoor_helper.dart';
import '../models/teacher_info_model.dart';
import '../models/schedule_model.dart' as schedule;
import '../models/teacher_info_model.dart' show ScheduleModel;
// import '../models/subject_info_model.dart';
// import '../models/schedule_model.dart' hide ScheduleModel;

class RekapService extends BaseService {
  static RekapService? _instance;
  bool _disposed = false;

  // Singleton pattern with disposal check
  factory RekapService() {
    if (_instance == null || _instance!._disposed) {
      _instance = RekapService._internal();

      // Register for URL refresh callbacks
      BackdoorHelper.registerRefreshCallback(() {
        _instance?.refreshDioInstance();
      });
    }
    return _instance!;
  }

  RekapService._internal();

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;

    // Unregister from URL refresh callbacks
    BackdoorHelper.unregisterRefreshCallback(() {
      refreshDioInstance();
    });

    super.dispose();

    if (_instance == this) {
      _instance = null;
    }
  }

  // Enhanced token management
  Future<String> _getTokenSafely() async {
    if (_disposed) throw StateError('Service disposed');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw AuthenticationException('Token tidak ditemukan atau kosong');
      }

      return token;
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Gagal mengambil token: $e');
    }
  }

  // Enhanced employee ID management with better type safety
  Future<String> _getEmployeeIdSafely() async {
    if (_disposed) throw StateError('Service disposed');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Try UUID format first (preferred)
      String? employeeId = prefs.getString('employee_id_uuid');

      if (employeeId != null && employeeId.isNotEmpty) {
        return employeeId;
      }

      // Fallback to integer format
      final intId = prefs.getInt('employee_id');
      if (intId != null && intId > 0) {
        return intId.toString();
      }

      throw Exception('Employee ID tidak ditemukan di SharedPreferences');
    } catch (e) {
      throw Exception('Gagal mengambil Employee ID: $e');
    }
  }

  // Enhanced teacher info retrieval with comprehensive error handling
  Future<TeacherInfoModel> getTeacherInfo() async {
    if (_disposed) throw StateError('Service disposed');

    // Check connectivity first
    if (!await hasInternetConnection()) {
      throw ConnectivityException();
    }

    try {
      final employeeId = await _getEmployeeIdSafely();
      final token = await _getTokenSafely();

      debugPrint('🔍 Fetching teacher info for employee ID: $employeeId');

      final response = await dio.get(
        '/employee',
        queryParameters: {'paginate': false},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'requiresAuth': true}, // Custom flag for interceptor
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Server returned status ${response.statusCode}',
          response.statusCode!,
        );
      }

      // Validate response structure
      if (response.data == null) {
        throw ServerException('Empty response from server', 200);
      }

      final dynamic results = response.data['results'];
      if (results == null) {
        throw ServerException('Missing results in response', 200);
      }

      final employees = results as List<dynamic>?;
      if (employees == null || employees.isEmpty) {
        throw Exception('Tidak ada data employee ditemukan');
      }

      // Find employee with better error handling
      Map<String, dynamic>? employeeData;

      try {
        employeeData =
            employees.firstWhere((emp) {
                  if (emp == null || emp['id'] == null) return false;
                  return emp['id'].toString() == employeeId;
                }, orElse: () => null)
                as Map<String, dynamic>?;
      } catch (e) {
        debugPrint('❌ Error finding employee: $e');
      }

      if (employeeData == null) {
        throw Exception('Employee dengan ID $employeeId tidak ditemukan');
      }

      // Validate employee data structure
      if (employeeData['user'] == null) {
        throw ServerException(
          'Invalid employee data structure: missing user data',
          200,
        );
      }

      final teacherInfo = TeacherInfoModel.fromJson(employeeData);
      debugPrint('✅ Teacher info loaded successfully: ${teacherInfo.name}');

      return teacherInfo;
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error in getTeacherInfo: $e');
      if (e is NetworkException) rethrow;
      throw NetworkException('Gagal memuat informasi guru: $e');
    }
  }

  // Enhanced subjects retrieval with better data validation
  Future<List<SubjectInfoModel>> getSubjectsWithClassInfo(
    String employeeId,
  ) async {
    if (_disposed) throw StateError('Service disposed');

    if (employeeId.isEmpty) {
      print('❌ Employee ID is empty');
      throw ArgumentError('Employee ID cannot be empty');
    }

    // Check connectivity first
    if (!await hasInternetConnection()) {
      throw ConnectivityException();
    }

    try {
      final token = await _getTokenSafely();

      debugPrint('🔍 Fetching subjects for employee ID: $employeeId');

      final response = await dio.get(
        '/mobile/teacher/subjects/$employeeId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'requiresAuth': true},
        ),
      );

      debugPrint('🔍 Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ServerException(
          'Server returned status ${response.statusCode}',
          response.statusCode!,
        );
      }

      // Validate response structure
      if (response.data == null) {
        throw ServerException('Empty response from server', 200);
      }

      final dynamic results = response.data['results'];
      if (results == null) {
        throw ServerException('Missing results in response', 200);
      }

      final subjectsData = results as List<dynamic>?;
      if (subjectsData == null) {
        debugPrint('⚠️ No subjects data found, returning empty list');
        return [];
      }

      debugPrint('📚 Processing ${subjectsData.length} subjects');

      final List<SubjectInfoModel> processedSubjects = [];

      for (int i = 0; i < subjectsData.length; i++) {
        try {
          final subjectData = subjectsData[i];

          if (subjectData == null || subjectData is! Map<String, dynamic>) {
            debugPrint('⚠️ Invalid subject data at index $i, skipping');
            continue;
          }

          final subjectName = _safeStringExtract(subjectData, 'mata_pelajaran');
          final className = _safeStringExtract(subjectData, 'kelas');
          final subjectId = _safeStringExtract(
            subjectData,
            'id',
            defaultValue: '0',
          );

          if (subjectName.isEmpty) {
            debugPrint('⚠️ Subject name is empty at index $i, skipping');
            continue;
          }

          final formattedLevel = _formatLevel(className);

          // Enhanced display name formatting
          String displayName;
          if (className.isNotEmpty && subjectName.isNotEmpty) {
            if (className.toLowerCase() == formattedLevel.toLowerCase()) {
              displayName = '$className - $subjectName';
            } else {
              displayName = '$className - $formattedLevel - $subjectName';
            }
          } else if (subjectName.isNotEmpty) {
            displayName = subjectName;
          } else {
            displayName = 'Subject $subjectId';
          }

          final subject = SubjectInfoModel(
            id: subjectId,
            mataPelajaran: subjectName,
            kelasName: className,
            level: formattedLevel,
            displayName: displayName,
          );

          processedSubjects.add(subject);
          debugPrint('📖 Processed subject: ${subject.displayName}');
        } catch (e) {
          debugPrint('❌ Error processing subject at index $i: $e');
          // Continue processing other subjects
          continue;
        }
      }

      if (processedSubjects.isEmpty && subjectsData.isNotEmpty) {
        debugPrint(
          '⚠️ No valid subjects could be processed from ${subjectsData.length} items',
        );
      }

      debugPrint(
        '✅ Successfully processed ${processedSubjects.length} subjects',
      );
      return processedSubjects;
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error in getSubjectsWithClassInfo: $e');
      if (e is NetworkException) rethrow;
      throw NetworkException('Gagal memuat mata pelajaran: $e');
    }
  }

  // Enhanced schedule retrieval
  Future<List<schedule.ScheduleModel>> getSchedulesForSubject(
    String subjectTeacherId,
  ) async {
    if (_disposed) throw StateError('Service disposed');

    if (subjectTeacherId.isEmpty) {
      throw ArgumentError('Subject teacher ID cannot be empty');
    }

    // Check connectivity first
    if (!await hasInternetConnection()) {
      throw ConnectivityException();
    }

    try {
      final token = await _getTokenSafely();

      debugPrint(
        '🔍 Fetching schedules for subject_teacher_id: $subjectTeacherId',
      );

      final response = await dio.get(
        '/mobile/teacher/schedules/$subjectTeacherId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'requiresAuth': true},
        ),
      );

      // === TAMBAHKAN LOGGING DEBUG INI ===
      debugPrint('🔍 SCHEDULE DEBUG INFO:');
      debugPrint('🔍 Response Status: ${response.statusCode}');
      debugPrint('🔍 Full Response Data: ${response.data}');
      debugPrint('🔍 Response Type: ${response.data.runtimeType}');

      if (response.data != null) {
        debugPrint('🔍 Response Keys: ${(response.data as Map).keys.toList()}');

        if (response.data['results'] != null) {
          debugPrint(
            '🔍 Results Type: ${response.data['results'].runtimeType}',
          );
          debugPrint(
            '🔍 Results Length: ${(response.data['results'] as List).length}',
          );
          debugPrint('🔍 Results Content: ${response.data['results']}');

          // Debug setiap item dalam results
          final schedulesList = response.data['results'] as List;
          for (int i = 0; i < schedulesList.length; i++) {
            debugPrint('🔍 Schedule Item $i: ${schedulesList[i]}');
            debugPrint(
              '🔍 Schedule Item $i Type: ${schedulesList[i].runtimeType}',
            );
          }
        } else {
          debugPrint('🔍 Results is NULL - no schedule data returned');
        }
      } else {
        debugPrint('🔍 Response data is NULL');
      }
      // === AKHIR LOGGING DEBUG ===

      if (response.statusCode != 200) {
        throw ServerException(
          'Server returned status ${response.statusCode}',
          response.statusCode!,
        );
      }

      // Validate response structure
      if (response.data == null) {
        throw ServerException('Empty response from server', 200);
      }

      final dynamic results = response.data['results'];
      if (results == null) {
        debugPrint('⚠️ No schedule results found, returning empty list');
        return [];
      }

      final schedulesData = results as List<dynamic>?;
      if (schedulesData == null || schedulesData.isEmpty) {
        debugPrint(
          '📋 No schedules found for subject teacher $subjectTeacherId',
        );
        return [];
      }

      debugPrint('📋 Processing ${schedulesData.length} schedules');

      final List<schedule.ScheduleModel> processedSchedules = [];

      for (int i = 0; i < schedulesData.length; i++) {
        try {
          final scheduleData = schedulesData[i];

          if (scheduleData == null || scheduleData is! Map<String, dynamic>) {
            debugPrint('⚠️ Invalid schedule data at index $i, skipping');
            continue;
          }

          final scheduleObj = schedule.ScheduleModel.fromJson(scheduleData);
          processedSchedules.add(scheduleObj);

          debugPrint(
            '📅 Processed schedule: ${scheduleObj.day} ${scheduleObj.jamMulai}-${scheduleObj.jamSelesai}',
          );
        } catch (e) {
          debugPrint('❌ Error processing schedule at index $i: $e');
          // Continue processing other schedules
          continue;
        }
      }

      if (processedSchedules.isEmpty && schedulesData.isNotEmpty) {
        debugPrint(
          '⚠️ No valid schedules could be processed from ${schedulesData.length} items',
        );
      }

      debugPrint(
        '✅ Successfully processed ${processedSchedules.length} schedules',
      );
      return processedSchedules;
    } on DioException catch (e) {
      throw handleDioException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error in getSchedulesForSubject: $e');
      if (e is NetworkException) rethrow;
      throw NetworkException('Gagal memuat jadwal: $e');
    }
  }

  // Mendapatkan statistik presensi untuk mata pelajaran tertentu - FIXED VERSION
  Future<Map<String, int>> getAttendanceStats({
    required dynamic teacherId,
    dynamic subjectId,
    String? kelasName,
  }) async {
    try {
      final token = await _getTokenSafely();
      if (token.isEmpty) throw Exception('Token tidak ditemukan');

      print(
        '🔍 Mengambil statistik presensi untuk guru ID: $teacherId (${teacherId.runtimeType})',
      );
      if (subjectId != null) print('   - Subject Teacher ID: $subjectId');

      // Set timeout untuk request
      final cancelToken = CancelToken();
      Timer(Duration(seconds: 15), () {
        cancelToken.cancel('Request timeout after 15 seconds');
      });

      // Gunakan endpoint baru yang lebih efisien dengan subject_teacher_id
      final response = await dio.get(
        '/attendance/teacher/$teacherId/stats',
        queryParameters:
            subjectId != null ? {'subject_teacher_id': subjectId} : {},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) {
            // Accept both 200 and 404 as valid responses
            return status != null && (status == 200 || status == 404);
          },
        ),
        cancelToken: cancelToken,
      );

      print('📊 Attendance stats response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        print('📊 No attendance data found for this teacher/subject');
        return {
          'total_presensi': 0,
          'hadir': 0,
          'sakit': 0,
          'izin': 0,
          'alpha': 0,
        };
      }

      if (response.statusCode == 200) {
        final data = response.data;
        print('📦 Attendance stats response data: $data');

        // Handle different response formats
        Map<String, dynamic> results;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('results')) {
            results = data['results'] as Map<String, dynamic>;
          } else {
            results = data;
          }
        } else {
          throw Exception(
            'Invalid response format: expected Map, got ${data.runtimeType}',
          );
        }

        final stats = {
          'total_presensi': _parseIntSafely(results['total_presensi']),
          'hadir': _parseIntSafely(results['hadir']),
          'sakit': _parseIntSafely(results['sakit']),
          'izin': _parseIntSafely(results['izin']),
          'alpha': _parseIntSafely(results['alpha']),
        };

        print('✅ Attendance stats retrieved: $stats');
        return stats;
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        print('❌ Request cancelled due to timeout');
        throw Exception('Request timeout - silakan coba lagi');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      }

      if (e.response?.statusCode == 404) {
        print('📊 No attendance data found (404)');
        return {
          'total_presensi': 0,
          'hadir': 0,
          'sakit': 0,
          'izin': 0,
          'alpha': 0,
        };
      }

      print('❌ Dio error in getAttendanceStats: ${e.response?.data}');
      throw Exception(
        'Network error: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      print('❌ Error fetching attendance stats: $e');

      // Don't throw error, return empty stats for graceful degradation
      print('📊 Returning empty stats due to error');
      return {
        'total_presensi': 0,
        'hadir': 0,
        'sakit': 0,
        'izin': 0,
        'alpha': 0,
      };
    }
  }

  // Helper method untuk parsing integer dengan aman
  int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper method for safe string extraction
  String _safeStringExtract(
    Map<String, dynamic> data,
    String key, {
    String defaultValue = '',
  }) {
    try {
      final value = data[key];
      if (value == null) return defaultValue;
      return value.toString().trim();
    } catch (e) {
      debugPrint('⚠️ Error extracting string for key "$key": $e');
      return defaultValue;
    }
  }

  // Helper method for safe integer extraction
  int _safeIntExtract(
    Map<String, dynamic> data,
    String key, {
    int defaultValue = 0,
  }) {
    try {
      final value = data[key];
      if (value == null) return defaultValue;

      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }

      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ Error extracting int for key "$key": $e');
      return defaultValue;
    }
  }

  // Helper method to get default attendance stats
  Map<String, int> _getDefaultAttendanceStats() {
    return {'total_presensi': 0, 'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0};
  }

  // Helper method for detailed attendance debug logging
  void _logAttendanceDebugInfo(
    Map<String, dynamic> responseData,
    Map<String, int> stats,
  ) {
    debugPrint('🔍 DEBUG: Detailed attendance stats analysis:');
    debugPrint('🔍 Response type: ${responseData.runtimeType}');
    debugPrint('🔍 Response keys: ${responseData.keys.toList()}');
    debugPrint('🔍 Processed stats: $stats');

    // Log attendance records if available
    if (responseData['attendance_records'] != null) {
      final attendanceRecords =
          responseData['attendance_records'] as List<dynamic>? ?? [];
      debugPrint('🔍 Total attendance records: ${attendanceRecords.length}');

      if (attendanceRecords.isNotEmpty) {
        // Group records by status for detailed analysis
        final statusCounts = <String, int>{};
        final dateGroups = <String, List<dynamic>>{};

        for (var record in attendanceRecords) {
          if (record is Map<String, dynamic>) {
            final status = record['status']?.toString() ?? 'unknown';
            final date = record['attendance_date']?.toString() ?? 'unknown';

            statusCounts[status] = (statusCounts[status] ?? 0) + 1;

            if (!dateGroups.containsKey(date)) {
              dateGroups[date] = [];
            }
            dateGroups[date]!.add(record);
          }
        }

        debugPrint('🔍 Status distribution from records: $statusCounts');
        debugPrint('🔍 Records grouped by ${dateGroups.length} dates');

        // Show sample records for verification
        final hadirRecords =
            attendanceRecords
                .where(
                  (r) => r is Map<String, dynamic> && r['status'] == 'HADIR',
                )
                .take(3)
                .toList();

        if (hadirRecords.isNotEmpty) {
          debugPrint('🔍 Sample HADIR records:');
          for (int i = 0; i < hadirRecords.length; i++) {
            final record = hadirRecords[i] as Map<String, dynamic>;
            final studentName =
                record['student']?['user']?['name'] ?? 'Unknown';
            final date = record['attendance_date'] ?? 'Unknown';
            debugPrint('🔍   ${i + 1}. $studentName on $date');
          }
        }
      }
    } else {
      debugPrint(
        '🔍 No attendance_records field in response - stats only mode',
      );
    }
  }

  // Enhanced level formatting with more comprehensive mappings
  String _formatLevel(String level) {
    if (level.isEmpty) return '';

    final normalizedLevel = level.trim().toUpperCase();

    switch (normalizedLevel) {
      case 'TODDLER':
        return 'Toddler';
      case 'PLAYGROUP':
        return 'Playgroup';
      case 'KINDERGARTEN_1':
      case 'KINDERGARTEN 1':
      case 'TK A':
        return 'TK A';
      case 'KINDERGARTEN_2':
      case 'KINDERGARTEN 2':
      case 'TK B':
        return 'TK B';
      case 'ELEMENTARY_SCHOOL':
      case 'ELEMENTARY SCHOOL':
      case 'SD':
        return 'SD';
      case 'JUNIOR_HIGH_SCHOOL':
      case 'JUNIOR HIGH SCHOOL':
      case 'SMP':
        return 'SMP';
      case 'SENIOR_HIGH_SCHOOL':
      case 'SENIOR HIGH SCHOOL':
      case 'SMA':
        return 'SMA';
      default:
        // Return the original level with proper capitalization
        return level
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty
                      ? ''
                      : word[0].toUpperCase() + word.substring(1).toLowerCase(),
            )
            .join(' ');
    }
  }

  // Check if service is disposed
  bool get isDisposed => _disposed;
}
