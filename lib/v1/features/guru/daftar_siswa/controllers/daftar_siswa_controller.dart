import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/daftar_siswa_service.dart';
import '../models/daftar_siswa_model.dart';

class DaftarSiswaController extends ChangeNotifier {
  final DaftarSiswaService _daftarSiswaService = DaftarSiswaService();

  // State variables
  List<DaftarSiswaModel> _students = [];
  List<String> _kelasList = [];
  String? _selectedKelas;
  Map<String, List<DaftarSiswaModel>> _studentsByKelas = {};

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _employeeUuid;

  // Getters
  List<DaftarSiswaModel> get students => _students;
  List<String> get kelasList => _kelasList;
  String? get selectedKelas => _selectedKelas;
  Map<String, List<DaftarSiswaModel>> get studentsByKelas => _studentsByKelas;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  // Initialize controller dengan employee UUID dari user yang login
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Controller sudah diinisialisasi');
      return;
    }

    if (_isLoading) {
      print('⚠️ Controller sedang loading');
      return;
    }

    print('🚀 Memulai inisialisasi StudentController');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ambil employee UUID dari shared preferences
      await _getEmployeeUuid();

      if (_employeeUuid == null) {
        throw Exception('UUID pegawai tidak ditemukan. Silakan login kembali.');
      }

      // Load data awal
      await _loadInitialData();

      _isInitialized = true;
      print('✅ Inisialisasi berhasil');
    } catch (e) {
      print('❌ Error saat inisialisasi: $e');
      _errorMessage = e.toString();
      // Jangan set _isInitialized = true jika error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getEmployeeUuid() async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil UUID dari shared preferences
    _employeeUuid =
        prefs.getString('employee_id_uuid') ??
        prefs.getString('employee_uuid') ??
        prefs.getString('user_uuid');

    print('👤 Employee UUID: $_employeeUuid');
    print('🔍 Available keys in SharedPreferences:');
    prefs.getKeys().forEach((key) {
      final value = prefs.get(key);
      print('   - $key: $value');
    });

    if (_employeeUuid == null) {
      throw Exception('UUID pegawai tidak ditemukan dalam storage');
    }
  }

  // Load data awal (daftar kelas dan siswa)
  Future<void> _loadInitialData() async {
    print('📚 Memulai load data awal');

    try {
      // Ambil daftar kelas yang diajar guru menggunakan UUID
      print('🏫 Mengambil daftar kelas...');
      print('👤 Employee UUID: $_employeeUuid');

      _kelasList = await _daftarSiswaService.getKelasListByTeacher(
        _employeeUuid!,
      );
      print('📋 Kelas ditemukan: $_kelasList');

      // Tambahkan debug untuk students
      print('👥 Mengambil data siswa...');
      _studentsByKelas = await _daftarSiswaService.getAllStudentsByTeacher(
        _employeeUuid!,
      );
      print('📊 Data siswa berhasil dimuat: ${_studentsByKelas.keys}');

      // Set kelas pertama sebagai default jika ada
      if (_kelasList.isNotEmpty) {
        _selectedKelas = _kelasList.first;
        _students = _studentsByKelas[_selectedKelas] ?? [];
        print(
          '✅ Kelas default dipilih: $_selectedKelas dengan ${_students.length} siswa',
        );
      } else {
        print('⚠️ Tidak ada kelas yang ditemukan');
      }
    } catch (e) {
      print('❌ Error saat load data awal: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Gagal memuat data: $e');
    }
  }

  // Pilih kelas untuk menampilkan siswa
  void selectKelas(String kelas) {
    if (_selectedKelas != kelas) {
      _selectedKelas = kelas;
      _students = _studentsByKelas[kelas] ?? [];
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    if (_employeeUuid == null) {
      print('⚠️ Employee UUID null, tidak bisa refresh');
      return;
    }

    print('🔄 Memulai refresh data');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadInitialData();
      print('✅ Refresh berhasil');
    } catch (e) {
      print('❌ Error saat refresh: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load siswa untuk kelas tertentu (jika diperlukan reload)
  Future<void> loadStudentsForKelas(String kelasName) async {
    try {
      // Untuk sementara gunakan yang sudah ada di cache
      if (_studentsByKelas.containsKey(kelasName)) {
        _students = _studentsByKelas[kelasName] ?? [];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat siswa untuk kelas $kelasName: $e';
      notifyListeners();
    }
  }

  // Set employee UUID (dipanggil dari login atau session)
  void setEmployeeUuid(String employeeUuid) {
    _employeeUuid = employeeUuid;
  }

  // Clear all data
  void clear() {
    _students.clear();
    _kelasList.clear();
    _studentsByKelas.clear();
    _selectedKelas = null;
    _isInitialized = false;
    _errorMessage = null;
    _employeeUuid = null;
    notifyListeners();
  }

  // Get total students count
  int get totalStudentsCount {
    return _studentsByKelas.values.fold(
      0,
      (sum, students) => sum + students.length,
    );
  }

  // Get students count for specific kelas
  int getStudentsCountForKelas(String kelasName) {
    return _studentsByKelas[kelasName]?.length ?? 0;
  }
}
