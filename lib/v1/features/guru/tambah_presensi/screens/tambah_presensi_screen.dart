import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/presensi_service.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/presensi_controller.dart';
import '../models/attendance_model.dart';
import '../../rekap/models/schedule_model.dart';

// Extension untuk membantu dengan firstOrNull
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

class TambahPresensiScreen extends StatefulWidget {
  final String? preselectedKelas;
  final String? preselectedMataPelajaran;
  final dynamic subjectId; // Changed from int? to dynamic to support UUID
  final String? scheduleInfo;
  final ScheduleModel? selectedSchedule;

  const TambahPresensiScreen({
    super.key,
    this.preselectedKelas,
    this.preselectedMataPelajaran,
    this.subjectId,
    this.scheduleInfo,
    this.selectedSchedule,
  });

  @override
  _TambahPresensiScreenState createState() => _TambahPresensiScreenState();
}

class _TambahPresensiScreenState extends State<TambahPresensiScreen> {
  DateTime? _selectedTanggal;
  final List<String> _statusPresensi = ['HADIR', 'SAKIT', 'IZIN', 'ALPHA'];

  // Map untuk menyimpan status presensi siswa (key: studentId as String)
  Map<String, String> _studentAttendanceStatus = {};

  late PresensiController _presensiController;
  late AttendanceController _attendanceController;

