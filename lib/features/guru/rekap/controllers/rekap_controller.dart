import 'package:flutter/material.dart';
import '../services/rekap_service.dart';
import '../models/teacher_info_model.dart';
import '../models/schedule_model.dart';

class RekapController extends ChangeNotifier {
  final RekapService _rekapService = RekapService();

  // State variables
  TeacherInfoModel? _teacherInfo;
  List<SubjectInfoModel> _subjects = [];
  List<ScheduleModel> _schedules = [];
  String _selectedMataPelajaran = '';
  Map<String, int> _attendanceStats = {};

  bool _isLoading = false;
  bool _isLoadingSchedules = false;
  bool _isLoadingAttendanceStats =
      true; // Mulai dari true agar loading tampil langsung
  bool _isInitialized = false;
  String? _errorMessage;
  String? _scheduleErrorMessage;

  // Getters
  TeacherInfoModel? get teacherInfo => _teacherInfo;
  List<SubjectInfoModel> get subjects => _subjects;
  List<ScheduleModel> get schedules => _schedules;
  String get selectedMataPelajaran => _selectedMataPelajaran;
  Map<String, int> get attendanceStats => _attendanceStats;
  bool get isLoading => _isLoading;
  bool get isLoadingSchedules => _isLoadingSchedules;
  bool get isLoadingAttendanceStats => _isLoadingAttendanceStats;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get scheduleErrorMessage => _scheduleErrorMessage;

  // Getter untuk nama guru
  String get teacherName => _teacherInfo?.name ?? 'Nama Tidak Tersedia';

  // Getter untuk role guru
  String get teacherRole => _teacherInfo?.roleDisplayName ?? 'Staff';

  // Getter untuk daftar mata pelajaran dalam format string
  List<String> get subjectDisplayNames =>
      _subjects.map((subject) => subject.displayName).toList();

  // Getter untuk total presensi yang akan ditampilkan di RekapCard
  String get totalPresensiDisplay {
    final total = _attendanceStats['total_presensi'] ?? 0;
    return total.toString();
  }

  // Getter untuk detail statistik presensi
  int get totalHadir => _attendanceStats['hadir'] ?? 0;
  int get totalSakit => _attendanceStats['sakit'] ?? 0;
  int get totalIzin => _attendanceStats['izin'] ?? 0;
  int get totalAlpha => _attendanceStats['alpha'] ?? 0;

  // Initialize controller
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _errorMessage = null;
    try {
      notifyListeners();
    } catch (e) {
      // Controller sudah disposed, stop initialization
      print('⚠️ Controller disposed during initialization');
      return;
    }

    try {
      await _loadTeacherInfo();
      await _loadSubjects();

      // Mark as initialized so UI can render basic content
      _isInitialized = true;
      _isLoading = false;
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed before basic data notification');
        return;
      }

