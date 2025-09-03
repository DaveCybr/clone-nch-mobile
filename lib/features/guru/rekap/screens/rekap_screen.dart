import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/koordinator_card.dart';
import '../widgets/rekap_card.dart';
import '../widgets/jadwal_section.dart';
import '../widgets/mata_pelajaran_sidebar.dart';
import '../controllers/rekap_controller.dart';
import '../models/schedule_model.dart';
import '../../tambah_presensi/screens/tambah_presensi_screen.dart';
import '../../rekap_presensi/screens/rekap_presensi_screen.dart';

class RekapScreen extends StatefulWidget {
  const RekapScreen({super.key});

  @override
  _RekapScreenState createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late RekapController _rekapController;

  @override
  void initState() {
    super.initState();
    _rekapController = RekapController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rekapController.initialize();
    });
  }

  @override
  void didUpdateWidget(RekapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh attendance stats when returning from other screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rekapController.loadAttendanceStats();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rekapController.dispose();
    super.dispose();
  }

  void _openMataPelajaranSidebar() {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: MataPelajaranSidebar(
              controller: _rekapController,
              onMataPelajaranSelected: (mapel) {
                _rekapController.setSelectedMataPelajaran(mapel);
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }

  void _showTambahDataDialog([ScheduleModel? selectedSchedule]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Jenis Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F7836),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTambahDataButton(
                  label: 'Tambah Tugas',
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigasi ke halaman tambah tugas
                  },
                  isDisabled: true,
                ),
                const SizedBox(height: 16),
                _buildTambahDataButton(
                  label: 'Tambah Presensi',
                  onPressed: () async {
                    Navigator.pop(context);
                    // Kirim data kelas dan mata pelajaran yang dipilih
                    final selectedSubject =
                        _rekapController.selectedSubjectModel;

                    // Gunakan jadwal yang dipilih atau yang pertama sebagai fallback
                    final scheduleToUse =
                        selectedSchedule ??
                        (_rekapController.schedules.isNotEmpty
                            ? _rekapController.schedules.first
                            : null);

                    if (selectedSubject != null) {
                      // Gunakan kelasId dari schedule jika tersedia, fallback ke UUID dari schedules yang cocok
                      String? preselectedKelasId = scheduleToUse?.kelasId;

                      // Jika tidak ada scheduleToUse, cari dari daftar schedule berdasarkan nama kelas
                      if (preselectedKelasId == null ||
                          preselectedKelasId == '0') {
                        try {
                          final matchingSchedule = _rekapController.schedules
                              .firstWhere(
                                (schedule) =>
                                    schedule.kelas == selectedSubject.kelasName,
                              );
                          preselectedKelasId = matchingSchedule.kelasId;
                        } catch (e) {
                          // Tidak ada schedule yang cocok, tetap null
                          preselectedKelasId = null;
                        }
                      }

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TambahPresensiScreen(
                                preselectedKelas: preselectedKelasId,
                                preselectedMataPelajaran:
                                    selectedSubject.mataPelajaran,
                                subjectId: selectedSubject.id,
                                scheduleInfo:
                                    scheduleToUse != null
                                        ? '${scheduleToUse.day}, ${scheduleToUse.jamMulai} - ${scheduleToUse.jamSelesai}'
                                        : null,
                                selectedSchedule: scheduleToUse,
                              ),
                        ),
                      );

                      // Refresh attendance stats setelah kembali dari tambah presensi
                      if (result == null) {
                        // Kembali dari screen (baik berhasil atau tidak)
                        _rekapController.loadAttendanceStats();
                      }
                    } else {
                      // Fallback jika tidak ada subject yang dipilih
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TambahPresensiScreen(
                                selectedSchedule: scheduleToUse,
                              ),
                        ),
                      );

                      // Refresh attendance stats setelah kembali
                      if (result == null) {
                        _rekapController.loadAttendanceStats();
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTambahDataButton(
                  label: 'Tambah Ujian',
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigasi ke halaman tambah ujian
                  },
                  isDisabled: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTambahDataButton({
    required String label,
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey[300] : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: StadiumBorder(
          side: BorderSide(
            color: isDisabled ? Colors.grey[400]! : const Color(0xFF0F7836),
            width: 2,
          ),
        ),
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey[600] : const Color(0xFF0F7836),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isDisabled) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _rekapController,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF5),
        body: SafeArea(
          child: Consumer<RekapController>(
            builder: (context, controller, child) {
              // Show error only if critical error and not initialized (like network error)
              if (controller.errorMessage != null &&
                  !controller.isInitialized &&
                  !controller.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Terjadi Kesalahan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          controller.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7836),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomAppBar(
                        onOpenMataPelajaranSidebar: _openMataPelajaranSidebar,
                      ),

                      const SizedBox(height: 24),

                      KoordinatorCard(controller: controller),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          RekapCard(
                            value: '0',
                            label: 'Tugas',
                            type: 'tugas',
                            isLoading: false,
                            isDisabled: true,
                            comingSoonLabel: 'Coming Soon',
                            onTap: null,
                          ),
                          const SizedBox(width: 16),
                          RekapCard(
                            value: controller.totalPresensiDisplay,
                            label: 'Presensi',
                            type: 'presensi',
                            isLoading: controller.isLoadingAttendanceStats,
                            onTap: () async {
                              // Navigate to rekap presensi screen
                              final selectedSubject =
                                  controller.selectedSubjectModel;

                              // Get additional data from controller
                              String? kelasName;
                              String?
                              kelasId; // Changed from int? to String? to support UUID
                              dynamic timeSlotId;

                              if (controller.schedules.isNotEmpty) {
                                kelasName = controller.schedules.first.kelas;
                                kelasId =
                                    controller
                                        .schedules
                                        .first
                                        .kelasId; // No parsing needed for String UUID
                                timeSlotId =
                                    controller.schedules.first.timeSlotId;
                                print(
                                  '🔍 Using kelasId from schedule: $kelasId',
                                );
                                print(
                                  '🔍 Passing timeSlotId to rekap presensi: $timeSlotId (${timeSlotId.runtimeType})',
                                );
                              } else {
                                // Fallback: try to get kelasId from teacher info or reconstruct from available data
                                if (selectedSubject != null) {
                                  kelasName = selectedSubject.kelasName;
                                  print(
                                    '⚠️ No schedules found, using fallback kelasName: $kelasName',
                                  );

                                  // Try to find kelasId by matching kelasName from teacher info
                                  // This is a workaround until schedule service is fixed
                                  final normalizedKelasName =
                                      kelasName?.trim().toLowerCase();
                                  print(
                                    '🔍 Attempting to map kelasName: "$kelasName" (normalized: "$normalizedKelasName")',
                                  );

                                  if (normalizedKelasName == "toddler") {
                                    kelasId =
                                        "0198c546-cae8-70b0-8446-01b7d13bc619"; // Known Toddler ID
                                  } else if (normalizedKelasName ==
                                      "playgroup") {
                                    kelasId =
                                        "0198c546-caed-71c5-b1c8-8e9a96a09d7c";
                                  } else if (normalizedKelasName ==
                                      "kindergarten 1") {
                                    kelasId =
                                        "0198c546-caf1-706a-9f72-e0579219b292";
                                  } else if (normalizedKelasName ==
                                      "kindergarten 2") {
                                    kelasId =
                                        "0198c546-caf7-713a-8f6a-0dfbecc80624";
                                  } else if (normalizedKelasName ==
                                      "elementary school") {
                                    kelasId =
                                        "0198c546-cafc-718d-96a0-fd88a0d46598";
                                  } else if (normalizedKelasName ==
                                      "junior high school") {
                                    kelasId =
                                        "0198c546-cb01-700c-b506-43ec4cf8b7e4";
                                  } else if (normalizedKelasName ==
                                      "senior high school") {
                                    kelasId =
                                        "0198c546-cb06-7145-b2cb-407a8fe77554";
                                  }

                                  if (kelasId != null) {
                                    print(
                                      '✅ Found kelasId for $kelasName: $kelasId',
                                    );
                                  } else {
                                    print(
                                      '⚠️ Could not determine kelasId for $kelasName',
                                    );
                                  }
                                }
                              }

                              // Debug: Log what we're passing to RekapPresensiPage
                              print('🔍 Passing to RekapPresensiPage:');
                              print('   - kelasId: $kelasId');
                              print('   - kelasName: $kelasName');
                              print('   - subjectId: ${selectedSubject?.id}');
                              print(
                                '   - subjectName: ${selectedSubject?.mataPelajaran}',
                              );
                              print('   - timeSlotId: $timeSlotId');

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => RekapPresensiPage(
                                        kelasId: kelasId,
                                        subjectId: selectedSubject?.id,
                                        subjectName:
                                            selectedSubject?.mataPelajaran,
                                        kelasName: kelasName,
                                        teacherName: controller.teacherName,
                                        teacherId: controller.teacherInfo?.id,
                                        timeSlotId: timeSlotId,
                                      ),
                                ),
                              );

                              // Debug: Log what we're passing to RekapPresensiPage
                              print('🔍 Passing to RekapPresensiPage:');
                              print('   - kelasId: $kelasId');
                              print('   - kelasName: $kelasName');
                              print('   - subjectId: ${selectedSubject?.id}');
                              print(
                                '   - subjectName: ${selectedSubject?.mataPelajaran}',
                              );
                              print('   - timeSlotId: $timeSlotId');

                              // Refresh attendance stats when returning
                              if (result == null) {
                                controller.loadAttendanceStats();
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          RekapCard(
                            value: '0',
                            label: 'Ujian',
                            type: 'ujian',
                            isLoading: false,
                            isDisabled: true,
                            comingSoonLabel: 'Coming Soon',
                            onTap: null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tampilkan jadwal ketika mata pelajaran dipilih
                      if (controller.selectedMataPelajaran.isNotEmpty)
                        JadwalSection(
                          controller: controller,
                          onJadwalTap: (ScheduleModel selectedSchedule) {
                            _showTambahDataDialog(selectedSchedule);
                          },
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
