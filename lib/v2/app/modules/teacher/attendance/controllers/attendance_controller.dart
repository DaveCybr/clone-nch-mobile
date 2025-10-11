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
  // final ExportService _exportService = Get.find<ExportService>();
  // Observables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final scheduleDetail = Rxn<ScheduleDetailModel>();
  final studentsAttendance = <StudentAttendanceModel>[].obs;
  final selectedDate = DateTime.now().obs;

  // Form state
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Schedule info from arguments
  TodayScheduleModel? get schedule =>
      Get.arguments?['schedule'] as TodayScheduleModel?;
  String? get scheduleId =>
      schedule?.id ?? Get.arguments?['schedule_id'] as String?;

  @override
  void onInit() {
    super.onInit();
    if (scheduleId != null) {
      loadScheduleAttendance();
    } else {
      _showErrorSnackbar('Error', 'Jadwal tidak ditemukan');
      Get.back();
    }
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
      var date = selectedDate.value.toIso8601String().substring(0, 10);
      developer.log('Loading attendance for schedule: $scheduleId');
      developer.log('Loading attendance for schedule: $date');

      final detail = await _apiService.getScheduleAttendance(
        scheduleId: scheduleId!,
        date: date,
      );

      scheduleDetail.value = detail;
      studentsAttendance.value = detail.students;

      developer.log('Loaded ${detail.students.length} students');
    } catch (e) {
      developer.log('Error loading attendance: $e');
      _showErrorSnackbar('Error', 'Gagal memuat data absensi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit attendance data
  // File: lib/v2/app/modules/teacher/attendance/controllers/attendance_controller.dart

  /// Submit attendance data (INSERT or UPDATE)
  Future<void> submitAttendance() async {
    if (isSaving.value) {
      return; // Prevent double submission
    }

    try {
      isSaving.value = true;

      // Build submission with attendance_id
      final submission = AttendanceSubmissionModel(
        scheduleId: scheduleId!,
        attendanceDate: selectedDate.value,
        attendances: studentsAttendance
            .map(
              (student) => AttendanceRecordModel(
                studentId: student.studentId,
                status: student.currentStatus,
                notes: student.notes,
                attendanceId: student.attendanceId, // Include this!
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

  /// Update student attendance status
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

  /// Get filtered students based on search
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

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Change attendance date
  Future<void> changeAttendanceDate(DateTime newDate) async {
    selectedDate.value = newDate;
    await loadScheduleAttendance();
  }

  /// Show attendance options bottom sheet
  void showAttendanceOptions(StudentAttendanceModel student) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
<<<<<<< HEAD
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
=======
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
<<<<<<< HEAD
              const SizedBox(height: 20),

              Text(
                student.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
=======
              SizedBox(height: 20),

              Text(
                student.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
              ),
              Text(
                'NIS: ${student.nisn}',
                style: TextStyle(color: Colors.grey[600]),
              ),

<<<<<<< HEAD
              const SizedBox(height: 20),
=======
              SizedBox(height: 20),
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46

              // Attendance options
              ...AttendanceStatus.values.map(
                (status) => ListTile(
                  leading: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                  title: Text(status.displayName),
<<<<<<< HEAD
                  trailing:
                      student.currentStatus == status
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
=======
                  trailing: student.currentStatus == status
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
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

  /// Get attendance summary
  Map<AttendanceStatus, int> get attendanceSummary {
    final summary = <AttendanceStatus, int>{};
    for (final status in AttendanceStatus.values) {
      summary[status] = studentsAttendance
          .where((s) => s.currentStatus == status)
          .length;
    }
    return summary;
  }

  /// Get icon for attendance status
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

  /// Get color for attendance status
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
      duration: const Duration(seconds: 3),
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

      // await _exportService.exportAttendanceToExcel(
      //   className: scheduleDetail.className,
      //   subjectName: scheduleDetail.subjectName,
      //   students: studentsAttendance,
      //   date: selectedDate.value,
      // );

      _showSuccessSnackbar('تبارك الله', 'Laporan absensi berhasil diekspor');
    } catch (e) {
      developer.log('Error exporting attendance: $e');
      _showErrorSnackbar('Error', 'Gagal mengekspor laporan: $e');
    }
  }

  /// Show export options - NEW METHOD
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
            // Header
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

            // Export to Excel option
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('Ekspor ke Excel'),
              subtitle: const Text('Download file Excel (.xlsx)'),
              onTap: () {
                Get.back();
                exportToExcel();
              },
            ),

            // Print option
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Cetak Laporan'),
              subtitle: const Text('Cetak atau simpan sebagai PDF'),
              onTap: () {
                Get.back();
                _showSnackbar('Info', 'Fitur cetak akan segera tersedia');
              },
            ),

            // Share option
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Bagikan'),
              subtitle: const Text('Bagikan laporan melalui WhatsApp, Email, dll'),
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

  // Helper method
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
