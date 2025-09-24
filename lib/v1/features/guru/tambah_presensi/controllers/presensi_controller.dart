import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../services/presensi_service.dart';
import '../models/kelas_model.dart';
import '../models/mata_pelajaran_model.dart';
import '../models/jadwal_model.dart';
import '../models/time_slot_model.dart';
import '../models/student_model.dart' as PresensiStudentModel;
import '../../../../core/config/app_config.dart';

class PresensiController extends ChangeNotifier {
  final PresensiService _presensiService;

  // Daftar kelas
  List<KelasModel> _kelasList = [];
  KelasModel? selectedKelas;

  // Daftar mata pelajaran
  List<MataPelajaranModel> _mataPelajaranList = [];
  MataPelajaranModel? selectedMataPelajaran;

  // Daftar jadwal
  List<JadwalModel> _jadwalList = [];
  JadwalModel? selectedJadwal;

  // Daftar siswa
  List<PresensiStudentModel.StudentModel> _students = [];

  // Daftar hari tersedia
  List<String> _availableDays = [];
  String? selectedDay;

  // Daftar slot waktu tersedia
  List<TimeSlotModel> _availableTimeSlots = [];
  TimeSlotModel? selectedTimeSlot;

  // Daftar siswa untuk presensi
  List<dynamic> _attendanceStudents = [];

  // Daftar mata pelajaran
  List<MataPelajaranModel> _subjectList = [];
  MataPelajaranModel? selectedSubject;

  bool _isLoading = false;
  String? _errorMessage;

  // Properti untuk time slot
  List<TimeSlotModel> _timeSlotList = [];

  // Properti untuk jadwal presensi
  List<dynamic> _attendanceSchedules = [];
  dynamic selectedAttendanceSchedule;

  // Daftar jadwal tersedia
  List<dynamic> _availableSchedules = [];
  dynamic selectedSchedule;

  // Status presensi siswa
  Map<String, String> _studentAttendanceStatus = {};

  // Constructor
  PresensiController(this._presensiService) {
    // Log saat controller diinisialisasi
    developer.log(
      'PresensiController diinisialisasi',
      name: 'PresensiController',
      level: 900,
    );

    // Catatan: fetchKelasByTeacher() dipanggil manual dari screen
    // untuk memberi kontrol kapan auto-selection dilakukan
  }

  // Method untuk mengset data preselected dari RekapScreen
  void setPreselectedData({
    required KelasModel kelas,
    required MataPelajaranModel mataPelajaran,
    JadwalModel? jadwal,
  }) {
    developer.log(
      'Setting preselected data - Kelas: ${kelas.name}, Mapel: ${mataPelajaran.name}',
      name: 'PresensiController',
      level: 900,
    );

    // Set kelas terpilih
    selectedKelas = kelas;

    // Set mata pelajaran terpilih
    selectedMataPelajaran = mataPelajaran;

    // Tambahkan ke list jika belum ada
    if (!_kelasList.any((k) => k.id == kelas.id)) {
      _kelasList.add(kelas);
    }

    if (!_mataPelajaranList.any((m) => m.id == mataPelajaran.id)) {
      _mataPelajaranList.add(mataPelajaran);
    }

    // Set jadwal jika ada
    if (jadwal != null) {
      selectedJadwal = jadwal;
      if (!_jadwalList.any((j) => j.id == jadwal.id)) {
        _jadwalList.add(jadwal);
      }
    }

    notifyListeners();

    // Fetch siswa berdasarkan kelas dan mata pelajaran yang sudah di-set
    _fetchStudentsByClassAndSubject();
  }

  // Getter
  List<KelasModel> get kelasList => _kelasList;
  List<MataPelajaranModel> get mataPelajaranList => _mataPelajaranList;
  List<JadwalModel> get jadwalList => _jadwalList;
  List<PresensiStudentModel.StudentModel> get students => _students;
  List<String> get availableDays => _availableDays;
  List<TimeSlotModel> get availableTimeSlots => _availableTimeSlots;
  List<MataPelajaranModel> get subjectList => _subjectList;
  List<TimeSlotModel> get timeSlotList => _timeSlotList;
  List<dynamic> get attendanceSchedules => _attendanceSchedules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get availableSchedules => _availableSchedules;
  Map<String, String> get studentAttendanceStatus => _studentAttendanceStatus;

