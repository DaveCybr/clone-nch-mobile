import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/rekap_presensi_custom_app_bar.dart';
import '../widgets/date_selector.dart';
import '../widgets/presensi_summary_chart.dart';
import '../widgets/additional_filters.dart';
import '../widgets/siswa_list.dart';
import '../controllers/rekap_presensi_controller.dart';

class RekapPresensiPage extends StatefulWidget {
  final dynamic kelasId; // Changed from int? to dynamic to support UUID
  final dynamic subjectId; // Changed from int? to dynamic to support UUID
  final String? subjectName;
  final String? kelasName;
  final String? teacherName;
  final String? teacherId;
  final dynamic timeSlotId; // Added to support time slot ID from main rekap

  const RekapPresensiPage({
    super.key,
    this.kelasId,
    this.subjectId,
    this.subjectName,
    this.kelasName,
    this.teacherName,
    this.teacherId,
    this.timeSlotId,
  });

  @override
  _RekapPresensiPageState createState() => _RekapPresensiPageState();
}

class _RekapPresensiPageState extends State<RekapPresensiPage> {
  late RekapPresensiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RekapPresensiController();

    // Initialize controller dengan parameter yang diberikan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize(
        kelasId: widget.kelasId,
        subjectId: widget.subjectId,
        timeSlotId: widget.timeSlotId,
        teacherName: widget.teacherName,
        subjectName: widget.subjectName,
        kelasName: widget.kelasName,
        teacherId: widget.teacherId,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF5),
        body: SafeArea(
          child: Consumer<RekapPresensiController>(
            builder: (context, controller, child) {
              if (controller.isLoading && !controller.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F7836)),
                );
              }

              if (controller.errorMessage != null &&
                  !controller.isInitialized) {
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

              // Convert attendance records ke format yang diharapkan widget lama
              final siswaList =
                  controller.filteredAttendanceRecords.map((record) {
                    return {
                      'nama': record.student.user.name,
                      'nis': record.student.nim,
                      'kelas': controller.subjectInfo?.kelas ?? '',
                      'status': record.statusDisplay,
                    };
                  }).toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RekapPresensiCustomAppBar(),

                    // Subject and Level Information
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F7836,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: Color(0xFF0F7836),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mata Pelajaran',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      controller
                                              .subjectInfo
                                              ?.namaMataPelajaran ??
                                          widget.subjectName ??
                                          'Tidak tersedia',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F7836),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F7836,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: Color(0xFF0F7836),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kelas/Jenjang',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      controller.subjectInfo?.kelas ??
                                          'Tidak tersedia',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F7836),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Date selector untuk memilih tanggal
                    const DateSelector(),

                    const PresensiSummaryChart(),

                    AdditionalFilters(
                      onSemuaTerabsensiChanged: (value) {
                        controller.setSemuaTerabsensi(value);
                      },
                      onSearchChanged: (value) {
                        controller.setSearchQuery(value);
                      },
                    ),

                    SiswaList(
                      siswaList: siswaList,
                      semuaTerabsensi: controller.semuaTerabsensi,
                      searchQuery: controller.searchQuery,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