  // Helper method untuk parsing string/int menjadi int
  @override
  void initState() {
    super.initState();

    // Debug: Print data yang diterima dari RekapScreen
    print('🎯 TambahPresensiScreen initialized with data from RekapScreen:');
    print('   - preselectedKelas: ${widget.preselectedKelas}');
    print('   - preselectedMataPelajaran: ${widget.preselectedMataPelajaran}');
    print('   - subjectId: ${widget.subjectId}');
    print('   - scheduleInfo: ${widget.scheduleInfo}');
    print(
      '   - selectedSchedule: ${widget.selectedSchedule?.toJson() ?? 'null'}',
    );

    // Inisialisasi controller
    _presensiController = PresensiController(PresensiService());
    _attendanceController = AttendanceController();

    // Fetch data setelah inisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🚀 Starting data fetching process...');

      try {
        // Fetch kelas dulu, tapi skip auto-selection jika ada preselected data
        final hasPreselectedData =
            widget.preselectedKelas != null &&
            widget.preselectedMataPelajaran != null;

        await _presensiController.fetchKelasByTeacher(
          skipAutoSelection: hasPreselectedData,
        );
        print('✅ Kelas fetched: ${_presensiController.kelasList.length}');

        await _presensiController.fetchTimeSlots();
        print(
          '✅ Time slots fetched: ${_presensiController.timeSlotList.length}',
        );

        // Auto-select kelas dan mata pelajaran jika disediakan dari RekapScreen
        if (widget.preselectedKelas != null &&
            widget.preselectedMataPelajaran != null) {
          print('🎯 Starting auto-selection process...');
          final autoSelectSuccess = await _autoSelectKelasAndMataPelajaran();

          // Cek apakah auto-selection berhasil load students
          if (autoSelectSuccess && _presensiController.students.isNotEmpty) {
            print(
              '✅ Auto-selection completed successfully with ${_presensiController.students.length} students',
            );
            return; // Skip alternative loading jika sudah berhasil
          }
        }

        // Alternatif: Jika auto-selection gagal atau tidak ada preselected data
        if (widget.subjectId != null && _presensiController.students.isEmpty) {
          print(
            '🔍 Attempting alternative loading with subjectId: ${widget.subjectId}',
          );
          _tryLoadStudentsWithSubjectId();
        }
      } catch (error) {
        print('❌ Error fetching data: $error');
        // Jika gagal fetch data, masih coba load siswa dengan fallback
        if (widget.preselectedKelas != null &&
            widget.preselectedMataPelajaran != null) {
          _loadStudentsWithMultipleFallbacks();
        }
      }
    });
  }

  // Method untuk auto-select kelas dan mata pelajaran
  Future<bool> _autoSelectKelasAndMataPelajaran() async {
    try {
      // Cari kelas berdasarkan UUID (ID)
      var targetKelas =
          _presensiController.kelasList
              .where((kelas) => kelas.id == widget.preselectedKelas)
              .firstOrNull;

      // Fallback: jika tidak ditemukan berdasarkan ID, cari berdasarkan nama
      if (targetKelas == null && widget.preselectedKelas != null) {
        targetKelas =
            _presensiController.kelasList
                .where(
                  (kelas) =>
                      kelas.name.toLowerCase() ==
                      widget.preselectedKelas!.toLowerCase(),
                )
                .firstOrNull;
      }

      if (targetKelas != null) {
        print(
          '✅ Found target kelas: ${targetKelas.code} (${targetKelas.name}) with ID: ${targetKelas.id}',
        );
        _presensiController.selectKelas(targetKelas);

        // Auto-select mata pelajaran jika ada preselected
        if (widget.preselectedMataPelajaran != null) {
          // Tunggu mata pelajaran ter-load
          await Future.delayed(const Duration(milliseconds: 500));

          final targetMataPelajaran =
              _presensiController.mataPelajaranList
                  .where(
                    (mapel) => mapel.name.toLowerCase().contains(
                      widget.preselectedMataPelajaran!.toLowerCase(),
                    ),
                  )
                  .firstOrNull;

          if (targetMataPelajaran != null) {
            print('✅ Found mata pelajaran: ${targetMataPelajaran.name}');
            _presensiController.selectMataPelajaran(targetMataPelajaran);
            // Students akan di-load secara otomatis oleh selectMataPelajaran

            // Tunggu sebentar untuk memastikan loading selesai
            await Future.delayed(const Duration(milliseconds: 1000));

            return _presensiController.students.isNotEmpty;
          } else {
            print(
              '⚠️ Mata pelajaran "${widget.preselectedMataPelajaran}" tidak ditemukan',
            );
            return false;
          }
        }
        return false;
      } else {
        print('⚠️ Kelas "${widget.preselectedKelas}" tidak ditemukan');
        return false;
      }
    } catch (e) {
      print('❌ Error in auto-select: $e');
      return false;
    }
  }

  // Method alternatif untuk memuat siswa dengan subjectId
  void _tryLoadStudentsWithSubjectId() async {
    if (widget.subjectId == null) return;

    try {
      print(
        '🔍 Trying to load students using alternative method with subjectId: ${widget.subjectId}',
      );

      // Tunggu delay agar tidak bentrok dengan proses auto-select
      await Future.delayed(const Duration(milliseconds: 1500));

      // Cek apakah siswa sudah ada dari proses auto-select
      if (_presensiController.students.isNotEmpty) {
        print(
          '✅ Students already loaded via auto-select: ${_presensiController.students.length}',
        );
        return;
      }

      // Jika ada kelas yang terpilih, gunakan untuk load students
      if (_presensiController.selectedKelas != null) {
        print(
          '🔍 Loading students using selected kelas: ${_presensiController.selectedKelas!.id}',
        );
        await _presensiController.fetchStudentsByKelasId(
          _presensiController.selectedKelas!.id,
        );

        if (_presensiController.students.isNotEmpty) {
          print(
            '✅ Students loaded successfully: ${_presensiController.students.length} students',
          );
          return;
        }
      }

      print('⚠️ No students found after alternative loading');
    } catch (e) {
      print('❌ Error in alternative loading: $e');
    }
  }

  void _showDatePicker() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 7));
    final lastDate = DateTime(
      now.year,
      now.month,
      now.day,
    ); // hanya sampai hari ini
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        // Hanya izinkan tanggal dari seminggu ke belakang sampai hari ini
        return !date.isAfter(lastDate) && !date.isBefore(firstDate);
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTanggal = picked;
      });
    }
  }

  void _updateSiswaStatus(String studentId, String newStatus) {
    print(
      'Debug: _updateSiswaStatus called with studentId: $studentId, status: $newStatus',
    );
    setState(() {
      _studentAttendanceStatus[studentId] = newStatus;
    });
    print(
      'Debug: After update, map contains: ${_studentAttendanceStatus[studentId]}',
    );
  }

  void _simpanPresensi(
    AttendanceController attendanceController,
    PresensiController presensiController,
  ) async {
    print('🎯 ==> SIMPAN PRESENSI: Using data from RekapScreen');
    print('   - preselectedKelas: ${widget.preselectedKelas}');
    print('   - preselectedMataPelajaran: ${widget.preselectedMataPelajaran}');
    print('   - subjectId: ${widget.subjectId}');
    print('   - scheduleInfo: ${widget.scheduleInfo}');

    // Debug basic info
    print('Debug: Validating before save...');
    print('Debug: jadwalList length: ${presensiController.jadwalList.length}');
    print(
      'Debug: availableSchedules length: ${presensiController.availableSchedules.length}',
    );
    print(
      'Debug: timeSlotList length: ${presensiController.timeSlotList.length}',
    );

    if (presensiController.jadwalList.isNotEmpty) {
      print('Debug: First jadwal: ${presensiController.jadwalList.first}');
    }
    if (presensiController.availableSchedules.isNotEmpty) {
      print(
        'Debug: First availableSchedule: ${presensiController.availableSchedules.first}',
      );
    }

    // Validasi input yang lebih fleksibel - gunakan data dari RekapScreen
    List<String> missingFields = [];

    if (presensiController.selectedKelas == null) {
      missingFields.add('Kelas');
    }

    // Mata pelajaran: prioritas dari widget parameter (RekapScreen)
    String? mataPelajaranName =
        widget.preselectedMataPelajaran ??
        presensiController.selectedMataPelajaran?.name;

    if (mataPelajaranName == null) {
      missingFields.add('Mata Pelajaran');
    }

    if (_selectedTanggal == null) {
      missingFields.add('Tanggal');
    }
    if (presensiController.students.isEmpty) {
      missingFields.add('Data Siswa');
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap lengkapi: ${missingFields.join(', ')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Cari jadwal otomatis berdasarkan kelas dan mata pelajaran
    dynamic availableSchedule;

    // Prioritas 0: Gunakan selectedSchedule dari RekapScreen jika ada
    if (widget.selectedSchedule != null) {
      // Konversi ScheduleModel ke format yang diperlukan
      availableSchedule = {
        'id': widget.selectedSchedule!.id,
        'day': widget.selectedSchedule!.day,
        'time_start': widget.selectedSchedule!.jamMulai,
        'time_end': widget.selectedSchedule!.jamSelesai,
        'kelas': widget.selectedSchedule!.kelas,
        'mata_pelajaran': widget.selectedSchedule!.mataPelajaran,
        'subject_teacher_id': widget.selectedSchedule!.subjectTeacherId,
        'kelas_id': widget.selectedSchedule!.kelasId,
      };
      print(
        'Debug: Using selectedSchedule from RekapScreen with ID: ${availableSchedule['id']}',
      );
    }
    // Prioritas 1: Gunakan jadwal yang sudah dipilih
    else if (presensiController.selectedJadwal != null) {
      availableSchedule = presensiController.selectedJadwal;
      print('Debug: Using selectedJadwal with ID: ${availableSchedule.id}');
    }
    // Prioritas 2: Gunakan jadwal pertama dari jadwalList
    else if (presensiController.jadwalList.isNotEmpty) {
      availableSchedule = presensiController.jadwalList.first;
      print(
        'Debug: Using first jadwal from jadwalList with ID: ${availableSchedule.id}',
      );
    }
    // Prioritas 3: Gunakan availableSchedules jika ada
    else if (presensiController.availableSchedules.isNotEmpty) {
      availableSchedule = presensiController.availableSchedules.first;
      print(
        'Debug: Using first availableSchedule with ID: ${availableSchedule.id ?? availableSchedule['id']}',
      );
    }
    // Prioritas 4: Cari schedule yang sesuai dengan hari dan mata pelajaran
    else if (widget.subjectId != null && widget.scheduleInfo != null) {
      print(
        'Debug: Trying to find actual schedule ID for subject: ${widget.subjectId}',
      );

      // Parse hari dari scheduleInfo (format: "SELASA, 07:00:00 - 07:45:00")
      String? dayFromSchedule;
      if (widget.scheduleInfo!.contains(',')) {
        dayFromSchedule =
            widget.scheduleInfo!.split(',')[0].trim().toUpperCase();
      }

      print('Debug: Extracted day from schedule: $dayFromSchedule');

      // Coba ambil jadwal yang sesuai dengan hari dan mata pelajaran
      try {
        print(
          'Debug: Calling fetchJadwalBySubject with subjectId: ${widget.subjectId}',
        );
        await presensiController.fetchJadwalBySubject(widget.subjectId!);

        print(
          'Debug: Returned jadwalList length: ${presensiController.jadwalList.length}',
        );

        // Debug: print all available schedules
        if (presensiController.jadwalList.isNotEmpty) {
          print('Debug: All available schedules:');
          for (var jadwal in presensiController.jadwalList) {
            print(
              '  - Schedule ID: ${jadwal.id}, Day: ${jadwal.day}, Subject: ${jadwal.subjectName}, Start: ${jadwal.startTime}, End: ${jadwal.endTime}',
            );
          }
        }

        // Cari jadwal yang sesuai dengan hari yang diinginkan
        final matchingSchedule =
            presensiController.jadwalList
                .where(
                  (jadwal) =>
                      dayFromSchedule != null &&
                      jadwal.day.toUpperCase() == dayFromSchedule,
                )
                .firstOrNull;

        if (matchingSchedule != null) {
          print(
            'Debug: Found matching schedule with ID: ${matchingSchedule.id}',
          );
          availableSchedule = matchingSchedule;
        } else {
          print('Debug: No matching schedule found for day: $dayFromSchedule');
          print(
            'Debug: Available schedules: ${presensiController.jadwalList.map((j) => 'Day: ${j.day}, ID: ${j.id}').toList()}',
          );

          // Try to find schedule by subject name instead of day
          final matchingBySubject =
              presensiController.jadwalList
                  .where(
                    (jadwal) => jadwal.subjectName.toLowerCase().contains(
                      mataPelajaranName!.toLowerCase(),
                    ),
                  )
                  .firstOrNull;

          if (matchingBySubject != null) {
            print(
              'Debug: Found schedule by subject name: ID ${matchingBySubject.id}, Day: ${matchingBySubject.day}',
            );
            availableSchedule = matchingBySubject;
          } else {
            print('Debug: No schedule found by subject name either');
            print(
              'Debug: Will use fallback approach since no schedules were found',
            );

            // Last resort: Since we know this is valid data from RekapScreen,
            // but the schedule lookup failed, we can try using the teacher's
            // subject_teacher.id as the schedule_id as a fallback

            // For now, use the subjectId as schedule_id with explicit warning
            print('⚠️ WARNING: Using subjectId as fallback schedule_id');
            print('⚠️ This may fail if backend validation is strict');

            availableSchedule = {
              'id': widget.subjectId,
              'subject_id': widget.subjectId,
              'subject_name': mataPelajaranName,
              'schedule_info': widget.scheduleInfo,
              'fallback': true,
              'warning':
                  'No actual schedule found, using subject_id as schedule_id',
            };
          }
        }
      } catch (e) {
        print('Debug: Error fetching schedules: $e');
        // Fallback ke subject_id jika gagal fetch
        availableSchedule = {
          'id': widget.subjectId,
          'subject_id': widget.subjectId,
          'subject_name': mataPelajaranName,
          'schedule_info': widget.scheduleInfo,
          'fallback': true,
        };
      }

      print('Debug: Final availableSchedule after search: $availableSchedule');
    }

    // Jangan gunakan time slot sebagai fallback karena itu bukan schedule ID yang valid
    if (availableSchedule == null) {
      print('Debug: No valid schedule found!');
      print('Debug: selectedJadwal: ${presensiController.selectedJadwal}');
      print(
        'Debug: jadwalList.length: ${presensiController.jadwalList.length}',
      );
      print(
        'Debug: availableSchedules.length: ${presensiController.availableSchedules.length}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada jadwal tersedia. Pastikan mata pelajaran sudah dipilih dan memiliki jadwal.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    print('Debug: Final availableSchedule: $availableSchedule');

    // Handle schedule ID yang bisa berupa int atau dari map
    dynamic scheduleId;

    // Cek apakah availableSchedule adalah Map atau object
    if (availableSchedule is Map) {
      scheduleId = availableSchedule['id'] ?? availableSchedule['subject_id'];
    } else {
      // Jika object, coba akses properti id
      try {
        scheduleId = availableSchedule.id;
      } catch (e) {
        print('Debug: Error accessing .id property: $e');
        scheduleId = null;
      }
    }

    print('Debug: Schedule ID type: ${scheduleId.runtimeType}');
    print('Debug: Schedule ID value: $scheduleId');

    // Debug: Print isi map _studentAttendanceStatus
    print('Debug: _studentAttendanceStatus map contents:');
    _studentAttendanceStatus.forEach((key, value) {
      print('  $key (${key.runtimeType}): $value');
    });

    // Buat list attendance untuk bulk insert dengan error handling
    List<AttendanceModel> attendances = [];

    try {
      attendances =
          presensiController.students.map((student) {
            final String studentStatus =
                _studentAttendanceStatus[student.id] ?? 'HADIR';

            print(
              'Debug: Processing student ID: ${student.id} (${student.id.runtimeType})',
            );
            print('Debug: Status for student: $studentStatus');
            print(
              'Debug: Map contains key ${student.id}: ${_studentAttendanceStatus.containsKey(student.id)}',
            );

            // Ambil schedule ID dengan safe handling yang lebih fleksibel
            dynamic finalScheduleId;

            // Cek apakah availableSchedule adalah Map atau object
            if (availableSchedule is Map) {
              // Jika Map, akses dengan key
              finalScheduleId =
                  availableSchedule['id'] ?? availableSchedule['subject_id'];
            } else {
              // Jika object, coba akses properti id dengan safe handling
              try {
                finalScheduleId = availableSchedule?.id;
              } catch (e) {
                print('Debug: Error accessing .id property: $e');
                finalScheduleId = null;
              }
            }

            // Jika widget.subjectId tersedia sebagai fallback terakhir
            if (finalScheduleId == null && widget.subjectId != null) {
              finalScheduleId = widget.subjectId;
              print(
                'Debug: Using widget.subjectId as final fallback: $finalScheduleId',
              );
            }

            // Jika masih null, throw exception dengan info yang jelas
            if (finalScheduleId == null) {
              throw Exception(
                'Cannot determine schedule ID from availableSchedule: $availableSchedule (type: ${availableSchedule.runtimeType})',
              );
            }

            print(
              'Debug: Final schedule ID: $finalScheduleId (${finalScheduleId.runtimeType})',
            );

            // Validasi bahwa student.id dan scheduleId tidak kosong
            if (student.id.isEmpty || student.id == '0') {
              throw Exception('Invalid student ID: ${student.id}');
            }
            if (finalScheduleId == null || finalScheduleId.toString().isEmpty) {
              throw Exception('Invalid schedule ID: $finalScheduleId');
            }

            // Ambil nama mata pelajaran dari controller atau preselected
            final String mataPelajaranName =
                presensiController.selectedMataPelajaran?.name ??
                widget.preselectedMataPelajaran ??
                'Mata Pelajaran';

            return AttendanceModel(
              scheduleId: finalScheduleId.toString(),
              studentId: student.id,
              status: studentStatus,
              attendanceTime: _selectedTanggal!,
              notes:
                  'Presensi untuk kelas ${presensiController.selectedKelas!.code}, mata pelajaran $mataPelajaranName${widget.scheduleInfo != null ? ', jadwal: ${widget.scheduleInfo}' : ''}',
            );
          }).toList();

      print(
        'Debug: Successfully created ${attendances.length} attendance records',
      );
    } catch (e) {
      print('Debug: Error creating attendance list: $e');
      print('Debug: Error type: ${e.runtimeType}');
      print(
        'Debug: Students data: ${presensiController.students.map((s) => 'ID: ${s.id} (${s.id.runtimeType}), Name: ${s.name}').toList()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memproses data siswa: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Debug: Attendance data to be sent:');
    for (var attendance in attendances) {
      print(
        '  Schedule: ${attendance.scheduleId}, Student: ${attendance.studentId}, Status: ${attendance.status}',
      );
    }

    try {
      print('Debug: About to call createBulkAttendance');
      final result = await attendanceController.createBulkAttendance(
        attendances,
      );
      print('Debug: createBulkAttendance returned: $result');

      if (result != null) {
        // Ambil nama mata pelajaran untuk pesan sukses
        final String mataPelajaranName =
            presensiController.selectedMataPelajaran?.name ??
            widget.preselectedMataPelajaran ??
            'Mata Pelajaran';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Presensi untuk ${presensiController.students.length} siswa kelas ${presensiController.selectedKelas!.code} ($mataPelajaranName) berhasil disimpan',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset form setelah berhasil
        setState(() {
          _selectedTanggal = null;
          _studentAttendanceStatus.clear();
        });
        presensiController.resetSelections();

        // Kembali ke rekap presensi screen setelah berhasil simpan
        // Tunggu sebentar agar user sempat melihat pesan sukses
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pop(); // Kembali ke screen sebelumnya (rekap presensi)
          }
        });
      } else {
        // Tampilkan pesan error dari controller
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attendanceController.errorMessage ?? 'Gagal menyimpan presensi',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Debug: Error occurred: $e');
      print('Debug: Error type: ${e.runtimeType}');
      print(
        'Debug: Error stackTrace: ${e is Error ? e.stackTrace : 'No stack trace'}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Metode untuk membangun filter kelas
  Widget _buildKelasFilterTab(PresensiController presensiController) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            presensiController.kelasList.map((kelas) {
              bool isSelected = presensiController.selectedKelas == kelas;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    presensiController.selectKelas(kelas);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? const Color(0xFF0F7836) : Colors.white,
                    side: BorderSide(color: const Color(0xFF0F7836), width: 2),
                    elevation: 0,
                  ),
                  child: Text(
                    kelas.name, // Gunakan nama kelas bukan code
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF0F7836),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Metode untuk membangun filter mata pelajaran
  Widget _buildMataPelajaranFilterTab(PresensiController presensiController) {
    // Jika tidak ada mata pelajaran
    if (presensiController.mataPelajaranList.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada mata pelajaran tersedia',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            presensiController.mataPelajaranList.map((mapel) {
              bool isSelected =
                  presensiController.selectedMataPelajaran == mapel;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed:
                      presensiController.selectedKelas != null
                          ? () {
                            presensiController.selectMataPelajaran(mapel);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? const Color(0xFF0F7836) : Colors.white,
                    side: BorderSide(color: const Color(0xFF0F7836), width: 2),
                    elevation: 0,
                  ),
                  child: Text(
                    mapel.name,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF0F7836),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Widget untuk dropdown "Pilih Semua" status kehadiran
  Widget _buildSelectAllDropdown(PresensiController presensiController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F7836).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pilih Semua Siswa:',
            style: TextStyle(
              color: const Color(0xFF0F7836),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButton<String>(
            hint: Text(
              'Pilih Status',
              style: TextStyle(color: const Color(0xFF0F7836), fontSize: 14),
            ),
            dropdownColor: Colors.white,
            underline: Container(),
            items:
                _statusPresensi.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (String? selectedStatus) {
              if (selectedStatus != null) {
                _selectAllStudents(selectedStatus, presensiController);
              }
            },
          ),
        ],
      ),
    );
  }

  // Method untuk memilih semua siswa dengan status tertentu
  void _selectAllStudents(
    String status,
    PresensiController presensiController,
  ) {
    print('Debug: _selectAllStudents called with status: $status');
    setState(() {
      for (var student in presensiController.students) {
        _studentAttendanceStatus[student.id] = status;
        print('Debug: Set student ${student.id} to $status');
      }
    });
    print(
      'Debug: After selectAll, map size: ${_studentAttendanceStatus.length}',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Semua siswa telah diatur ke status: $status'),
        backgroundColor: _getStatusColor(status),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Custom SiswaList Widget

  Widget _buildSiswaList(PresensiController presensiController) {
    // Tampilkan loading jika sedang memuat siswa
    if (presensiController.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F7836)),
            SizedBox(height: 16),
            Text(
              'Mengambil daftar siswa...',
              style: TextStyle(color: Color(0xFF0F7836), fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Tampilkan pesan error jika ada
    if (presensiController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error: ${presensiController.errorMessage}',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                presensiController.resetErrorMessage();
                if (presensiController.selectedTimeSlot != null) {
                  presensiController.selectTimeSlot(
                    presensiController.selectedTimeSlot!,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0F7836),
              ),
              child: Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Tampilkan pesan jika belum ada mata pelajaran yang dipilih DAN bukan dari RekapScreen
    if (presensiController.selectedMataPelajaran == null &&
        widget.preselectedMataPelajaran == null) {
      return const Center(
        child: Text(
          'Silakan pilih mata pelajaran terlebih dahulu',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Jika dari RekapScreen tapi siswa belum ter-load, tampilkan loading yang berbeda
    if (widget.preselectedMataPelajaran != null &&
        presensiController.students.isEmpty &&
        !presensiController.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0F7836)),
            SizedBox(height: 16),
            Text(
              'Memuat daftar siswa untuk kelas yang dipilih...',
              style: TextStyle(color: Color(0xFF0F7836), fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Mata Pelajaran: ${widget.preselectedMataPelajaran}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Tampilkan pesan jika tidak ada siswa
    if (presensiController.students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'Tidak ada siswa ditemukan untuk jadwal ini',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Inisialisasi status default untuk siswa yang belum ada statusnya
    for (var student in presensiController.students) {
      print(
        'Debug: Initializing student ID: ${student.id} (type: ${student.id.runtimeType})',
      );
      if (!_studentAttendanceStatus.containsKey(student.id)) {
        _studentAttendanceStatus[student.id] = 'HADIR';
        print('Debug: Set default status for student ${student.id}');
      }
    }

    return Column(
      children: [
        // Dropdown "Pilih Semua"
        _buildSelectAllDropdown(presensiController),

        // Daftar siswa
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presensiController.students.length,
          itemBuilder: (context, index) {
            final student = presensiController.students[index];
            print(
              'Debug: Building student card for ID: ${student.id}, Name: "${student.name}", NIM: "${student.nim}"',
            );
            print(
              'Debug: Student name length: ${student.name.length}, is empty: ${student.name.isEmpty}',
            );
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF0F7836).withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student.name.isEmpty ? 'NAMA KOSONG' : student.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            student.name.isEmpty
                                ? Colors.red
                                : Color(0xFF0F7836),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _studentAttendanceStatus[student.id] ?? 'HADIR',
                      dropdownColor: Colors.white,
                      underline: Container(),
                      style: TextStyle(
                        color: _getStatusColor(
                          _studentAttendanceStatus[student.id] ?? 'HADIR',
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                      items:
                          _statusPresensi.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newStatus) {
                        if (newStatus != null) {
                          _updateSiswaStatus(student.id, newStatus);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Helper method untuk mendapatkan icon status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'HADIR':
        return Icons.check_circle;
      case 'SAKIT':
        return Icons.local_hospital;
      case 'IZIN':
        return Icons.event_note;
      case 'ALPHA':
        return Icons.cancel;
      default:
        return Icons.person;
    }
  }

  // Helper method untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'HADIR':
        return Colors.green;
      case 'SAKIT':
        return Colors.orange; // Warna kuning/orange untuk sakit
      case 'IZIN':
        return Colors.blue;
      case 'ALPHA':
        return Colors.red;
      default:
        return const Color(0xFF0F7836);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _presensiController),
        ChangeNotifierProvider.value(value: _attendanceController),
      ],
      child: Consumer2<PresensiController, AttendanceController>(
        builder: (context, presensiController, attendanceController, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF0FFF5),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCustomAppBar(),

                          const SizedBox(height: 24),

                          // Kartu Informasi Tambah Presensi
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tambah Presensi',
                                  style: TextStyle(
                                    color: const Color(0xFF0F7836),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Jika data dari RekapScreen, tampilkan info kelas dan mata pelajaran
                                if (widget.preselectedKelas != null &&
                                    widget.preselectedMataPelajaran !=
                                        null) ...[
                                  // Info Kelas dan Mata Pelajaran yang sudah dipilih
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0F7836,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF0F7836),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.class_,
                                              color: const Color(0xFF0F7836),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                presensiController
                                                            .selectedKelas !=
                                                        null
                                                    ? 'Kelas: ${presensiController.selectedKelas!.code}'
                                                    : 'Kelas: Pilih Kelas',
                                                style: const TextStyle(
                                                  color: Color(0xFF0F7836),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.book,
                                              color: const Color(0xFF0F7836),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Mata Pelajaran: ${widget.preselectedMataPelajaran}',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF0F7836,
                                                  ),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Tambahkan info jadwal jika tersedia
                                        if (widget.scheduleInfo != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                color: const Color(0xFF0F7836),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Jadwal: ${widget.scheduleInfo}',
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF0F7836,
                                                    ),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Filter Kelas (hanya tampil jika tidak ada preselection)
                                  Text(
                                    'Pilih Kelas',
                                    style: TextStyle(
                                      color: const Color(0xFF0F7836),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildKelasFilterTab(presensiController),

                                  const SizedBox(height: 16),

                                  // Filter Mata Pelajaran
                                  if (presensiController.selectedKelas !=
                                      null) ...[
                                    Text(
                                      'Pilih Mata Pelajaran',
                                      style: TextStyle(
                                        color: const Color(0xFF0F7836),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMataPelajaranFilterTab(
                                      presensiController,
                                    ),
                                  ],
                                ],

                                const SizedBox(height: 16),

                                // Pilih Tanggal
                                ElevatedButton.icon(
                                  onPressed: _showDatePicker,
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF0F7836),
                                  ),
                                  label: Text(
                                    _selectedTanggal == null
                                        ? 'Pilih Tanggal'
                                        : 'Tanggal: ${_selectedTanggal!.day}/${_selectedTanggal!.month}/${_selectedTanggal!.year}',
                                    style: const TextStyle(
                                      color: Color(0xFF0F7836),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFF0F7836),
                                      width: 2,
                                    ),
                                    elevation: 0,
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Daftar Siswa (ditampilkan setelah mata pelajaran dipilih ATAU jika siswa sudah ter-load)
                          if (presensiController.selectedMataPelajaran !=
                                  null ||
                              (widget.preselectedMataPelajaran != null &&
                                  presensiController.students.isNotEmpty)) ...[
                            Text(
                              'Daftar Siswa',
                              style: TextStyle(
                                color: const Color(0xFF0F7836),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _buildSiswaList(presensiController),

                            const SizedBox(height: 16),

                            // Tombol Simpan (hanya tampil setelah pilih tanggal dan ada siswa)
                            if (_selectedTanggal != null &&
                                presensiController.students.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.save,
                                          color: const Color(0xFF0F7836),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Siap untuk disimpan',
                                          style: TextStyle(
                                            color: const Color(0xFF0F7836),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed:
                                          attendanceController.isLoading
                                              ? null
                                              : () => _simpanPresensi(
                                                attendanceController,
                                                presensiController,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F7836,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: const StadiumBorder(),
                                        elevation: 0,
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                      ),
                                      child:
                                          attendanceController.isLoading
                                              ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Menyimpan Presensi...',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : Text(
                                                'Simpan Presensi (${presensiController.students.length} Siswa)',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Custom AppBar Widget
  Widget _buildCustomAppBar() {
    return Consumer<PresensiController>(
      builder: (context, presensiController, child) {
        // Buat judul dinamis berdasarkan kelas dan mata pelajaran yang dipilih
        String title = 'Tambah Presensi';

        // Hanya update title jika data sudah ter-load lengkap dan tidak sedang loading
        if (presensiController.selectedKelas != null &&
            presensiController.selectedMataPelajaran != null &&
            !presensiController.isLoading &&
            presensiController.selectedKelas!.code.isNotEmpty &&
            presensiController.selectedMataPelajaran!.name.isNotEmpty) {
          // Gunakan nama kelas dan mata pelajaran yang dipilih
          title =
              'Presensi ${presensiController.selectedKelas!.code} - ${presensiController.selectedMataPelajaran!.name}';
        } else if (presensiController.selectedKelas != null &&
            !presensiController.isLoading &&
            presensiController.selectedKelas!.code.isNotEmpty) {
          // Hanya kelas yang dipilih dan tidak loading
          title = 'Presensi ${presensiController.selectedKelas!.code}';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1EEC3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFFF0FFF5),
                    size: 24,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F7836),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 40), // Spacer untuk keseimbangan
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    print('🔚 TambahPresensiScreen disposing');
    super.dispose();
  }

  // Method dengan fallback sederhana untuk memuat siswa (hanya untuk kelas yang dipilih)
  Future<void> _loadStudentsWithMultipleFallbacks() async {
    print('🔄 Trying to load students for selected class only...');

    try {
      // Hanya coba dengan kelas yang sudah dipilih - TIDAK ADA AUTO-SELECT KELAS LAIN
      if (_presensiController.selectedKelas != null) {
        print(
          '🔄 Loading students for selected kelas ID: ${_presensiController.selectedKelas!.id} (${_presensiController.selectedKelas!.code})',
        );
        await _presensiController.fetchStudentsByKelasId(
          _presensiController.selectedKelas!.id,
        );
        if (_presensiController.students.isNotEmpty) {
          print(
            '✅ Students loaded successfully: ${_presensiController.students.length} students found',
          );
          return;
        } else {
          print('⚠️ No students found for the selected class');
        }
      } else {
        print('❌ No class selected, cannot load students');
      }

      // Tampilkan pesan informatif tanpa error yang menakutkan
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak ada data siswa untuk kelas yang dipilih. Periksa data jadwal dan semester.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading students: $e');
      // Silent error, tidak perlu ditampilkan ke user
    }
  }
}
