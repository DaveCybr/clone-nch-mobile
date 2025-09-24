import 'package:dio/dio.dart';
import 'package:nch_mobile/v1/core/config/app_config.dart';
import 'package:nch_mobile/v1/core/config/backdoor_helper.dart';
import 'package:nch_mobile/v1/features/login/models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
  static LoginService? _instance;
  Dio? _dio;

  // Singleton pattern
  static LoginService get instance {
    _instance ??= LoginService._();
    return _instance!;
  }

  LoginService._() {
    // Register callback untuk refresh Dio instance ketika URL berubah
    try {
      BackdoorHelper.registerRefreshCallback(_refreshDioInstance);
    } catch (e) {
      print('❌ Error registering refresh callback: $e');
    }
  }

  Dio get dio {
    if (_dio == null) {
      _createDioInstance();
    }
    return _dio!;
  }

  void _createDioInstance() {
    try {
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

      print(
        '🔧 LoginService Dio instance created with baseUrl: ${AppConfig.baseUrl}',
      );
    } catch (e) {
      print('❌ Error creating Dio instance: $e');
    }
  }

  void _refreshDioInstance() {
    try {
      print('🔄 Refreshing LoginService Dio instance...');
      _dio?.close();
      _dio = null;
      _createDioInstance();
    } catch (e) {
      print('❌ Error refreshing Dio instance: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Attempting login with email: $email');

      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response data keys: ${response.data?.keys}');

      if (response.statusCode == 200) {
        // Backend mengembalikan 'access_token'
        final token = response.data['access_token'];
        if (token == null) {
          print('❌ Token is null in response');
          return {
            'success': false,
            'message': 'Token tidak ditemukan dalam response',
          };
        }

        await saveToken(token);
        AppConfig.setToken(token);

        // Backend mengembalikan 'user' object langsung
        final userJson = response.data['user'];
        if (userJson == null) {
          print('❌ User data is null in response');
          return {
            'success': false,
            'message': 'Data user tidak ditemukan dalam response',
          };
        }

        print('👤 Processing user data...');
        print('👤 User JSON structure: ${userJson.keys}');
        print('👤 User ID type: ${userJson['id'].runtimeType}');
        print('👤 User ID value: ${userJson['id']}');

        try {
          final user = UserModel.fromJson(userJson);

          // Simpan employee ID jika user adalah employee
          if (userJson['employee'] != null &&
              userJson['employee']['id'] != null) {
            final employeeId = userJson['employee']['id'].toString();
            print('👨‍🏫 Employee ID type: ${employeeId.runtimeType}');
            print('👨‍🏫 Employee ID value: $employeeId');

            // Simpan employee ID sebagai string (UUID)
            await saveEmployeeIdString(employeeId);
            AppConfig.setEmployeeIdString(employeeId);
            print('👨‍🏫 Employee ID saved as string: $employeeId');
          }

          // Simpan student ID jika user adalah student
          if (userJson['student'] != null &&
              userJson['student']['id'] != null) {
            final studentId = userJson['student']['id'].toString();
            print('👨‍🎓 Student ID type: ${studentId.runtimeType}');
            print('👨‍🎓 Student ID value: $studentId');

            // Simpan student ID sebagai string (UUID)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('student_id_uuid', studentId);
            print('👨‍🎓 Student ID saved as string: $studentId');

            // Debug: Verify it was saved correctly
            final savedStudentId = prefs.getString('student_id_uuid');
            print('👨‍🎓 Verification - Saved student ID: $savedStudentId');
            print('👨‍🎓 All keys after save: ${prefs.getKeys().toList()}');
          }

          print('✅ Login successful');
          return {
            'success': true,
            'token': token,
            'tokenType': response.data['token_type'] ?? 'Bearer',
            'user': user,
            'userRaw': userJson, // Add raw JSON data for role checking
          };
        } catch (userParseError) {
          print('❌ Error parsing user data: $userParseError');
          return {
            'success': false,
            'message':
                'Gagal memproses data user: ${userParseError.toString()}',
          };
        }
      } else {
        print('❌ Non-200 response: ${response.statusCode}');
        return {
          'success': false,
          'message':
              response.data?['message'] ??
              'Login gagal dengan kode ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ DioException during login: ${e.message}');
      print('❌ DioException type: ${e.type}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');

      String errorMessage = 'Terjadi kesalahan koneksi';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Email atau password salah';
      } else if (e.response?.data != null &&
          e.response!.data is Map &&
          e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi timeout - periksa koneksi internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server tidak merespons dalam waktu yang ditentukan';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Tidak dapat terhubung ke server - periksa koneksi internet';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ Unexpected login error: $e');
      print('❌ Error type: ${e.runtimeType}');

      // Specific debugging for potential issues
      String debugMessage = 'Terjadi kesalahan tidak terduga';
      if (e.toString().contains('FormatException')) {
        debugMessage = 'Kesalahan format data dari server: ${e.toString()}';
      } else if (e.toString().contains('TypeError')) {
        debugMessage = 'Kesalahan tipe data: ${e.toString()}';
      } else if (e.toString().contains('JSON') ||
          e.toString().contains('json')) {
        debugMessage = 'Kesalahan parsing JSON: ${e.toString()}';
      } else {
        debugMessage = 'Kesalahan tidak terduga: ${e.toString()}';
      }

      return {'success': false, 'message': debugMessage};
    }
  }

  Future<Map<String, dynamic>> loginStudent(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Attempting student login with email: $email');

      final response = await dio.post(
        '/auth/login-student',
        data: {'email': email, 'password': password},
      );

      print('📡 Student login response status: ${response.statusCode}');
      print('📡 Student login response data keys: ${response.data?.keys}');

      if (response.statusCode == 200) {
        // Backend mengembalikan 'access_token'
        final token = response.data['access_token'];
        if (token == null) {
          print('❌ Token is null in response');
          return {
            'success': false,
            'message': 'Token tidak ditemukan dalam response',
          };
        }

        await saveToken(token);
        AppConfig.setToken(token);

        // Backend mengembalikan 'user' object langsung
        final userJson = response.data['user'];
        if (userJson == null) {
          print('❌ User data is null in response');
          return {
            'success': false,
            'message': 'Data user tidak ditemukan dalam response',
          };
        }

        print('👤 Processing student user data...');
        print('👤 Student User JSON structure: ${userJson.keys}');
        print('👤 Student User ID type: ${userJson['id'].runtimeType}');
        print('👤 Student User ID value: ${userJson['id']}');

        try {
          final user = UserModel.fromJson(userJson);

          // For students, save student ID if available
          if (userJson['student'] != null &&
              userJson['student']['id'] != null) {
            final studentId = userJson['student']['id'].toString();
            print('👨‍🎓 Student ID type: ${studentId.runtimeType}');
            print('👨‍🎓 Student ID value: $studentId');

            // Simpan student ID sebagai string (UUID)
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('student_id_uuid', studentId);
            print('👨‍🎓 Student ID saved as string: $studentId');

            // Debug: Verify it was saved correctly
            final savedStudentId = prefs.getString('student_id_uuid');
            print('👨‍🎓 Verification - Saved student ID: $savedStudentId');
            print('👨‍🎓 All keys after save: ${prefs.getKeys().toList()}');
          }

          print('✅ Student login successful');
          return {
            'success': true,
            'token': token,
            'tokenType': response.data['token_type'] ?? 'Bearer',
            'user': user,
          };
        } catch (userParseError) {
          print('❌ Error parsing student user data: $userParseError');
          return {
            'success': false,
            'message':
                'Gagal memproses data user siswa: ${userParseError.toString()}',
          };
        }
      } else {
        print('❌ Non-200 response: ${response.statusCode}');
        return {
          'success': false,
          'message':
              response.data?['message'] ??
              'Login siswa gagal dengan kode ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      print('❌ DioException during student login: ${e.message}');
      print('❌ DioException type: ${e.type}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');

      String errorMessage = 'Terjadi kesalahan koneksi';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Email atau password siswa salah';
      } else if (e.response?.data != null &&
          e.response!.data is Map &&
          e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi timeout - periksa koneksi internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server tidak merespons dalam waktu yang ditentukan';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Tidak dapat terhubung ke server - periksa koneksi internet';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ Unexpected student login error: $e');
      print('❌ Error type: ${e.runtimeType}');

      String debugMessage = 'Terjadi kesalahan tidak terduga';
      if (e.toString().contains('FormatException')) {
        debugMessage = 'Kesalahan format data dari server: ${e.toString()}';
      } else if (e.toString().contains('TypeError')) {
        debugMessage = 'Kesalahan tipe data: ${e.toString()}';
      } else if (e.toString().contains('JSON') ||
          e.toString().contains('json')) {
        debugMessage = 'Kesalahan parsing JSON: ${e.toString()}';
      } else {
        debugMessage = 'Kesalahan tidak terduga: ${e.toString()}';
      }

      return {'success': false, 'message': debugMessage};
    }
  }

  Future<UserModel?> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return null;

      final response = await dio.get(
        '/user',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> saveEmployeeId(int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('employee_id', employeeId);
  }

  Future<void> saveEmployeeIdString(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employee_id_uuid', employeeId);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('employee_id');
    await prefs.remove('employee_id_uuid');
  }

  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        await dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }

      AppConfig.clearToken();
      await removeToken();
      return true;
    } catch (e) {
      // Even if logout request fails, clear local data
      AppConfig.clearToken();
      await removeToken();
      return false;
    }
  }
}
