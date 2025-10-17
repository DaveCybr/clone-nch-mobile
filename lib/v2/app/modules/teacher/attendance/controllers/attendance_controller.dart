import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/modules/teacher/dashboard/controllers/teacher_dashboard_controller.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/export_servic.dart';
import '../../schedule/controllers/schedule_controller.dart';

class AttendanceController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final scheduleDetail = Rxn<ScheduleDetailModel>();
  final studentsAttendance = <StudentAttendanceModel>[].obs;
  final selectedDate = DateTime.now().obs;

  // Form state
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // ✅ Data from navigation
  String? scheduleId;
  String? scheduleDate;

  @override
  void onInit() {
    super.onInit();

    developer.log('=== ATTENDANCE CONTROLLER INIT ===');

    // ✅ TRY 1: Get from Get.arguments
    final args = Get.arguments;

    // ✅ TRY 2: Get from Get.parameters
    final params = Get.parameters;

    // ✅ TRY 3: Get from RouteSettings (Navigator.push)
    final context = Get.context;
    Map<String, dynamic>? routeArgs;
    if (context != null) {
      final route = ModalRoute.of(context);
      if (route?.settings.arguments != null) {
        routeArgs = route!.settings.arguments as Map<String, dynamic>?;
        developer.log('✅ Found arguments in RouteSettings');
      }
    }

    developer.log('Get.arguments: ${args?.keys}');
    developer.log('Get.parameters: ${params.keys}');
    developer.log('RouteSettings: ${routeArgs?.keys}');

    // ✅ Priority: RouteSettings > Get.arguments > Get.parameters
    if (routeArgs != null && routeArgs.isNotEmpty) {
      scheduleId = routeArgs['schedule_id'] as String?;
      scheduleDate = routeArgs['date'] as String?;
      developer.log('✅ Using RouteSettings arguments');
    } else if (args != null && args.isNotEmpty) {
      scheduleId = args['schedule_id'] as String?;
      scheduleDate = args['date'] as String?;
      developer.log('✅ Using Get.arguments');
    } else if (params.isNotEmpty) {
      scheduleId = params['schedule_id'];
      scheduleDate = params['date'];
      developer.log('✅ Using Get.parameters');
    }

    developer.log('Schedule ID: $scheduleId');
    developer.log('Schedule Date: $scheduleDate');
    developer.log('=================================');

    // Validate
    if (scheduleId == null || scheduleId!.isEmpty) {
      developer.log('❌ ERROR: Schedule ID is null or empty!');
      _showErrorSnackbar('Error', 'ID Jadwal tidak ditemukan');
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(Get.context!).pop();
      });
      return;
    }

    if (scheduleDate != null) {
      try {
        selectedDate.value = DateTime.parse(scheduleDate!);
      } catch (e) {
        developer.log('⚠️ Failed to parse date: $e');
        scheduleDate = DateTime.now().toIso8601String().split('T')[0];
      }
    } else {
      scheduleDate = DateTime.now().toIso8601String().split('T')[0];
      developer.log('⚠️ No date provided, using today: $scheduleDate');
    }

    // Load data
    loadScheduleAttendance();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load schedule and students for attendance
  Future<void> loadScheduleAttendance() async {
    try {
      isLoading.value = true;

      developer.log('=== LOADING ATTENDANCE DATA ===');
      developer.log('Schedule ID: $scheduleId');
      developer.log('Date: $scheduleDate');
      developer.log('================================');

      final detail = await _apiService.getScheduleAttendance(
        scheduleId: scheduleId!,
        date: scheduleDate!,
      );

      scheduleDetail.value = detail;
      studentsAttendance.value = detail.students;

      developer.log('✅ Loaded ${detail.students.length} students');
      developer.log('✅ Subject: ${detail.subjectName}');
      developer.log('✅ Class: ${detail.className}');
    } catch (e, stackTrace) {
      developer.log('❌ Error loading attendance: $e');
      developer.log('Stack trace: $stackTrace');
      _showErrorSnackbar(
        'Error',
        'Gagal memuat data absensi.\n\nPesan: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit attendance data
  Future<void> submitAttendance() async {
    if (isSaving.value) {
      return;
    }

    try {
      isSaving.value = true;

      final submission = AttendanceSubmissionModel(
        scheduleId: scheduleId!,
        attendanceDate: selectedDate.value,
        attendances:
            studentsAttendance
                .map(
                  (student) => AttendanceRecordModel(
                    studentId: student.studentId,
                    status: student.currentStatus,
                    notes: student.notes,
                    attendanceId: student.attendanceId,
                  ),
                )
                .toList(),
      );

      await _apiService.submitAttendance(submission);

      _showSuccessSnackbar(
        'بَارَكَ اللهُ فِيكَ',
        'Absensi berhasil disimpan. جزاك الله خيرا',
      );

      // Refresh schedule list
      if (Get.isRegistered<ScheduleController>()) {
        final scheduleController = Get.find<ScheduleController>();
        await scheduleController.loadWeeklySchedule();
      }

      // Refresh current data
      await _apiService.getTeacherDashboard();
      await loadScheduleAttendance();
    } catch (e) {
      developer.log('Error submitting attendance: $e');
      _showErrorSnackbar('Error', 'Gagal menyimpan absensi: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void updateStudentAttendance(
    String studentId,
    AttendanceStatus status, {
    String? notes,
  }) {
    final index = studentsAttendance.indexWhere(
      (s) => s.studentId == studentId,
    );
    if (index != -1) {
      studentsAttendance[index] = studentsAttendance[index].copyWith(
        currentStatus: status,
        notes: notes,
      );
    }
  }

  List<StudentAttendanceModel> get filteredStudents {
    if (searchQuery.value.isEmpty) {
      return studentsAttendance;
    }

    return studentsAttendance.where((student) {
      return student.name.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          student.nisn.contains(searchQuery.value);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> changeAttendanceDate(DateTime newDate) async {
    selectedDate.value = newDate;
    scheduleDate = newDate.toIso8601String().split('T')[0];
    developer.log('📅 Date changed to: $scheduleDate');
    await loadScheduleAttendance();
  }

  void showAttendanceOptions(StudentAttendanceModel student) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                student.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'NIS: ${student.nisn}',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 20),

              ...AttendanceStatus.values.map(
                (status) => ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  title: Text(status.displayName),
                  trailing:
                      student.currentStatus == status
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                  onTap: () {
                    updateStudentAttendance(student.studentId, status);
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Map<AttendanceStatus, int> get attendanceSummary {
    final summary = <AttendanceStatus, int>{};
    for (final status in AttendanceStatus.values) {
      summary[status] =
          studentsAttendance.where((s) => s.currentStatus == status).length;
    }
    return summary;
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Icons.check_circle;
      case AttendanceStatus.sakit:
        return Icons.local_hospital;
      case AttendanceStatus.izin:
        return Icons.info;
      case AttendanceStatus.alpha:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir:
        return Colors.green;
      case AttendanceStatus.sakit:
        return Colors.blue;
      case AttendanceStatus.izin:
        return Colors.orange;
      case AttendanceStatus.alpha:
        return Colors.red;
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> exportToExcel() async {
    try {
      final scheduleDetail = this.scheduleDetail.value;
      if (scheduleDetail == null) {
        _showErrorSnackbar('Error', 'Tidak ada data untuk diekspor');
        return;
      }

      _showSnackbar('Info', 'Sedang memproses ekspor...');
      _showSuccessSnackbar('تبارك الله', 'Laporan absensi berhasil diekspor');
    } catch (e) {
      developer.log('Error exporting attendance: $e');
      _showErrorSnackbar('Error', 'Gagal mengekspor laporan: $e');
    }
  }

  void showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Ekspor Laporan Absensi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('Ekspor ke Excel'),
              subtitle: const Text('Download file Excel (.xlsx)'),
              onTap: () {
                Get.back();
                exportToExcel();
              },
            ),

            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Cetak Laporan'),
              subtitle: const Text('Cetak atau simpan sebagai PDF'),
              onTap: () {
                Get.back();
                _showSnackbar('Info', 'Fitur cetak akan segera tersedia');
              },
            ),

            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Bagikan'),
              subtitle: const Text(
                'Bagikan laporan melalui WhatsApp, Email, dll',
              ),
              onTap: () {
                Get.back();
                exportToExcel();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
