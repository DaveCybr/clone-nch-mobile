import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/kelas_model.dart';
import '../models/mata_pelajaran_model.dart';
import '../models/jadwal_model.dart';
import '../models/time_slot_model.dart';
import '../../../../core/config/app_config.dart';
import 'dart:developer' as developer;
import '../models/subject_model.dart';
import '../models/student_model.dart';
import 'package:dio/dio.dart';

class PresensiService {
  final Dio _dio = Dio();
  final String _baseUrl = AppConfig.baseUrl;

  PresensiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppConfig.token}',
    };

    // Add basic error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          print('API Error: ${error.response?.statusCode}');
          handler.next(error);
        },
      ),
    );
  }

  Future<List<dynamic>> fetchAvailableSchedules({
    required dynamic employeeId,
    required dynamic kelasId,
    required dynamic subjectId,
  }) async {
    try {
      final response = await _dio.get(
        '/attendance/schedules',
        queryParameters: {
          'employee_id': employeeId,
          'kelas_id': kelasId,
          'subject_id': subjectId,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> schedulesData = response.data['data'] as List;
        return schedulesData;
      } else {
        throw Exception('Response tidak valid dari server');
      }
    } catch (e) {
      throw Exception('Gagal mengambil jadwal tersedia: $e');
    }
  }

  Future<List<StudentModel>> fetchStudentsBySchedule(dynamic scheduleId) async {
    try {
      final response = await _dio.get(
        '/attendance/students',
        queryParameters: {'schedule_id': scheduleId},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> studentsData = response.data['data'] as List;
        return studentsData
            .map((studentData) => StudentModel.fromJson(studentData))
            .toList();
      } else {
        throw Exception('Response tidak valid dari server');
      }
    } catch (e) {
      throw Exception('Gagal mengambil daftar siswa: $e');
    }
  }

  Future<bool> submitAttendance({
    required dynamic scheduleId,
    required DateTime attendanceDate,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      final response = await _dio.post(
        '/attendance',
        data: {
          'schedule_id': scheduleId,
          'attendance_date': attendanceDate.toIso8601String(),
          'students': students,
        },
      );

      return response.data['status'] == 'success';
    } catch (e) {
      throw Exception('Gagal menyimpan presensi');
    }
  }

  Future<List<KelasModel>> fetchKelasByTeacher(dynamic teacherId) async {
    try {
      // Log detail request
      developer.log(
        'Fetching Kelas - All available classes',
        name: 'PresensiService',
        level: 900,
      );
      developer.log('Base URL: $_baseUrl', name: 'PresensiService', level: 900);
      developer.log(
        'Token: ${AppConfig.token}',
        name: 'PresensiService',
        level: 900,
      );

      // Gunakan endpoint untuk mengambil semua kelas yang tersedia (non-paginated)
      final response = await http.get(
        Uri.parse('$_baseUrl/kelas?paginate=false'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Log response details
      developer.log(
        'Kelas Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Kelas Response Body: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Cek apakah response memiliki struktur data yang benar
        if (jsonData is Map && jsonData.containsKey('results')) {
          // API menggunakan key 'results' bukan 'data'
          final resultsData = jsonData['results'];

          if (resultsData is Map && resultsData.containsKey('data')) {
            // Jika paginated, data ada di results.data
            List<dynamic> body = resultsData['data'];
            return body.map((json) => KelasModel.fromJson(json)).toList();
          } else if (resultsData is List) {
            // Jika non-paginated, results langsung berupa array
            return resultsData
                .map((json) => KelasModel.fromJson(json))
                .toList();
          } else {
            throw Exception('Invalid results format: $resultsData');
          }
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          List<dynamic> body = jsonData['data'];
          return body.map((json) => KelasModel.fromJson(json)).toList();
        } else if (jsonData is List) {
          // Jika response langsung berupa array
          return jsonData.map((json) => KelasModel.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format: ${response.body}');
        }
      } else {
        throw Exception('Gagal mengambil daftar kelas: ${response.body}');
      }
    } catch (e) {
      developer.log(
        'Error fetching kelas: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }

  Future<List<MataPelajaranModel>> fetchMataPelajaranByKelas(
    dynamic kelasId,
  ) async {
    try {
      // Log detail request
      developer.log(
        'Fetching Mata Pelajaran - Kelas ID: $kelasId',
        name: 'PresensiService',
        level: 900,
      );
      developer.log('Base URL: $_baseUrl', name: 'PresensiService', level: 900);
      developer.log(
        'Token: ${AppConfig.token}',
        name: 'PresensiService',
        level: 900,
      );

      // Ambil ID guru dari token atau config (support UUID)
      final teacherIdUuid = AppConfig.employeeIdUuid;
      final teacherIdInt = AppConfig.employeeId ?? 1;
      final teacherId = teacherIdUuid ?? teacherIdInt.toString();

      // Gunakan endpoint backend yang benar: /mobile/teacher/subjects/{id}
      final response = await _dio.get('/mobile/teacher/subjects/$teacherId');

      // Log response details
      developer.log(
        'Mata Pelajaran Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Mata Pelajaran Response Body: ${response.data}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Backend menggunakan key 'results' dan format data berbeda
        if (responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];

          // Filter hasil berdasarkan kelas dan transform ke format MataPelajaranModel
          List<MataPelajaranModel> mataPelajaranList = [];

          for (var item in results) {
            // Backend response format: {"id": 1, "mata_pelajaran": "Matematika", "kelas": "Toddler"}
            final kelasName = item['kelas']?.toString() ?? '';

            // Transform ke format MataPelajaranModel
            mataPelajaranList.add(
              MataPelajaranModel(
                id: item['id'],
                name: item['mata_pelajaran'],
                code:
                    item['mata_pelajaran']
                        .toString()
                        .substring(0, 3)
                        .toUpperCase(), // Generate code
                kelasId: kelasId, // Use the requested kelasId
                kelasCode:
                    kelasName
                        .substring(0, 3)
                        .toUpperCase(), // Generate code from kelas name
              ),
            );
          }

          developer.log(
            'Found ${mataPelajaranList.length} mata pelajaran for teacher',
            name: 'PresensiService',
            level: 900,
          );

          return mataPelajaranList;
        } else {
          // Jika tidak ada results, lempar exception
          throw Exception('Tidak ada mata pelajaran ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        final errorData = response.data;
        String errorMessage =
            errorData['message'] ?? 'Gagal mengambil daftar mata pelajaran';
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        'Error fetching mata pelajaran: $e',
        name: 'PresensiService',
        level: 1000,
      );

      // Detail error untuk DioException
      if (e is DioException) {
        developer.log(
          'DioException Type: ${e.type}',
          name: 'PresensiService',
          level: 1000,
        );
        developer.log(
          'DioException Message: ${e.message}',
          name: 'PresensiService',
          level: 1000,
        );
        if (e.response != null) {
          developer.log(
            'DioException Response: ${e.response?.data}',
            name: 'PresensiService',
            level: 1000,
          );
        }
      }

      rethrow;
    }
  }

  // Metode untuk mengambil jadwal berdasarkan mata pelajaran
  Future<List<JadwalModel>> fetchJadwalBySubject(dynamic subjectId) async { // Changed from int to dynamic to support UUID
    try {
      // Step 1: Dapatkan employee_id dari AppConfig (support UUID)
      final employeeIdUuid = AppConfig.employeeIdUuid;
      final employeeIdInt = AppConfig.employeeId ?? 1;
      final employeeId = employeeIdUuid ?? employeeIdInt.toString();

      print('Debug: fetchJadwalBySubject using employeeId: $employeeId');
      print('Debug: AppConfig.employeeIdUuid: ${AppConfig.employeeIdUuid}');
      print('Debug: AppConfig.employeeId: ${AppConfig.employeeId}');

      developer.log(
        'Fetching subjects for employee: $employeeId',
        name: 'PresensiService',
        level: 900,
      );

      // Step 2: Ambil daftar subject_teacher berdasarkan employee_id untuk mencari subject_teacher.id yang tepat
      final subjectsResponse = await _dio.get(
        '/mobile/teacher/subjects/$employeeId',
      );

      print(
        'Debug: fetchSubjects response status: ${subjectsResponse.statusCode}',
      );
      print('Debug: fetchSubjects response data: ${subjectsResponse.data}');

      if (subjectsResponse.statusCode != 200 ||
          !subjectsResponse.data.containsKey('results')) {
        throw Exception('Gagal mengambil daftar mata pelajaran');
      }

      List<dynamic> subjectsResults = subjectsResponse.data['results'];

      // Step 3: Cari subject_teacher.id yang sesuai dengan mata pelajaran yang diminta
      int? correctSubjectTeacherId;

      print('Debug: Looking for subject with ID: $subjectId');
      for (var subject in subjectsResults) {
        print(
          'Debug: Checking subject: ID=${subject['id']}, mata_pelajaran=${subject['mata_pelajaran']}',
        );

        // Match berdasarkan ID dari MataPelajaranModel yang dipassing ke fungsi ini
        // subjectId yang di-pass kemungkinan adalah subject_teacher.id, bukan mata_pelajaran.id
        if (subject['id'] == subjectId) {
          correctSubjectTeacherId = subject['id'];
          print('Debug: Found exact match for subject ID: $subjectId');
          break;
        }
      }

      // Jika tidak ada yang match dengan ID, ambil yang pertama sebagai fallback
      if (correctSubjectTeacherId == null && subjectsResults.isNotEmpty) {
        correctSubjectTeacherId = subjectsResults.first['id'];
        print(
          'Debug: Using first available subject as fallback: $correctSubjectTeacherId',
        );
      }

      if (correctSubjectTeacherId == null) {
        throw Exception(
          'Tidak ada mata pelajaran ditemukan untuk employee ini',
        );
      }

      print(
        'Debug: Found correct subject_teacher_id: $correctSubjectTeacherId',
      );

      // Step 4: Sekarang gunakan subject_teacher.id yang benar untuk mengambil jadwal
      print(
        'Debug: Calling /mobile/teacher/schedules/$correctSubjectTeacherId',
      );
      final response = await _dio.get(
        '/mobile/teacher/schedules/$correctSubjectTeacherId',
      );

      print('Debug: fetchSchedules response status: ${response.statusCode}');
      print('Debug: fetchSchedules response data: ${response.data}');

      // Log individual schedule details
      if (response.statusCode == 200 && response.data.containsKey('results')) {
        List<dynamic> results = response.data['results'];
        print(
          'Debug: Found ${results.length} schedules from correct subject_teacher_id',
        );
        for (var schedule in results) {
          print(
            'Debug: Schedule detail - ID: ${schedule['id']}, Day: ${schedule['day']}, Subject: ${schedule['mata_pelajaran']}, Time: ${schedule['jam_mulai']}-${schedule['jam_selesai']}',
          );

          // Add database verification log
          print(
            'Debug: This schedule ID ${schedule['id']} should exist in Laravel schedule table',
          );
        }
      }

      developer.log(
        'Jadwal Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Log detail response
        developer.log(
          'Response body keys: ${responseData.keys}',
          name: 'PresensiService',
          level: 900,
        );

        // Backend menggunakan key 'results' dan format data berbeda
        if (responseData.containsKey('results')) {
          List<dynamic> results = responseData['results'];

          // Filter jadwal berdasarkan mata pelajaran dan transform ke JadwalModel
          List<JadwalModel> jadwalList = [];

          for (var item in results) {
            // Backend response format berbeda, perlu transform
            jadwalList.add(
              JadwalModel(
                id: item['id'],
                subjectTeacherId: '0', // Tidak ada di response, set default
                day: item['day'],
                timeSlotId: '0', // Tidak ada di response, set default
                startTime: item['jam_mulai'],
                endTime: item['jam_selesai'],
                subjectName: item['mata_pelajaran'],
                subjectCode:
                    item['mata_pelajaran']
                        .toString()
                        .substring(0, 3)
                        .toUpperCase(),
                kelasCode:
                    item['kelas'].toString().substring(0, 3).toUpperCase(),
              ),
            );
          }

          // Log jumlah jadwal
          developer.log(
            'Found ${jadwalList.length} jadwal for teacher',
            name: 'PresensiService',
            level: 900,
          );

          return jadwalList;
        } else {
          // Jika tidak ada results, lempar exception
          developer.log(
            'Tidak ada kunci results di response',
            name: 'PresensiService',
            level: 1000,
          );
          throw Exception('Tidak ada jadwal ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        final errorData = response.data;
        String errorMessage =
            errorData['message'] ?? 'Gagal mengambil daftar jadwal';

        developer.log(
          'Error response: $errorData',
          name: 'PresensiService',
          level: 1000,
        );

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Log error untuk debugging
      developer.log(
        'Error mengambil jadwal: $e',
        name: 'PresensiService',
        level: 1000,
      );

      // Detail error untuk DioException
      if (e is DioException) {
        developer.log(
          'DioException Type: ${e.type}',
          name: 'PresensiService',
          level: 1000,
        );
        developer.log(
          'DioException Message: ${e.message}',
          name: 'PresensiService',
          level: 1000,
        );
        if (e.response != null) {
          developer.log(
            'DioException Response: ${e.response?.data}',
            name: 'PresensiService',
            level: 1000,
          );
        }
      }

      // Rethrow exception untuk ditangani di controller
      rethrow;
    }
  }

  // Metode untuk mengambil time slot
  Future<List<TimeSlotModel>> fetchTimeSlots() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/time-slot?paginate=false'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Cetak response untuk debugging
      developer.log(
        'Response time slots: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // API Laravel menggunakan key 'results' bukan 'data'
        if (responseBody.containsKey('results')) {
          dynamic resultsData = responseBody['results'];

          if (resultsData is List) {
            // Non-paginated response, results langsung berupa array
            return resultsData
                .map((json) => TimeSlotModel.fromJson(json))
                .toList();
          } else if (resultsData is Map && resultsData.containsKey('data')) {
            // Paginated response, data ada di results.data
            List<dynamic> body = resultsData['data'];
            return body.map((json) => TimeSlotModel.fromJson(json)).toList();
          } else {
            throw Exception('Invalid results format: $resultsData');
          }
        } else if (responseBody.containsKey('data')) {
          // Fallback untuk format lama
          List<dynamic> body = responseBody['data'];
          return body.map((json) => TimeSlotModel.fromJson(json)).toList();
        } else {
          // Jika tidak ada data, lempar exception
          throw Exception('Tidak ada time slot ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ?? 'Gagal mengambil daftar time slot';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Log error untuk debugging
      developer.log(
        'Error mengambil time slot: $e',
        name: 'PresensiService',
        level: 1000,
      );

      // Rethrow exception untuk ditangani di controller
      rethrow;
    }
  }

  // FUNGSI DIHAPUS: fetchStudentsByKelas karena endpoint tidak ada di backend
  // Gunakan fetchStudentsBySchedule sebagai gantinya

  // Metode untuk mengambil hari tersedia berdasarkan kelas dan mata pelajaran
  Future<List<String>> fetchAvailableDays(dynamic kelasId, dynamic subjectId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/schedules/available-days?kelas_id=$kelasId&subject_id=$subjectId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Cetak response lengkap untuk debugging
      developer.log(
        'Response available days lengkap: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // Log detail response
        developer.log(
          'Response body keys: ${responseBody.keys}',
          name: 'PresensiService',
          level: 900,
        );

        // Periksa apakah data ada
        if (responseBody.containsKey('available_days')) {
          List<dynamic> body = responseBody['available_days'];

          // Log jumlah hari tersedia
          developer.log(
            'Jumlah hari tersedia: ${body.length}',
            name: 'PresensiService',
            level: 900,
          );

          // Log detail setiap hari
          body.forEach((hari) {
            developer.log(
              'Hari tersedia: $hari',
              name: 'PresensiService',
              level: 900,
            );
          });

          return body.map((day) => day.toString()).toList();
        } else {
          // Jika tidak ada data, lempar exception
          developer.log(
            'Tidak ada kunci available_days di response',
            name: 'PresensiService',
            level: 1000,
          );
          throw Exception('Tidak ada hari tersedia ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ?? 'Gagal mengambil daftar hari tersedia';

        developer.log(
          'Error response available days: $errorBody',
          name: 'PresensiService',
          level: 1000,
        );

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Log error untuk debugging
      developer.log(
        'Error mengambil hari tersedia: $e',
        name: 'PresensiService',
        level: 1000,
      );

      // Rethrow exception untuk ditangani di controller
      rethrow;
    }
  }

  // Metode untuk mengambil slot waktu tersedia berdasarkan kelas, mata pelajaran, dan hari
  Future<List<TimeSlotModel>> fetchAvailableTimeSlots(
    dynamic kelasId,
    dynamic subjectId,
    String day,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/schedules/available-time-slots?kelas_id=$kelasId&subject_id=$subjectId&day=$day',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Cetak response untuk debugging
      developer.log(
        'Response slot waktu tersedia: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // Periksa apakah data ada
        if (responseBody.containsKey('available_time_slots')) {
          List<dynamic> body = responseBody['available_time_slots'];
          return body.map((json) => TimeSlotModel.fromJson(json)).toList();
        } else {
          // Jika tidak ada data, lempar exception
          throw Exception('Tidak ada slot waktu tersedia ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ??
            'Gagal mengambil daftar slot waktu tersedia';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Log error untuk debugging
      developer.log(
        'Error mengambil slot waktu tersedia: $e',
        name: 'PresensiService',
        level: 1000,
      );

      // Rethrow exception untuk ditangani di controller
      rethrow;
    }
  }

  // Metode untuk mendapatkan jadwal presensi
  Future<List<dynamic>> fetchAttendanceSchedule({
    required dynamic kelasId,
    required dynamic subjectId,
    required dynamic employeeId,
  }) async {
    try {
      // Log detail request
      developer.log(
        'Fetching Attendance Schedule',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Kelas ID: $kelasId, Subject ID: $subjectId, Employee ID: $employeeId',
        name: 'PresensiService',
        level: 900,
      );

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/attendance/schedule?kelas_id=$kelasId&subject_id=$subjectId&employee_id=$employeeId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Log response details
      developer.log(
        'Attendance Schedule Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Attendance Schedule Response Body: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // Periksa apakah data ada
        if (responseBody.containsKey('data')) {
          List<dynamic> body = responseBody['data'];
          return body;
        } else {
          // Jika tidak ada data, lempar exception
          throw Exception('Tidak ada jadwal presensi ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ?? 'Gagal mengambil jadwal presensi';
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        'Error fetching attendance schedule: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }

  // Metode untuk mendapatkan siswa untuk presensi
  Future<List<dynamic>> fetchStudentsForAttendance(int scheduleId) async {
    try {
      // Log detail request
      developer.log(
        'Fetching Students for Attendance',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Schedule ID: $scheduleId',
        name: 'PresensiService',
        level: 900,
      );

      final response = await http.get(
        Uri.parse('$_baseUrl/attendance/students?schedule_id=$scheduleId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Log response details
      developer.log(
        'Students for Attendance Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Students for Attendance Response Body: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // Periksa apakah data ada
        if (responseBody.containsKey('data')) {
          List<dynamic> body = responseBody['data'];
          return body;
        } else {
          // Jika tidak ada data, lempar exception
          throw Exception('Tidak ada siswa ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ?? 'Gagal mengambil daftar siswa';
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        'Error fetching students for attendance: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }

  // Metode untuk mendapatkan hari-hari yang tersedia berdasarkan kelas dan mata pelajaran
  Future<List<String>> getAvailableDays({
    required int kelasId,
    required int subjectId,
  }) async {
    try {
      // Log detail request
      developer.log(
        'Fetching Available Days - Kelas ID: $kelasId, Subject ID: $subjectId',
        name: 'PresensiService',
        level: 900,
      );

      // Ambil ID guru dari token
      final teacherId = AppConfig.employeeId ?? 1;

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/schedules/available-days/$teacherId/$kelasId/$subjectId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      // Log response details
      developer.log(
        'Available Days Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Available Days Response Body: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);

        // Periksa apakah data ada
        if (responseBody.containsKey('data')) {
          List<dynamic> body = responseBody['data'];

          // Konversi ke List<String>
          List<String> availableDays =
              body.map((day) => day.toString()).toList();

          // Log available days
          developer.log(
            'Hari tersedia: $availableDays',
            name: 'PresensiService',
            level: 900,
          );

          return availableDays;
        } else {
          // Jika tidak ada data, lempar exception
          throw Exception('Tidak ada hari tersedia ditemukan');
        }
      } else {
        // Parsing pesan error dari backend
        Map<String, dynamic> errorBody = json.decode(response.body);
        String errorMessage =
            errorBody['message'] ?? 'Gagal mengambil daftar hari tersedia';
        throw Exception(errorMessage);
      }
    } catch (e) {
      developer.log(
        'Error fetching available days: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }

  Future<List<TimeSlotModel>> getAvailableTimeSlots({
    required int employeeId,
    required int kelasId,
    required int subjectId,
  }) async {
    try {
      final response = await _dio.get(
        '/schedules/available-time-slots',
        queryParameters: {
          'employee_id': employeeId,
          'kelas_id': kelasId,
          'subject_id': subjectId,
        },
      );

      return (response.data['data'] as List)
          .map((timeSlotData) => TimeSlotModel.fromJson(timeSlotData))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil time slot tersedia');
    }
  }

  Future<List<Subject>> getSubjectsForKelas(int kelasId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subjects/kelas/$kelasId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> subjectsJson =
            json.decode(response.body)['subjects'];
        return subjectsJson.map((json) => Subject.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting subjects for kelas: $e');
      return [];
    }
  }

  Future<List<StudentModel>> getStudentsForAttendance({
    required dynamic kelasId,
    required dynamic subjectId,
    required String day,
    required dynamic timeSlotId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/attendance/students?kelas_id=$kelasId&subject_id=$subjectId&day=$day&time_slot_id=$timeSlotId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> studentsJson =
            json.decode(response.body)['students'];
        return studentsJson.map((json) => StudentModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting students for attendance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceSummary({
    required dynamic employeeId,
    dynamic kelasId,
    dynamic subjectId,
  }) async {
    try {
      developer.log(
        'Fetching attendance summary for employee: $employeeId, kelas: $kelasId, subject: $subjectId',
        name: 'PresensiService',
        level: 900,
      );

      // Build query parameters
      Map<String, String> queryParams = {'employee_id': employeeId.toString()};

      if (kelasId != null) {
        queryParams['kelas_id'] = kelasId.toString();
      }

      if (subjectId != null) {
        queryParams['subject_id'] = subjectId.toString();
      }

      final uri = Uri.parse(
        '$_baseUrl/attendance/summary',
      ).replace(queryParameters: queryParams);

      developer.log('Request URL: $uri', name: 'PresensiService', level: 900);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Response body: ${response.body}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return List<Map<String, dynamic>>.from(responseData['data']);
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to get attendance summary',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch attendance summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log(
        'Error in getAttendanceSummary: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }

  Future<List<KelasModel>> getKelasList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/kelas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${AppConfig.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> kelasJson = json.decode(response.body)['kelas'];
        return kelasJson.map((json) => KelasModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting kelas list: $e');
      return [];
    }
  }

  // Method untuk fetch siswa berdasarkan kelas ID menggunakan endpoint mobile
  Future<List<StudentModel>> fetchStudentsByKelasId(dynamic kelasId) async {
    try {
      developer.log(
        'Fetching Students by Kelas ID: $kelasId',
        name: 'PresensiService',
        level: 900,
      );

      final response = await _dio.get(
        '/mobile/teacher/schedules/students/$kelasId',
      );

      developer.log(
        'Students by Kelas Response Status: ${response.statusCode}',
        name: 'PresensiService',
        level: 900,
      );
      developer.log(
        'Students by Kelas Response Body: ${response.data}',
        name: 'PresensiService',
        level: 900,
      );

      if (response.statusCode == 200) {
        // API Laravel menggunakan struktur: { message, results }
        if (response.data is Map && response.data.containsKey('results')) {
          final List<dynamic> studentsData = response.data['results'] as List;

          developer.log(
            'Jumlah siswa ditemukan by kelas: ${studentsData.length}',
            name: 'PresensiService',
            level: 900,
          );

          return studentsData
              .map((json) => StudentModel.fromJson(json))
              .toList();
        } else {
          developer.log(
            'Response tidak memiliki key results: ${response.data}',
            name: 'PresensiService',
            level: 1000,
          );
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Gagal mengambil daftar siswa: ${response.data}');
      }
    } catch (e) {
      developer.log(
        'Error fetching students by kelas: $e',
        name: 'PresensiService',
        level: 1000,
      );
      rethrow;
    }
  }
}