      // Load additional data asynchronously
      if (_subjects.isNotEmpty) {
        _selectedMataPelajaran = _subjects.first.displayName;
        // Load schedules and attendance stats in background
        _loadAdditionalDataAsync();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ Error in RekapController.initialize: $e');
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed before error notification');
      }
    }
  }

  // Load additional data asynchronously without blocking UI
  Future<void> _loadAdditionalDataAsync() async {
    try {
      // Load schedules for the default selected subject
      await loadSchedulesForSelectedSubject();
      // Load attendance stats for the default selected subject
      await loadAttendanceStats();
    } catch (e) {
      print('❌ Error loading additional data: $e');
      // Don't set error message here as basic data is already loaded
    }
  }

  // Load teacher info
  Future<void> _loadTeacherInfo() async {
    try {
      print('🔍 Loading teacher info...');
      _teacherInfo = await _rekapService.getTeacherInfo();
      print('✅ Teacher info loaded: ${_teacherInfo?.name}');
    } catch (e) {
      print('❌ Error loading teacher info: $e');
      throw Exception('Gagal memuat informasi guru: $e');
    }
  }

  // Load subjects
  Future<void> _loadSubjects() async {
    try {
      if (_teacherInfo == null) {
        throw Exception('Teacher info belum dimuat');
      }

      print('🔍 Loading subjects for teacher ID: ${_teacherInfo!.id}');
      _subjects = await _rekapService.getSubjectsWithClassInfo(
        _teacherInfo!.id,
      );
      print('✅ Subjects loaded: ${_subjects.length} items');
    } catch (e) {
      print('❌ Error loading subjects: $e');
      throw Exception('Gagal memuat mata pelajaran: $e');
    }
  }

  // Set selected mata pelajaran
  void setSelectedMataPelajaran(String mataPelajaran) {
    if (_selectedMataPelajaran != mataPelajaran) {
      _selectedMataPelajaran = mataPelajaran;
      try {
        notifyListeners();
        // Load schedules for newly selected subject
        loadSchedulesForSelectedSubject();
        // Load attendance stats for newly selected subject
        loadAttendanceStats();
      } catch (e) {
        print('⚠️ Controller disposed during setSelectedMataPelajaran');
      }
    }
  }

  // Load schedules for selected subject
  Future<void> loadSchedulesForSelectedSubject() async {
    if (_selectedMataPelajaran.isEmpty || _teacherInfo == null) return;

    _isLoadingSchedules = true;
    _scheduleErrorMessage = null;
    try {
      notifyListeners();
    } catch (e) {
      print('⚠️ Controller disposed during loadSchedulesForSelectedSubject');
      return;
    }

    try {
      // Find the selected subject model
      final selectedSubject = _subjects.firstWhere(
        (subject) => subject.displayName == _selectedMataPelajaran,
        orElse: () => throw Exception('Subject tidak ditemukan'),
      );

      print('🔍 Loading schedules for subject: ${selectedSubject.displayName}');

      // Get schedules for the selected subject
      _schedules = await _rekapService.getSchedulesForSubject(
        selectedSubject.id,
      );

      print('✅ Loaded ${_schedules.length} schedules');
    } catch (e) {
      _scheduleErrorMessage = e.toString();
      _schedules = [];
      print('❌ Error loading schedules: $e');
    } finally {
      _isLoadingSchedules = false;
      try {
        notifyListeners();
      } catch (e) {
        print(
          '⚠️ Controller disposed during loadSchedulesForSelectedSubject finally',
        );
      }
    }
  }

  // Load attendance stats for selected subject
  Future<void> loadAttendanceStats() async {
    if (_teacherInfo == null) {
      print('⚠️ Teacher info not available, skipping attendance stats');
      _isLoadingAttendanceStats = false;
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed during loadAttendanceStats early return');
      }
      return;
    }

    final selectedSubject = selectedSubjectModel;
    if (selectedSubject == null) {
      print('⚠️ No subject selected, skipping attendance stats');
      _isLoadingAttendanceStats = false;
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed during loadAttendanceStats early return');
      }
      return;
    }

    // Jangan set _isLoadingAttendanceStats = true karena sudah true dari awal
    try {
      notifyListeners();
    } catch (e) {
      print('⚠️ Controller disposed during loadAttendanceStats');
      return;
    }

    try {
      print(
        '🔍 Loading attendance stats for subject: ${selectedSubject.mataPelajaran}',
      );

      _attendanceStats = await _rekapService.getAttendanceStats(
        teacherId: _teacherInfo!.id,
        subjectId: selectedSubject.id,
      );

      print('✅ Attendance stats loaded: $_attendanceStats');
    } catch (e) {
      print('❌ Error loading attendance stats: $e');

      // Set default values on error (graceful degradation)
      _attendanceStats = {
        'total_presensi': 0,
        'hadir': 0,
        'sakit': 0,
        'izin': 0,
        'alpha': 0,
      };

      print('📊 Using default empty stats due to error');

      // Tidak throw error agar UI tetap berfungsi
      // UI akan menampilkan "0" untuk presensi
    } finally {
      _isLoadingAttendanceStats = false;
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed during loadAttendanceStats finally');
      }
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      notifyListeners();
    } catch (e) {
      print('⚠️ Controller disposed during refresh');
      return;
    }

    try {
      await _loadTeacherInfo();
      await _loadSubjects();

      // Reset selected mata pelajaran jika tidak ada di list baru
      if (_subjects.isNotEmpty &&
          !_subjects.any((s) => s.displayName == _selectedMataPelajaran)) {
        _selectedMataPelajaran = _subjects.first.displayName;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in RekapController.refresh: $e');
    } finally {
      _isLoading = false;
      try {
        notifyListeners();
      } catch (e) {
        print('⚠️ Controller disposed during refresh finally');
      }
    }
  }

  // Clear all data
  void clear() {
    _teacherInfo = null;
    _subjects.clear();
    _schedules.clear();
    _attendanceStats.clear();
    _selectedMataPelajaran = '';
    _isInitialized = false;
    _errorMessage = null;
    _scheduleErrorMessage = null;
    notifyListeners();
  }

  // Get current selected subject model
  SubjectInfoModel? get selectedSubjectModel {
    try {
      return _subjects.firstWhere(
        (subject) => subject.displayName == _selectedMataPelajaran,
      );
    } catch (e) {
      return null;
    }
  }
}
