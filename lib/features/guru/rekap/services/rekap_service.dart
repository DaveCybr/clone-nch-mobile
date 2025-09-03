import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../models/teacher_info_model.dart';
import '../models/schedule_model.dart';

// Extension untuk membantu dengan null safety
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

class RekapService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {'Accept': 'application/json'},
    ),
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Helper method to get employee ID in the correct format
  Future<dynamic> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to get employee ID as UUID string first (newer format)
    dynamic employeeId = prefs.getString('employee_id_uuid');

    // If not found, try to get as integer (older format)
    if (employeeId == null) {
      employeeId = prefs.getInt('employee_id');
    }

    return employeeId;
  }

  // Mendapatkan informasi guru yang login
  Future<TeacherInfoModel> getTeacherInfo() async {
    try {
      print('🔍 Loading teacher info...');
      final prefs = await SharedPreferences.getInstance();

      // Try to get employee ID as UUID string first (newer format)
      dynamic employeeId = prefs.getString('employee_id_uuid');

      // If not found, try to get as integer (older format)
      if (employeeId == null) {
        employeeId = prefs.getInt('employee_id');
      }

      if (employeeId == null) {
        throw Exception('Employee ID tidak ditemukan di SharedPreferences');
      }

      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      print(
        '🔍 Mengambil info guru untuk employee ID: $employeeId (${employeeId.runtimeType})',
      );

      // Ambil data employee dengan user dan role
      final response = await _dio.get(
        '/employee',
        queryParameters: {'paginate': false},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📊 Employee response status: ${response.statusCode}');
      print('📦 Employee response data: ${response.data}');

      if (response.statusCode == 200) {
        final employees = response.data['results'] as List<dynamic>;

        // Find employee by ID
        final employeeData = employees.firstWhere(
          (emp) => emp['id'].toString() == employeeId.toString(),
          orElse:
              () =>
                  throw Exception(
                    'Employee dengan ID $employeeId tidak ditemukan',
                  ),
        );

        print('✅ Employee data found: ${employeeData['user']['name']}');
        return TeacherInfoModel.fromJson(employeeData);
      } else {
        throw Exception('Gagal mengambil data employee');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      }
      print('❌ Dio error in getTeacherInfo: ${e.response?.data}');
      throw Exception('Error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      print('❌ General error in getTeacherInfo: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Mendapatkan mata pelajaran yang diajar guru dengan format (kelas) - (jenjang)
  Future<List<SubjectInfoModel>> getSubjectsWithClassInfo(
    dynamic employeeId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      print(
        '🔍 Mengambil mata pelajaran untuk employee ID: $employeeId (${employeeId.runtimeType})',
      );

      // Step 1: Ambil subjects yang diajar guru
      final subjectsResponse = await _dio.get(
        '/mobile/teacher/subjects/$employeeId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📊 Subjects response status: ${subjectsResponse.statusCode}');

      if (subjectsResponse.statusCode != 200) {
        throw Exception('Gagal mengambil data mata pelajaran');
      }

      final subjectsData = subjectsResponse.data['results'] as List<dynamic>;
      print('📚 Raw subjects data: $subjectsData');

      final List<SubjectInfoModel> result = [];

      for (var subjectData in subjectsData) {
        final subjectName = subjectData['mata_pelajaran']?.toString() ?? '';
        final className =
            subjectData['kelas']?.toString() ??
            ''; // Gunakan 'kelas' bukan 'nama_kelas'
        final level =
            className; // Gunakan kelas sebagai level jika tidak ada field jenjang terpisah

        // Format level untuk display yang lebih user-friendly
        final formattedLevel = _formatLevel(level);

        // Format display name: (nama kelas) - (mata pelajaran)
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
          displayName = 'Subject ${subjectData['id'] ?? 'Unknown'}';
        }

        result.add(
          SubjectInfoModel(
            id: subjectData['id']?.toString() ?? '0',
            mataPelajaran: subjectName,
            kelasName: className,
            level: formattedLevel,
            displayName: displayName,
          ),
        );
      }

      print('✅ Processed ${result.length} subjects with class info');
      for (var subject in result) {
        print('📖 Subject: ${subject.displayName}');
      }

      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      }
      print('❌ Dio error in getSubjectsWithClassInfo: ${e.response?.data}');
      throw Exception('Error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      print('❌ General error in getSubjectsWithClassInfo: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Mendapatkan jadwal untuk subject teacher tertentu
  Future<List<ScheduleModel>> getSchedulesForSubject(
    dynamic subjectTeacherId,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      print(
        '🔍 Mengambil jadwal untuk subject_teacher_id: $subjectTeacherId (${subjectTeacherId.runtimeType})',
      );

      final response = await _dio.get(
        '/mobile/teacher/schedules/$subjectTeacherId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📊 Schedule response status: ${response.statusCode}');
      print('📦 Schedule response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['results'] ?? [];
        print('📋 Raw schedule data: $data');

        final schedules =
            data.map((json) => ScheduleModel.fromJson(json)).toList();

        print('✅ Parsed ${schedules.length} schedules');
        for (var schedule in schedules) {
          print(
            '📅 Schedule: ${schedule.day} ${schedule.jamMulai}-${schedule.jamSelesai} (${schedule.mataPelajaran})',
          );
        }

        return schedules;
      } else {
        throw Exception('Gagal mengambil jadwal');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      }
      print('❌ Dio error in getSchedulesForSubject: ${e.response?.data}');
      throw Exception('Error: ${e.response?.data['message'] ?? e.message}');
    } catch (e) {
      print('❌ General error in getSchedulesForSubject: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Mendapatkan statistik presensi untuk mata pelajaran tertentu - OPTIMIZED VERSION
  Future<Map<String, int>> getAttendanceStats({
    required dynamic teacherId,
    dynamic subjectId,
    String? kelasName,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      print(
        '🔍 Mengambil statistik presensi untuk guru ID: $teacherId (${teacherId.runtimeType})',
      );
      if (subjectId != null) print('   - Subject Teacher ID: $subjectId');

      // Gunakan endpoint baru yang lebih efisien dengan subject_teacher_id
      final response = await _dio.get(
        '/attendance/teacher/$teacherId/stats',
        queryParameters:
            subjectId != null ? {'subject_teacher_id': subjectId} : {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📊 Attendance stats response status: ${response.statusCode}');
      print('📦 Attendance stats response data: ${response.data}');

      if (response.statusCode == 200) {
        final results = response.data['results'] as Map<String, dynamic>;

        // 🔍 DEBUG: Tampilkan data mentah untuk debug 4 data hadir
        print('🔍 DEBUG: Raw attendance stats response:');
        print('🔍 Response type: ${response.data.runtimeType}');
        print('🔍 Response data: ${response.data}');
        print('🔍 Results type: ${results.runtimeType}');
        print('🔍 Results content: $results');

        // Cek apakah ada data detail attendance records
        if (response.data['attendance_records'] != null) {
          print('🔍 DEBUG: Found attendance_records in response');
          final attendanceRecords =
              response.data['attendance_records'] as List<dynamic>;
          print(
            '🔍 DEBUG: Total attendance records: ${attendanceRecords.length}',
          );

          // Group by date to see what dates have hadir records
          Map<String, List<dynamic>> recordsByDate = {};
          Map<String, int> statusCounts = {};

          for (var record in attendanceRecords) {
            final date = record['attendance_date'] ?? 'unknown';
            final status = record['status'] ?? 'unknown';

            // Group by date
            if (!recordsByDate.containsKey(date)) {
              recordsByDate[date] = [];
            }
            recordsByDate[date]!.add(record);

            // Count by status
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          print('🔍 DEBUG: Status distribution: $statusCounts');
          print('🔍 DEBUG: Records by date:');
          recordsByDate.forEach((date, records) {
            print('🔍   📅 $date: ${records.length} records');

            // Show detail for HADIR records
            final hadirRecords = records.where((r) => r['status'] == 'HADIR');
            if (hadirRecords.isNotEmpty) {
              print('🔍     ✅ HADIR records on $date:');
              for (var hadirRecord in hadirRecords.take(3)) {
                // Show first 3
                final studentName =
                    hadirRecord['student']?['user']?['name'] ?? 'Unknown';
                final subjectName =
                    hadirRecord['schedule']?['subject_teacher']?['subject_semester']?['subject']?['name'] ??
                    'Unknown';
                print('🔍       - $studentName ($subjectName)');
              }
            }
          });
        } else {
          print(
            '🔍 DEBUG: No attendance_records field in response - stats only',
          );
        }

        final stats = {
          'total_presensi': (results['total_presensi'] as num?)?.toInt() ?? 0,
          'hadir': (results['hadir'] as num?)?.toInt() ?? 0,
          'sakit': (results['sakit'] as num?)?.toInt() ?? 0,
          'izin': (results['izin'] as num?)?.toInt() ?? 0,
          'alpha': (results['alpha'] as num?)?.toInt() ?? 0,
        };

        print('✅ Attendance stats retrieved: $stats');
        print(
          '🔍 DEBUG: The 4 HADIR records should be visible in the debug output above',
        );
        return stats;
      } else {
        throw Exception('Gagal mengambil statistik presensi');
      }
    } catch (e) {
      print('❌ Error fetching attendance stats: $e');

      // Return empty stats instead of throwing error
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

  // Helper untuk format level/jenjang
  String _formatLevel(String level) {
    switch (level) {
      case 'TODDLER':
        return 'Toddler';
      case 'PLAYGROUP':
        return 'Playgroup';
      case 'KINDERGARTEN_1':
        return 'TK A';
      case 'KINDERGARTEN_2':
        return 'TK B';
      case 'ELEMENTARY_SCHOOL':
        return 'SD';
      case 'JUNIOR_HIGH_SCHOOL':
        return 'SMP';
      case 'SENIOR_HIGH_SCHOOL':
        return 'SMA';
      default:
        return level;
    }
  }
}
