import 'package:dio/dio.dart';
import '../../../../../core/config/app_config.dart';

class StudentModel {
  final int id;
  final String name;
  final String nim;
  final int kelasId;

  StudentModel({
    required this.id,
    required this.name,
    required this.nim,
    required this.kelasId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['user']['name'],
      nim: json['nim'],
      kelasId: json['kelas_id'],
    );
  }
}

class StudentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
  ));

  Future<List<StudentModel>> getStudentsByKelas(int kelasId) async {
    try {
      final response = await _dio.get('/students', queryParameters: {
        'kelas_id': kelasId,
        'limit': 100, // Sesuaikan dengan kebutuhan
      });

      final List<dynamic> data = response.data['results']['data'] ?? [];
      return data.map((item) => StudentModel.fromJson(item)).toList();
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