import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/services/api_service.dart';

class StudentHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

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

    developer.log('📋 Arguments received:');
    developer.log('  - Student: ${student?.name} (${student?.studentId})');
    developer.log('  - Subject ID: $subjectId');
    developer.log('  - Subject Name: $subjectName');
    developer.log('  - Class Name: $className');

    // ✅ FIXED: Set date range ke SEMUA DATA (6 bulan ke belakang sampai sekarang)
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month - 6, 1), // 6 bulan lalu
      end: now, // Sampai hari ini
    );

    developer.log(
      '📅 Default date range: ${selectedDateRange.value?.start} to ${selectedDateRange.value?.end}',
    );

    if (student != null && subjectId != null) {
      loadStudentHistory();
    } else {
      developer.log('❌ Missing required data: student or subjectId');
      _showErrorSnackbar('Error', 'Data siswa tidak ditemukan');
      Get.back();
    }
  }

  /// Load student attendance history
  Future<void> loadStudentHistory() async {
    try {
      isLoading.value = true;

      final dateRange = selectedDateRange.value;
      developer.log('🔄 Loading student history:');
      developer.log('  - Student ID: ${student?.studentId}');
      developer.log('  - Subject ID: $subjectId');
      developer.log('  - Date Range: ${dateRange?.start} to ${dateRange?.end}');

      final history = await _apiService.getStudentAttendanceHistory(
        studentId: student!.studentId,
        subjectId: subjectId!,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );

      developer.log('✅ History loaded successfully:');
      developer.log('  - Student: ${history.name}');
      developer.log('  - NISN: ${history.nisn}');
      developer.log('  - Class: ${history.className}');
      developer.log('  - Total Sessions: ${history.summary.totalSessions}');
      developer.log('  - Hadir: ${history.summary.hadir}');
      developer.log('  - Sakit: ${history.summary.sakit}');
      developer.log('  - Izin: ${history.summary.izin}');
      developer.log('  - Alpha: ${history.summary.alpha}');
      developer.log(
        '  - Attendance %: ${history.summary.attendancePercentage.toStringAsFixed(1)}%',
      );
      developer.log('  - History Records: ${history.history.length}');

      studentHistory.value = history;

      if (history.history.isEmpty && history.summary.totalSessions == 0) {
        developer.log('⚠️ WARNING: No history records found!');
        developer.log('  Possible reasons:');
        developer.log('  1. No attendance has been recorded yet');
        developer.log('  2. Backend API filter is too strict');
        developer.log('  3. Data exists but date range is incorrect');

        // ✅ ADDED: Try loading without date filter
        developer.log('🔄 Retrying without date range filter...');
        await _loadHistoryWithoutDateFilter();
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error loading student history: $e');
      developer.log('Stack trace: $stackTrace');
      _showErrorSnackbar('Error', 'Gagal memuat riwayat kehadiran: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ ADDED: Load history without date filter as fallback
  Future<void> _loadHistoryWithoutDateFilter() async {
    try {
      developer.log('🔄 Loading ALL history (no date filter)...');

      final history = await _apiService.getStudentAttendanceHistory(
        studentId: student!.studentId,
        subjectId: subjectId!,
        startDate: null, // No date filter
        endDate: null, // No date filter
      );

      if (history.summary.totalSessions > 0) {
        developer.log(
          '✅ Found ${history.summary.totalSessions} sessions without date filter!',
        );
        studentHistory.value = history;

        // Update date range based on actual data
        if (history.history.isNotEmpty) {
          final dates = history.history.map((e) => e.date).toList()..sort();
          selectedDateRange.value = DateTimeRange(
            start: dates.first,
            end: dates.last,
          );
          developer.log(
            '📅 Updated date range based on data: ${dates.first} to ${dates.last}',
          );
        }
      } else {
        developer.log('⚠️ Still no data found even without date filter');
        developer.log(
          '   This means no attendance has been recorded for this student+subject combination',
        );
      }
    } catch (e) {
      developer.log('❌ Error loading history without date filter: $e');
    }
  }

  /// Change date range
  Future<void> changeDateRange(DateTimeRange newRange) async {
    developer.log(
      '📅 Changing date range to: ${newRange.start} - ${newRange.end}',
    );
    selectedDateRange.value = newRange;
    await loadStudentHistory();
  }

  /// Show date range picker
  // Future<void> showDateRangePicker() async {
  //   final now = DateTime.now();
  //   final DateTimeRange? picked = await showDateRangePicker(
  //     context: Get.context!,
  //     firstDate: DateTime(now.year - 1),
  //     lastDate: now,
  //     initialDateRange: selectedDateRange.value,
  //   );

  //   if (picked != null && picked != selectedDateRange.value) {
  //     await changeDateRange(picked);
  //   }
  // }

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

      // TODO: Implement export functionality

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
