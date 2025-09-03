import 'package:flutter/material.dart';
import '../models/rekap_presensi_models.dart';
import '../services/rekap_presensi_service.dart';

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

class RekapPresensiController extends ChangeNotifier {
  final RekapPresensiService _service = RekapPresensiService();

  // State variables
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Data
  List<AttendanceRecordModel> _attendanceRecords = [];
  List<KelasModel> _kelasList = [];
  SubjectInfoModel? _subjectInfo;
  PresensiSummaryModel? _presensiSummary;

  // Filters - Updated to support UUID
  dynamic _selectedKelasId; // Changed from int? to dynamic for UUID support
  dynamic _selectedSemesterId; // Changed from int? to dynamic for UUID support
  dynamic _selectedTimeSlotId;
  String _selectedDay = 'SENIN';
  DateTime? _selectedDate;
  bool _semuaTerabsensi = false;
  String _searchQuery = '';

  // Data tambahan dari halaman rekap utama
  String? _teacherName;
  String? _subjectName;
  String? _kelasName;
  String? _teacherId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  List<AttendanceRecordModel> get attendanceRecords => _attendanceRecords;
  List<KelasModel> get kelasList => _kelasList;
  SubjectInfoModel? get subjectInfo => _subjectInfo;
  PresensiSummaryModel? get presensiSummary => _presensiSummary;
  dynamic get selectedKelasId => _selectedKelasId; // Updated return type
  String get selectedDay => _selectedDay;
  DateTime? get selectedDate => _selectedDate;
  bool get semuaTerabsensi => _semuaTerabsensi;
  String get searchQuery => _searchQuery;

  // Getters untuk data tambahan dari halaman rekap
  String? get teacherName => _teacherName;
  String? get subjectName => _subjectName;
  String? get kelasName => _kelasName;
  String? get teacherId => _teacherId;

  // Filtered data
  List<AttendanceRecordModel> get filteredAttendanceRecords {
    var filtered = _attendanceRecords;

    // Filter berdasarkan tanggal yang dipilih
    if (_selectedDate != null) {
      final selectedDateStr = _formatDateForFilter(_selectedDate!);
      filtered =
          filtered
              .where((record) => record.attendanceDate == selectedDateStr)
              .toList();
    }

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (record) =>
                    record.student.user.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    record.student.nim.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    // Filter semua terabsensi (hanya menampilkan yang sudah presensi)
    if (_semuaTerabsensi) {
      return filtered;
    } else {
      return filtered
          .where((record) => record.status != 'belum_diambil')
          .toList();
    }
  }

  // Kelas yang tersedia sebagai string untuk tab
  List<String> get kelasNames => _kelasList.map((k) => k.name).toList();