  // Metode untuk memilih kelas
  void selectKelas(KelasModel kelas) {
    selectedKelas = kelas;
    _mataPelajaranList.clear();
    selectedMataPelajaran = null;
    fetchMataPelajaranByKelas(kelas.id);
    notifyListeners();
  }

  // Metode untuk memilih mata pelajaran
  void selectMataPelajaran(MataPelajaranModel mapel) async {
    selectedMataPelajaran = mapel;
    _jadwalList.clear();
    selectedJadwal = null;

    // Reset daftar siswa
    _students.clear();

    developer.log(
      'selectMataPelajaran called with mapel: ${mapel.name} (ID: ${mapel.id})',
      name: 'PresensiController',
      level: 900,
    );

    // Notify dulu sebelum fetch
    notifyListeners();

    // SKIP fetch jadwal karena service menggunakan employeeId bukan subjectId
    // Langsung ambil siswa berdasarkan kelas
    if (selectedKelas != null) {
      developer.log(
        'Loading students for kelas: ${selectedKelas!.id}',
        name: 'PresensiController',
        level: 900,
      );
      await fetchStudentsByKelasId(selectedKelas!.id);
    }

    // Notify lagi setelah fetch selesai
    notifyListeners();
  }

  // Metode untuk memilih jadwal
  void selectJadwal(JadwalModel jadwal) {
    selectedJadwal = jadwal;
    _students.clear();
    // Siswa akan diambil setelah memilih schedule di pertemuan_card
    notifyListeners();
  }

