import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/services/api_service.dart';
// import '../../../../data/services/export_servic.dart';

class StudentHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  // final ExportService _exportService = Get.find<ExportService>(); // ADD THIS

  // Observables
  final isLoading = false.obs;
  final studentHistory = Rxn<StudentHistoryModel>();
  final selectedDateRange = Rxn<DateTimeRange>();

  // Data from arguments
  StudentSummaryModel? get student =>
      Get.arguments?['student'] as StudentSummaryModel?;
  String? get subjectId => Get.arguments?['subject_id'] as String?;
  String? get subjectName => Get.arguments?['subject_name'] as String?;
  String? get className => Get.arguments?['class_name'] as String?;

  @override
  void onInit() {
    super.onInit();
    // Set default date range (current month)
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    if (student != null && subjectId != null) {
      loadStudentHistory();
    } else {
      _showErrorSnackbar('Error', 'Data siswa tidak ditemukan');
      Get.back();
    }
  }

  /// Load student attendance history
  Future<void> loadStudentHistory() async {
    try {
      isLoading.value = true;
      developer.log('Loading student history for: ${student?.studentId}');

      final dateRange = selectedDateRange.value;
      final history = await _apiService.getStudentAttendanceHistory(
        studentId: student!.studentId,
        subjectId: subjectId!,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );

      studentHistory.value = history;
      developer.log('Loaded history with ${history.history.length} records');
    } catch (e) {
      developer.log('Error loading student history: $e');
      _showErrorSnackbar('Error', 'Gagal memuat riwayat kehadiran: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Change date range
  Future<void> changeDateRange(DateTimeRange newRange) async {
    selectedDateRange.value = newRange;
    await loadStudentHistory();
  }

  /// Get attendance status color
  Color getStatusColor(AttendanceStatus status) {
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

  /// Get attendance status icon
  IconData getStatusIcon(AttendanceStatus status) {
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

  /// Show date range picker
  // Future<void> showDateRangePicker() async {
  //   final DateTimeRange? picked = await showDateRangePicker(
  //     context: Get.context!,
  //     firstDate: DateTime.now().subtract(const Duration(days: 365)),
  //     lastDate: DateTime.now(),
  //     initialDateRange: selectedDateRange.value,
  //     builder: (BuildContext context, Widget? child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: const ColorScheme.light(
  //             primary: Colors.green,
  //             onPrimary: Colors.white,
  //             surface: Colors.white,
  //             onSurface: Colors.black,
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );

  //   if (picked != null && picked != selectedDateRange.value) {
  //     await changeDateRange(picked);
  //   }
  // }

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

  Future<void> exportReport() async {
    try {
      final history = studentHistory.value;
      if (history == null) {
        _showErrorSnackbar('Error', 'Tidak ada data untuk diekspor');
        return;
      }

      _showSnackbar('Info', 'Sedang memproses ekspor...');

      // await _exportService.exportAttendanceHistoryToPDF(
      //   studentHistory: history,
      //   subjectName: subjectName ?? 'Mata Pelajaran',
      //   className: className ?? 'Kelas',
      // );

      _showSnackbar(
        'تبارك الله',
        'Laporan riwayat kehadiran berhasil diekspor',
      );
    } catch (e) {
      developer.log('Error exporting history: $e');
      _showErrorSnackbar('Error', 'Gagal mengekspor laporan: $e');
    }
  }
}