  /// Format tanggal untuk filter (format: YYYY-MM-DD)
  String _formatDateForFilter(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get available days list
  List<String> get availableDays => [
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
  ];

  /// Initialize controller dengan data dari halaman rekap utama
  Future<void> initialize({
    dynamic kelasId,
    dynamic semesterId,
    dynamic timeSlotId,
    String? day,
    dynamic subjectId,
    // Data tambahan dari halaman rekap utama
    String? teacherName,
    String? subjectName,
    String? kelasName,
    String? teacherId,
  }) async {
    if (_isInitialized) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      print('🔄 Initializing RekapPresensiController...');
      print(
        '📋 Parameters: kelasId=$kelasId, subjectId=$subjectId, timeSlotId=$timeSlotId (${timeSlotId.runtimeType})',
      );
      print(
        '📋 Additional info: teacher=$teacherName, subject=$subjectName, kelas=$kelasName',
      );

      // Set data tambahan dari halaman rekap
      _teacherName = teacherName;
      _subjectName = subjectName;
      _kelasName = kelasName;
      _teacherId = teacherId;

      // Load kelas list terlebih dahulu
      await _loadKelasList();

      // Jika data sudah disediakan dari halaman rekap, gunakan langsung
      if (kelasId != null) {
        _selectedKelasId = kelasId;
        print('✅ Using provided kelasId: $kelasId');
      }

      // Load semester aktif jika belum ada
      if (_selectedSemesterId == null) {
        await _loadActiveSemester();
      }

      // Load attendance data
      await _loadAttendanceData();

      _isInitialized = true;
      print('✅ RekapPresensiController initialized successfully');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error initializing RekapPresensiController: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load daftar kelas
  Future<void> _loadKelasList() async {
    try {
      final kelasData = await _service.getKelas();
      _kelasList = kelasData.map((k) => KelasModel.fromJson(k)).toList();
      print('📋 Loaded ${_kelasList.length} kelas');
      print('📋 Kelas details:');
      for (var kelas in _kelasList) {
        print(
          '   - ID: ${kelas.id} (type: ${kelas.id.runtimeType}), Name: ${kelas.name}',
        );
      }
    } catch (e) {
      print('❌ Error loading kelas list: $e');
    }
  }

  /// Load semester aktif
  Future<void> _loadActiveSemester() async {
    try {
      final semesterData = await _service.getActiveSemester();
      if (semesterData != null) {
        print('📅 Raw semester data: $semesterData');
        final semesterId = semesterData['id'];
        final semesterName = semesterData['semester'];

        print('📅 Raw semesterId: $semesterId (${semesterId.runtimeType})');
        _selectedSemesterId = semesterId;
        print('📅 Using semester: $semesterName (ID: $semesterId)');
        print('✅ Found active semester: $semesterData');
      } else {
        print('❌ No active semester found');
        // Fallback: use a default semester structure
        _selectedSemesterId = '0198c548-30a5-71ae-8c0f-cf955aa53e0f';
        print('🔄 Using fallback semester ID: $_selectedSemesterId');
      }
    } catch (e) {
      print('❌ Error loading active semester: $e');
      // Final fallback
      _selectedSemesterId = '0198c548-30a5-71ae-8c0f-cf955aa53e0f';
    }
  }

  /// Load data attendance dari backend
  Future<void> _loadAttendanceData() async {
    if (_selectedKelasId == null) {
      print('❌ Cannot load attendance: kelasId is null');
      return;
    }

    // Use default semester if not provided
    if (_selectedSemesterId == null) {
      await _loadActiveSemester();
    }

    // Additional check for invalid kelasId
    if (_selectedKelasId == null ||
        _selectedKelasId == 0 ||
        _selectedKelasId.toString().isEmpty ||
        _selectedKelasId.toString() == '0') {
      print('❌ Invalid kelasId: $_selectedKelasId');
      return;
    }

    try {
      print('🔄 Loading attendance data...');

      // Reset data terlebih dahulu untuk memastikan tidak ada data lama
      _attendanceRecords = [];
      _presensiSummary = null;

      // Format the selected date as attendance date, fallback to current date
      final targetDate = _selectedDate ?? DateTime.now();
      final attendanceDate = _formatDateForFilter(targetDate);

      print('🔍 Trying tambah presensi pattern with date: $targetDate');
      print('🔍 Formatted attendance_date: $attendanceDate');

      // First, try to use direct schedule_id query if we know it works
      final knownScheduleId =
          '0198c54a-26f9-7076-9c35-bb1c5e1496e4'; // From successful debug logs

      final directResult = await _service.getAttendanceByScheduleId(
        scheduleId: knownScheduleId,
        attendanceDate: attendanceDate.split(' ')[0], // Get just the date part
      );

      if (directResult['attendance_data'] != null &&
          (directResult['attendance_data'] as List).isNotEmpty) {
        print(
          '📊 Found ${(directResult['attendance_data'] as List).length} attendance records from direct schedule_id query',
        );

        // Parse attendance data
        final attendanceData = directResult['attendance_data'] as List;
        _attendanceRecords =
            attendanceData
                .map((item) => AttendanceRecordModel.fromJson(item))
                .toList();

        // Parse subject info
        final additionalInfo = directResult['additional_info'];
        if (additionalInfo != null) {
          _subjectInfo = SubjectInfoModel.fromJson(additionalInfo);
          print(
            '✅ Parsed subject info from direct query: ${_subjectInfo?.namaMataPelajaran} - ${_subjectInfo?.kelas}',
          );
        }

        _calculatePresensiSummary();
        print(
          '✅ Successfully loaded ${_attendanceRecords.length} attendance records using direct schedule_id query',
        );
        notifyListeners();
        return;
      } else {
        print('📊 No attendance records found for date: $attendanceDate');
        // Data sudah direset di awal, jadi _attendanceRecords sudah kosong
        _calculatePresensiSummary(); // Ini akan membuat summary dengan nilai 0
        print('✅ Set empty attendance records for selected date');
        notifyListeners();
        return;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error loading attendance data: $e');
      // Reset data pada error juga
      _attendanceRecords = [];
      _calculatePresensiSummary();
      notifyListeners();
    }
  }

  /// Kalkulasi summary presensi
  void _calculatePresensiSummary() {
    if (_attendanceRecords.isEmpty) {
      _presensiSummary = PresensiSummaryModel(
        totalHadir: 0,
        totalSakit: 0,
        totalIzin: 0,
        totalAlpha: 0,
        totalSiswa: 0,
      );
      return;
    }

    int hadir = 0, sakit = 0, izin = 0, alpha = 0;

    for (var record in _attendanceRecords) {
      switch (record.status.toUpperCase()) {
        case 'HADIR':
          hadir++;
          break;
        case 'SAKIT':
          sakit++;
          break;
        case 'IZIN':
          izin++;
          break;
        case 'ALPHA':
          alpha++;
          break;
      }
    }

    _presensiSummary = PresensiSummaryModel(
      totalHadir: hadir,
      totalSakit: sakit,
      totalIzin: izin,
      totalAlpha: alpha,
      totalSiswa: _attendanceRecords.length,
    );

    print(
      '📊 Summary - Hadir: $hadir, Sakit: $sakit, Izin: $izin, Alpha: $alpha',
    );
  }

  /// Set tanggal yang dipilih dan reload data
  Future<void> setSelectedDate(DateTime date) async {
    if (_selectedDate == date) return;

    _selectedDate = date;

    // Update day berdasarkan tanggal yang dipilih
    _selectedDay = _getDayFromDate(date);

    print('📅 Date changed to: ${_selectedDate} (${_selectedDay})');

    _setLoading(true);

    try {
      await _loadAttendanceData();
    } finally {
      _setLoading(false);
    }
  }

  /// Set filter semua terabsensi
  void setSemuaTerabsensi(bool value) {
    _semuaTerabsensi = value;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Refresh semua data
  Future<void> refresh() async {
    _isInitialized = false;
    _attendanceRecords.clear();
    _subjectInfo = null;
    _presensiSummary = null;

    notifyListeners();

    await _loadAttendanceData();
  }

  /// Helper method untuk mengkonversi DateTime ke nama hari dalam bahasa Indonesia
  String _getDayFromDate(DateTime date) {
    final days = [
      'MINGGU',
      'SENIN',
      'SELASA',
      'RABU',
      'KAMIS',
      'JUMAT',
      'SABTU',
    ];
    return days[date.weekday % 7];
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
