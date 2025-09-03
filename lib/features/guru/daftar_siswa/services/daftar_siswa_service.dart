import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daftar_siswa_model.dart';
import '../../../../core/config/app_config.dart';

class DaftarSiswaService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: 15000),
      receiveTimeout: const Duration(milliseconds: 15000),
      sendTimeout: const Duration(milliseconds: 15000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('access_token') ??
          prefs.getString('bearer_token');

      if (token == null) {
        throw Exception(
          'Token autentikasi tidak ditemukan. Silakan login kembali.',
        );
      }
      return token;
    } catch (e) {
      throw Exception('Gagal mendapatkan token autentikasi: $e');
    }
  }

  // Method untuk mengambil daftar kelas dari API
  Future<List<String>> getKelasList() async {
    try {
      final url =
          AppConfig.baseUrl.replaceFirst('/api', '') + '/api/kelas/by-teacher';
      final token = await _getToken();

      print('🔍 Memulai request daftar kelas');
      print('📡 URL: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            print('✅ Status validasi: $status');
            return status! < 500;
          },
        ),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      switch (response.statusCode) {
        case 200:
          final dynamic results = response.data['results'];

          if (results is List) {
            // Pastikan hanya mengambil kode kelas unik
            final kelasList =
                results
                    .map(
                      (kelas) =>
                          kelas is Map
                              ? kelas['code'] as String
                              : kelas.toString(),
                    )
                    .toSet()
                    .toList(); // Gunakan Set untuk menghilangkan duplikasi

            print('🔢 Jumlah kelas unik: ${kelasList.length}');
            print('📋 Daftar kelas: $kelasList');

            // Jika list kosong, kembalikan default
            return kelasList.isNotEmpty
                ? kelasList
                : ['RPL-A', 'RPL-B', 'TKJ-A', 'TKJ-B'];
          } else {
            print('Unexpected results type: ${results.runtimeType}');
            return ['RPL-A', 'RPL-B', 'TKJ-A', 'TKJ-B'];
          }
        case 401:
          throw Exception('Anda harus login terlebih dahulu');
        case 403:
          throw Exception(
            'Anda tidak memiliki akses untuk melihat daftar kelas',
          );
        case 404:
          print('Kelas not found, using default list');
          return ['RPL-A', 'RPL-B', 'TKJ-A', 'TKJ-B'];
        default:
          throw Exception(
            'Gagal mengambil daftar kelas: ${response.statusCode}',
          );
      }
    } on DioException catch (e) {
      print('❌ Dio error: ${e.type}');
      print('❌ Error message: ${e.message}');

      if (e.response != null) {
        print('❌ Error response data: ${e.response?.data}');
        print('❌ Error response status: ${e.response?.statusCode}');
      }

      // Tambahkan penanganan spesifik untuk berbagai jenis kesalahan Dio
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          print('⏰ Koneksi timeout');
          break;
        case DioExceptionType.badResponse:
          print('❌ Respon buruk dari server');
          break;
        case DioExceptionType.cancel:
          print('🚫 Request dibatalkan');
          break;
        case DioExceptionType.unknown:
          print('❓ Kesalahan tidak dikenal');
          break;
        default:
          print('🔍 Kesalahan Dio lainnya');
      }

      print('🔄 Menggunakan daftar kelas default');
      return ['RPL-A', 'RPL-B', 'TKJ-A', 'TKJ-B'];
    } catch (e) {
      print('❌ Kesalahan tidak terduga: $e');
      print('🔄 Menggunakan daftar kelas default');
      return ['RPL-A', 'RPL-B', 'TKJ-A', 'TKJ-B'];
    }
  }

  // Method untuk mengambil mata pelajaran berdasarkan teacher
  Future<List<SubjectModel>> getSubjectsByTeacher(String employeeUuid) async {
    try {
      final token = await _getToken();

      print(
        '🔍 Mengambil mata pelajaran untuk employee ID: $employeeUuid (${employeeUuid.runtimeType})',
      );

      // Step 1: Ambil subjects dari endpoint subjects (bukan schedules)
      final response = await _dio.get(
        '/mobile/teacher/subjects/$employeeUuid',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Subjects response status: ${response.statusCode}');
      print('📦 Raw subjects data: ${response.data['results']}');

      if (response.statusCode == 200) {
        final dynamic results = response.data['results'];
        if (results is List && results.isNotEmpty) {
          final data = results.cast<Map<String, dynamic>>();
          final subjects =
              data.map((json) => SubjectModel.fromJson(json)).toList();

          print('✅ Processed ${subjects.length} subjects with class info');
          for (var subject in subjects) {
            print('📖 Subject: ${subject.id} - ${subject.mataPelajaran}');
          }

          return subjects;
        } else {
          print('⚠️ No subjects found for employee');
          return [];
        }
      } else {
        throw Exception(
          'Gagal mengambil data mata pelajaran: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ Dio error getting subjects: ${e.response?.statusCode} - ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else {
        throw Exception(
          'Terjadi kesalahan saat mengambil mata pelajaran: ${e.response?.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error getting subjects: $e');
      throw Exception('Terjadi kesalahan saat mengambil mata pelajaran: $e');
    }
  }

  // Method untuk mengambil siswa berdasarkan kelas
  Future<List<DaftarSiswaModel>> getStudentsByKelas(dynamic kelasId) async {
    try {
      final token = await _getToken();

      final response = await _dio.get(
        '/mobile/teacher/schedules/students/$kelasId',
        queryParameters: {
          'with': 'user,kelas', // Try to include user and kelas data
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Students response status: ${response.statusCode}');
      print('📦 Students response data: ${response.data}');

      if (response.statusCode == 200) {
        final dynamic results = response.data['results'];
        if (results is List && results.isNotEmpty) {
          final data = results.cast<Map<String, dynamic>>();

          // Debug: Print sample student data structure
          if (data.isNotEmpty) {
            print('📋 Sample student data structure:');
            final firstStudent = data.first;
            firstStudent.forEach((key, value) {
              print(
                '   - $key: ${value != null ? value.runtimeType : 'null'} = ${value.toString().length > 100 ? '${value.toString().substring(0, 100)}...' : value}',
              );
            });
          }

          return data.map((json) => DaftarSiswaModel.fromJson(json)).toList();
        } else {
          print('⚠️ No students found for kelas $kelasId');
          return [];
        }
      } else {
        throw Exception('Gagal mengambil data siswa: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print(
        '❌ Dio error getting students: ${e.response?.statusCode} - ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else {
        throw Exception(
          'Terjadi kesalahan saat mengambil data siswa: ${e.response?.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error getting students: $e');
      throw Exception('Terjadi kesalahan saat mengambil data siswa: $e');
    }
  }

  // Method untuk mengambil semua siswa berdasarkan teacher
  Future<Map<String, List<DaftarSiswaModel>>> getAllStudentsByTeacher(
    String employeeUuid,
  ) async {
    try {
      final subjects = await getSubjectsByTeacher(employeeUuid);
      final Map<String, List<DaftarSiswaModel>> studentsByKelas = {};

      // Untuk setiap subject, ambil schedules untuk mendapat kelas_id
      final token = await _getToken();

      for (final subject in subjects) {
        try {
          // Gunakan subject_teacher_id untuk mendapat schedules
          final schedulesResponse = await _dio.get(
            '/mobile/teacher/schedules/${subject.id}',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
              validateStatus: (status) => status! < 500,
            ),
          );

          if (schedulesResponse.statusCode == 200) {
            final schedules = schedulesResponse.data['results'] as List;

            if (schedules.isNotEmpty) {
              // Ambil kelas_id dari schedule pertama
              final kelasId = schedules.first['kelas_id'];
              final kelasName = subject.kelas;

              if (kelasId != null) {
                final students = await getStudentsByKelas(kelasId);

                // Update each student's kelasName if it's still default
                final updatedStudents =
                    students.map((student) {
                      if (student.kelasName == 'Kelas Tidak Tersedia') {
                        return DaftarSiswaModel(
                          id: student.id,
                          name: student.name,
                          nim: student.nim,
                          generation: student.generation,
                          kelasName: kelasName, // Set correct kelas name
                          kelasId: student.kelasId,
                          email: student.email,
                          phone: student.phone,
                          gender: student.gender,
                        );
                      }
                      return student;
                    }).toList();

                studentsByKelas[kelasName] = updatedStudents;
                print(
                  '✅ Loaded ${updatedStudents.length} students for kelas $kelasName',
                );
              } else {
                studentsByKelas[kelasName] = [];
              }
            } else {
              studentsByKelas[subject.kelas] = [];
            }
          } else {
            studentsByKelas[subject.kelas] = [];
          }
        } catch (e) {
          print(
            '⚠️ Error loading students for subject ${subject.mataPelajaran}: $e',
          );
          studentsByKelas[subject.kelas] = [];
        }
      }

      return studentsByKelas;
    } catch (e) {
      print('❌ Error getting all students by teacher: $e');
      throw Exception('Gagal mengambil data siswa: $e');
    }
  }

  // Method untuk mengambil daftar kelas berdasarkan teacher
  Future<List<String>> getKelasListByTeacher(String employeeUuid) async {
    try {
      final subjects = await getSubjectsByTeacher(employeeUuid);
      final Set<String> uniqueKelas =
          subjects.map((subject) => subject.kelas).toSet();
      return uniqueKelas.toList()..sort();
    } catch (e) {
      print('❌ Error getting kelas list: $e');
      throw Exception('Gagal mengambil daftar kelas: $e');
    }
  }
}