  // Metode untuk mengambil daftar kelas berdasarkan guru
  Future<void> fetchKelasByTeacher({bool skipAutoSelection = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Ambil ID guru dari token
      final teacherId = AppConfig.employeeId ?? 1;

      developer.log(
        'Mengambil kelas untuk guru ID: $teacherId',
        name: 'PresensiController',
        level: 900,
      );

      _kelasList = await _presensiService.fetchKelasByTeacher(teacherId);

      // Log jumlah kelas yang diambil
      developer.log(
        'Berhasil mengambil ${_kelasList.length} kelas',
        name: 'PresensiController',
        level: 900,
      );

      // Log detail setiap kelas
      _kelasList.forEach((kelas) {
        developer.log(
          'Kelas: ${kelas.name} (ID: ${kelas.id})',
          name: 'PresensiController',
          level: 900,
        );
      });

      // Jika tidak ada kelas dari API, log warning
      if (_kelasList.isEmpty) {
        developer.log(
          'WARNING: Tidak ada kelas ditemukan dari API',
          name: 'PresensiController',
          level: 1000,
        );
      } else if (!skipAutoSelection) {
        // Secara otomatis pilih kelas pertama jika tersedia dan tidak di-skip
        selectedKelas = _kelasList.first;
        // Otomatis muat mata pelajaran untuk kelas pertama
        await fetchMataPelajaranByKelas(selectedKelas!.id);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar kelas: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();

      // TIDAK menggunakan data hardcode lagi, biarkan kosong untuk debugging
      _kelasList = [];

      notifyListeners();
    }
  }

  // Metode untuk mengambil mata pelajaran berdasarkan kelas
  Future<void> fetchMataPelajaranByKelas(dynamic kelasId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _mataPelajaranList = await _presensiService.fetchMataPelajaranByKelas(
        kelasId,
      );

      // Log jumlah mata pelajaran yang diambil
      developer.log(
        'Berhasil mengambil ${_mataPelajaranList.length} mata pelajaran',
        name: 'PresensiController',
        level: 900,
      );

      // Jika tidak ada mata pelajaran, set error message
      if (_mataPelajaranList.isEmpty) {
        _errorMessage = 'Tidak ada mata pelajaran untuk kelas ini';
        developer.log(
          'Tidak ada mata pelajaran yang ditemukan',
          name: 'PresensiController',
          level: 900,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar mata pelajaran: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      _mataPelajaranList.clear(); // Pastikan daftar mata pelajaran kosong

      notifyListeners();
    }
  }

  // Metode untuk mengambil jadwal berdasarkan mata pelajaran
  Future<void> fetchJadwalBySubject(int subjectId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Log informasi pencarian jadwal
      developer.log(
        'Mencari jadwal untuk Subject ID: $subjectId',
        name: 'PresensiController',
        level: 900,
      );

      _jadwalList = await _presensiService.fetchJadwalBySubject(subjectId);

      // Log jumlah jadwal yang diambil
      developer.log(
        'Berhasil mengambil ${_jadwalList.length} jadwal untuk Subject ID: $subjectId',
        name: 'PresensiController',
        level: 900,
      );

      // Log detail setiap jadwal
      _jadwalList.forEach((jadwal) {
        developer.log(
          'Detail Jadwal - ID: ${jadwal.id}, Subject: ${jadwal.subjectName}, Hari: ${jadwal.day}, Kelas: ${jadwal.kelasCode}',
          name: 'PresensiController',
          level: 900,
        );
      });

      // Jika tidak ada jadwal, set error message
      if (_jadwalList.isEmpty) {
        _errorMessage = 'Tidak ada jadwal tersedia untuk mata pelajaran ini';
        developer.log(
          'Tidak ada jadwal yang ditemukan untuk Subject ID: $subjectId',
          name: 'PresensiController',
          level: 900,
        );
      } else {
        // Auto-select jadwal pertama jika ada
        selectedJadwal = _jadwalList.first;
        developer.log(
          'Auto-selected jadwal pertama: ID ${selectedJadwal!.id}',
          name: 'PresensiController',
          level: 900,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar jadwal: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      _jadwalList.clear(); // Pastikan daftar jadwal kosong

      notifyListeners();
    }
  }

  // FUNGSI DIHAPUS: fetchStudentsByKelas karena endpoint tidak ada di backend
  // Gunakan fetchStudentsBySchedule sebagai gantinya setelah memilih jadwal

  // Metode untuk mengambil time slot
  Future<void> fetchTimeSlots() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _timeSlotList = await _presensiService.fetchTimeSlots();

      // Log jumlah time slot yang diambil
      developer.log(
        'Berhasil mengambil ${_timeSlotList.length} time slot',
        name: 'PresensiController',
        level: 900,
      );

      // Jika tidak ada time slot, set error message
      if (_timeSlotList.isEmpty) {
        _errorMessage = 'Tidak ada jadwal tersedia';
        developer.log(
          'Tidak ada time slot yang ditemukan',
          name: 'PresensiController',
          level: 900,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar time slot: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      _timeSlotList.clear(); // Pastikan daftar time slot kosong

      notifyListeners();
    }
  }

  // Metode untuk memilih time slot
  void selectTimeSlot(TimeSlotModel timeSlot) async {
    selectedTimeSlot = timeSlot;
    _students.clear(); // Reset daftar siswa saat memilih time slot
    notifyListeners();

    // Jika kelas, mata pelajaran, dan time slot sudah dipilih, ambil jadwal dan siswa
    if (selectedKelas != null && selectedMataPelajaran != null) {
      await _fetchScheduleAndStudents();
    }
  }

  // Method helper untuk mengambil jadwal dan siswa
  Future<void> _fetchScheduleAndStudents() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final employeeId = AppConfig.employeeId ?? 1;

      // Log detail request
      developer.log(
        'Fetching schedule and students - Employee: $employeeId, Kelas: ${selectedKelas!.id}, Subject: ${selectedMataPelajaran!.id}',
        name: 'PresensiController',
        level: 900,
      );

      // Ambil jadwal yang tersedia
      final schedules = await _presensiService.fetchAvailableSchedules(
        employeeId: employeeId,
        kelasId: selectedKelas!.id,
        subjectId: selectedMataPelajaran!.id,
      );

      if (schedules.isNotEmpty) {
        // Ambil jadwal pertama yang tersedia (atau bisa disesuaikan logikanya)
        selectedSchedule = schedules.first;

        developer.log(
          'Selected schedule: ${selectedSchedule['id']}',
          name: 'PresensiController',
          level: 900,
        );

        // Ambil daftar siswa berdasarkan schedule
        await fetchStudentsBySchedule(selectedSchedule['id']);
      } else {
        _errorMessage =
            'Tidak ada jadwal tersedia untuk kombinasi kelas dan mata pelajaran ini';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();

      developer.log(
        'Error in _fetchScheduleAndStudents: $e',
        name: 'PresensiController',
        level: 1000,
      );
    }
  }

  // Method untuk mengambil siswa berdasarkan kelas dan mata pelajaran
  Future<void> _fetchStudentsByClassAndSubject() async {
    if (selectedKelas == null || selectedMataPelajaran == null) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      developer.log(
        'Fetching students for class: ${selectedKelas!.id}, subject: ${selectedMataPelajaran!.id}',
        name: 'PresensiController',
      );

      // Ambil jadwal pertama yang tersedia untuk kelas dan mata pelajaran
      final schedules = await _presensiService.fetchAvailableSchedules(
        employeeId: 1, // TODO: Ganti dengan employee ID yang sebenarnya
        kelasId: selectedKelas!.id,
        subjectId: selectedMataPelajaran!.id,
      );

      if (schedules.isNotEmpty) {
        // Gunakan jadwal pertama yang tersedia
        final firstSchedule = schedules.first;

        // Convert dynamic to JadwalModel jika diperlukan
        if (firstSchedule is Map<String, dynamic>) {
          selectedJadwal = JadwalModel.fromJson(firstSchedule);
        } else {
          selectedJadwal = firstSchedule;
        }

        // Ambil siswa berdasarkan jadwal
        final students = await _presensiService.fetchStudentsBySchedule(
          selectedJadwal!.id,
        );
        _students = students;

        developer.log(
          'Students loaded: ${_students.length}',
          name: 'PresensiController',
        );
      } else {
        _students = [];
        _errorMessage =
            'Tidak ada jadwal tersedia untuk kombinasi kelas dan mata pelajaran ini';
        developer.log(
          'No schedules found for class: ${selectedKelas!.id}, subject: ${selectedMataPelajaran!.id}',
          name: 'PresensiController',
        );
      }
    } catch (e) {
      _students = [];
      _errorMessage = 'Gagal memuat daftar siswa: $e';
      developer.log(
        'Error fetching students: $e',
        name: 'PresensiController',
        error: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk reset semua pilihan
  void resetSelections() {
    selectedKelas = null;
    selectedMataPelajaran = null;
    selectedJadwal = null;
    selectedTimeSlot = null;
    _mataPelajaranList.clear();
    _jadwalList.clear();
    _timeSlotList.clear();
    _students.clear();
    notifyListeners();
  }

  // Metode untuk mengambil jadwal presensi
  Future<void> fetchAttendanceSchedule() async {
    try {
      // Pastikan kelas dan mata pelajaran sudah dipilih
      if (selectedKelas == null || selectedMataPelajaran == null) {
        _errorMessage = 'Pilih kelas dan mata pelajaran terlebih dahulu';
        notifyListeners();
        return;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Ambil ID guru dari token
      final employeeId = int.tryParse(AppConfig.token) ?? 1;

      // Ambil jadwal presensi
      _attendanceSchedules = await _presensiService.fetchAttendanceSchedule(
        kelasId: selectedKelas!.id,
        subjectId: selectedMataPelajaran!.id,
        employeeId: employeeId,
      );

      // Log jumlah jadwal presensi
      developer.log(
        'Berhasil mengambil ${_attendanceSchedules.length} jadwal presensi',
        name: 'PresensiController',
        level: 900,
      );

      // Log detail setiap jadwal
      _attendanceSchedules.forEach((jadwal) {
        developer.log(
          'Jadwal Presensi: $jadwal',
          name: 'PresensiController',
          level: 900,
        );
      });

      // Jika tidak ada jadwal, set error message
      if (_attendanceSchedules.isEmpty) {
        _errorMessage = 'Tidak ada jadwal presensi tersedia';
        developer.log(
          'Tidak ada jadwal presensi yang ditemukan',
          name: 'PresensiController',
          level: 900,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar jadwal presensi: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      _attendanceSchedules.clear(); // Pastikan daftar jadwal kosong

      notifyListeners();
    }
  }

  // Metode untuk memilih jadwal presensi
  void selectAttendanceSchedule(dynamic schedule) {
    selectedAttendanceSchedule = schedule;

    // Reset daftar siswa
    _attendanceStudents.clear();

    // Fetch siswa untuk presensi
    fetchStudentsForAttendance();

    notifyListeners();
  }

  // Metode untuk mendapatkan mata pelajaran berdasarkan kelas
  Future<void> fetchSubjectsForKelas(int kelasId) async {
    try {
      _subjectList =
          await _presensiService.getSubjectsForKelas(kelasId)
              as List<MataPelajaranModel>;
      notifyListeners();
    } catch (e) {
      print('Error fetching subjects for kelas: $e');
      _subjectList = [];
      notifyListeners();
    }
  }

  // Metode untuk mendapatkan hari tersedia
  Future<void> fetchAvailableDays(int kelasId, int subjectId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Log informasi pencarian hari tersedia
      developer.log(
        'Mencari hari tersedia untuk Kelas ID: $kelasId, Subject ID: $subjectId',
        name: 'PresensiController',
        level: 900,
      );

      _availableDays = await _presensiService.getAvailableDays(
        kelasId: kelasId,
        subjectId: subjectId,
      );

      // Log jumlah hari yang diambil
      developer.log(
        'Berhasil mengambil ${_availableDays.length} hari',
        name: 'PresensiController',
        level: 900,
      );

      // Log detail setiap hari
      _availableDays.forEach((hari) {
        developer.log(
          'Hari tersedia: $hari',
          name: 'PresensiController',
          level: 900,
        );
      });

      // Jika tidak ada hari, set error message
      if (_availableDays.isEmpty) {
        _errorMessage = 'Tidak ada jadwal tersedia untuk mata pelajaran ini';
        developer.log(
          'Tidak ada hari yang ditemukan',
          name: 'PresensiController',
          level: 900,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil daftar hari: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      _availableDays.clear(); // Pastikan daftar hari kosong

      notifyListeners();
    }
  }

  // Metode untuk mengambil time slot tersedia
  Future<void> fetchAvailableTimeSlots({
    required int kelasId,
    required int subjectId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final employeeId = AppConfig.employeeId ?? 1;

      _availableTimeSlots = await _presensiService.getAvailableTimeSlots(
        employeeId: employeeId,
        kelasId: kelasId,
        subjectId: subjectId,
      );

      developer.log(
        'Berhasil mengambil ${_availableTimeSlots.length} time slot',
        name: 'PresensiController',
        level: 900,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil time slot: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Metode untuk mendapatkan siswa untuk presensi
  Future<void> fetchStudentsForAttendance({
    int? kelasId,
    int? subjectId,
    String? day,
    int? timeSlotId,
  }) async {
    try {
      // Gunakan parameter yang sudah dipilih sebelumnya jika tidak disediakan
      final finalKelasId = kelasId ?? selectedKelas?.id;
      final finalSubjectId = subjectId ?? selectedMataPelajaran?.id;
      final finalDay = day ?? selectedDay;
      final finalTimeSlotId = timeSlotId ?? selectedTimeSlot?.id;

      if (finalKelasId == null ||
          finalSubjectId == null ||
          finalDay == null ||
          finalTimeSlotId == null) {
        print('Semua parameter harus diisi');
        return;
      }

      _attendanceStudents = await _presensiService.getStudentsForAttendance(
        kelasId: finalKelasId,
        subjectId: finalSubjectId,
        day: finalDay,
        timeSlotId: finalTimeSlotId,
      );
      notifyListeners();
    } catch (e) {
      print('Error fetching students for attendance: $e');
      _attendanceStudents = [];
      notifyListeners();
    }
  }

  // Tambahkan metode untuk mendapatkan label waktu
  String getTimeSlotLabel(TimeSlotModel timeSlot) {
    return '${timeSlot.startTime} - ${timeSlot.endTime}';
  }

  // Metode untuk mengambil jadwal tersedia berdasarkan kelas dan mata pelajaran
  List<dynamic> getFilteredSchedules({int? kelasId, int? subjectId}) {
    if (kelasId == null || subjectId == null) {
      print('Filter Schedules: kelasId or subjectId is null');
      return [];
    }

    // Debug: Cetak semua jadwal yang tersedia
    print('Total Available Schedules: ${_availableSchedules.length}');
    _availableSchedules.forEach((schedule) {
      print(
        'Available Schedule: '
        'Kelas ID: ${schedule['kelas_id']}, '
        'Subject ID: ${schedule['subject_id']}',
      );
    });

    final filteredSchedules =
        _availableSchedules.where((schedule) {
          bool isMatch =
              schedule['kelas_id'] == kelasId &&
              schedule['subject_id'] == subjectId;

          // Debug: Cetak detail pencocokan
          if (isMatch) {
            print(
              'Matched Schedule: '
              'Kelas ID: ${schedule['kelas_id']}, '
              'Subject ID: ${schedule['subject_id']}, '
              'Day: ${schedule['day']}, '
              'Time: ${schedule['time_slot']['start_time']} - ${schedule['time_slot']['end_time']}',
            );
          }

          return isMatch;
        }).toList();

    // Debug: Cetak jumlah jadwal yang difilter
    print('Filtered Schedules Count: ${filteredSchedules.length}');

    return filteredSchedules;
  }

  // Metode untuk mengecek apakah jadwal valid
  bool isValidSchedule(dynamic schedule, int kelasId, int subjectId) {
    bool isValid =
        schedule['kelas_id'] == kelasId && schedule['subject_id'] == subjectId;

    // Debug: Cetak detail validasi
    print('Validating Schedule:');
    print('Schedule Kelas ID: ${schedule['kelas_id']}');
    print('Input Kelas ID: $kelasId');
    print('Schedule Subject ID: ${schedule['subject_id']}');
    print('Input Subject ID: $subjectId');
    print('Is Valid: $isValid');

    return isValid;
  }

  // Method fetchAvailableSchedules untuk logging tambahan
  Future<void> fetchAvailableSchedules({
    required int kelasId,
    required int subjectId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final employeeId = AppConfig.employeeId ?? 1;

      _availableSchedules = await _presensiService.fetchAvailableSchedules(
        employeeId: employeeId,
        kelasId: kelasId,
        subjectId: subjectId,
      );

      // Log detail jadwal yang diambil
      developer.log('Jadwal tersedia:', name: 'PresensiController', level: 900);
      _availableSchedules.forEach((schedule) {
        developer.log(
          'Jadwal: Kelas=${schedule['kelas_name']}, '
          'Mata Pelajaran=${schedule['subject_name']}, '
          'Hari=${schedule['day']}, '
          'Waktu=${schedule['time_slot']['start_time']}-${schedule['time_slot']['end_time']}',
          name: 'PresensiController',
          level: 900,
        );
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil jadwal: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Metode untuk memilih jadwal
  void selectSchedule(dynamic schedule) {
    developer.log(
      'selectSchedule dipanggil dengan schedule: $schedule',
      name: 'PresensiController',
      level: 900,
    );

    selectedSchedule = schedule;
    _students.clear();
    _studentAttendanceStatus.clear();

    // Log sebelum memanggil fetchStudentsBySchedule
    developer.log(
      'Akan memanggil fetchStudentsBySchedule dengan ID: ${schedule['id']}',
      name: 'PresensiController',
      level: 900,
    );

    fetchStudentsBySchedule(schedule['id']);
    notifyListeners();
  }

  // Metode untuk mengambil siswa berdasarkan jadwal
  Future<void> fetchStudentsBySchedule(int scheduleId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      developer.log(
        'Memanggil fetchStudentsBySchedule dengan scheduleId: $scheduleId',
        name: 'PresensiController',
        level: 900,
      );

      _students = await _presensiService.fetchStudentsBySchedule(scheduleId);

      developer.log(
        'Berhasil mendapat response dari service, jumlah siswa: ${_students.length}',
        name: 'PresensiController',
        level: 900,
      );

      // Inisialisasi status presensi default
      _studentAttendanceStatus = {
        for (var student in _students) student.id.toString(): 'HADIR',
      };

      // Log detail setiap siswa
      _students.forEach((student) {
        developer.log(
          'Siswa: ID=${student.id}, Nama=${student.name}',
          name: 'PresensiController',
          level: 900,
        );
      });

      developer.log(
        'Berhasil mengambil ${_students.length} siswa',
        name: 'PresensiController',
        level: 900,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Gagal mengambil siswa: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Metode untuk mengubah status presensi siswa
  void updateStudentAttendanceStatus(String studentId, String status) {
    _studentAttendanceStatus[studentId] = status;
    notifyListeners();
  }

  // Metode untuk submit presensi
  Future<bool> submitAttendance(DateTime attendanceDate) async {
    try {
      if (selectedSchedule == null) {
        _errorMessage = 'Pilih jadwal terlebih dahulu';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final students =
          _students
              .map(
                (student) => {
                  'student_id': student.id,
                  'status':
                      _studentAttendanceStatus[student.id.toString()] ??
                      'HADIR',
                },
              )
              .toList();

      final result = await _presensiService.submitAttendance(
        scheduleId: selectedSchedule['id'],
        attendanceDate: attendanceDate,
        students: students,
      );

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      developer.log(
        'Gagal submit presensi: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Metode untuk reset seluruh state
  void resetState() {
    _availableSchedules.clear();
    selectedSchedule = null;
    _students.clear();
    _studentAttendanceStatus.clear();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Metode untuk reset error message
  void resetErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method untuk fetch attendance data berdasarkan kelas dan mata pelajaran
  Future<List<Map<String, dynamic>>> fetchAttendanceByClassAndSubject(
    String kelasCode,
    String mataPelajaranName,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Find kelas and mata pelajaran objects
      final kelas = _kelasList.firstWhere((k) => k.code == kelasCode);
      final mataPelajaran = _mataPelajaranList.firstWhere(
        (m) => m.name == mataPelajaranName,
      );

      // Log untuk debugging
      developer.log(
        'Fetching attendance for Kelas: ${kelas.code}, Mapel: ${mataPelajaran.name}',
      );

      // Validasi employeeId
      if (AppConfig.employeeId == null) {
        throw Exception('Employee ID tidak tersedia. Silakan login ulang.');
      }

      // API call ke backend untuk mendapatkan attendance summary
      final attendanceData = await _presensiService.getAttendanceSummary(
        employeeId: AppConfig.employeeId!,
        kelasId: kelas.id,
        subjectId: mataPelajaran.id,
      );

      developer.log(
        'Received ${attendanceData.length} attendance records from backend',
      );

      _isLoading = false;
      notifyListeners();
      return attendanceData;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error fetching attendance data: $e';
      notifyListeners();
      developer.log('Error in fetchAttendanceByClassAndSubject: $e');
      rethrow;
    }
  }

  // Method untuk fetch siswa berdasarkan kelas ID
  Future<void> fetchStudentsByKelasId(dynamic kelasId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      developer.log(
        'Fetching students by kelas ID: $kelasId',
        name: 'PresensiController',
        level: 900,
      );

      _students = await _presensiService.fetchStudentsByKelasId(kelasId);

      developer.log(
        'Students fetched successfully: ${_students.length}',
        name: 'PresensiController',
        level: 900,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error fetching students by kelas ID: $e',
        name: 'PresensiController',
        level: 1000,
      );

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
