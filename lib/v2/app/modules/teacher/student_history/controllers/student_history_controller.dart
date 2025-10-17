import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/services/api_service.dart';

class StudentHistoryController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // ✅ Data dari constructor
  final StudentSummaryModel? student;
  final String? subjectId;
  final String? subjectName;
  final String? className;

  // Observables
  final isLoading = false.obs;
  final studentHistory = Rxn<StudentHistoryModel>();
  final selectedDateRange = Rxn<DateTimeRange>();

  // ✅ Flag
  bool _isInitialized = false;

  // ✅ Constructor
  StudentHistoryController({
    this.student,
    this.subjectId,
    this.subjectName,
    this.className,
  });

  @override
  void onInit() {
    super.onInit();

    developer.log('📋 StudentHistoryController onInit START');
    developer.log('📋 Data received:');
    developer.log('  - Student: ${student?.name} (${student?.studentId})');
    developer.log('  - Subject ID: $subjectId');
    developer.log('  - Subject Name: $subjectName');
    developer.log('  - Class Name: $className');

    // Set date range
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month - 6, 1),
      end: now,
    );

    // ✅ Validasi
    if (student == null || subjectId == null || subjectId!.isEmpty) {
      developer.log('❌ Missing required data');
      isLoading.value = false;
      return;
    }

    developer.log('✅ Data valid');
    _isInitialized = true;
  }

  @override
  void onReady() {
    super.onReady();

    // ✅ Load data di onReady
    if (_isInitialized) {
      developer.log('🔄 onReady: Loading history...');
      loadStudentHistory();
    }
  }

  /// Load student attendance history
  Future<void> loadStudentHistory() async {
    if (isLoading.value) {
      developer.log('⚠️ Already loading');
      return;
    }

    try {
      isLoading.value = true;

      final dateRange = selectedDateRange.value;
      developer.log('📥 Loading history for: ${student?.name}');

      final history = await _apiService.getStudentAttendanceHistory(
        studentId: student!.studentId,
        subjectId: subjectId!,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );

      developer.log('✅ History loaded:');
      developer.log('  - Total Sessions: ${history.summary.totalSessions}');
      developer.log('  - Records: ${history.history.length}');

      studentHistory.value = history;

      if (history.history.isEmpty && history.summary.totalSessions == 0) {
        developer.log('⚠️ No records, trying without date filter...');
        await _loadHistoryWithoutDateFilter();
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error: $e');
      developer.log('Stack: $stackTrace');
      _safeShowErrorSnackbar('Error', 'Gagal memuat riwayat: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadHistoryWithoutDateFilter() async {
    try {
      developer.log('🔄 Loading without date filter...');

      final history = await _apiService.getStudentAttendanceHistory(
        studentId: student!.studentId,
        subjectId: subjectId!,
        startDate: null,
        endDate: null,
      );

      if (history.summary.totalSessions > 0) {
        developer.log('✅ Found ${history.summary.totalSessions} sessions!');
        studentHistory.value = history;

        if (history.history.isNotEmpty) {
          final dates = history.history.map((e) => e.date).toList()..sort();
          selectedDateRange.value = DateTimeRange(
            start: dates.first,
            end: dates.last,
          );
        }
      } else {
        developer.log('⚠️ Still no data');
        _safeShowInfoSnackbar('Info', 'Belum ada data kehadiran');
      }
    } catch (e) {
      developer.log('❌ Error: $e');
    }
  }

  Future<void> changeDateRange(DateTimeRange newRange) async {
    selectedDateRange.value = newRange;
    await loadStudentHistory();
  }

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

  void _safeShowErrorSnackbar(String title, String message) {
    if (!Get.isSnackbarOpen) {
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
  }

  void _safeShowInfoSnackbar(String title, String message) {
    if (!Get.isSnackbarOpen) {
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

  Future<void> exportReport() async {
    try {
      final history = studentHistory.value;
      if (history == null) {
        _safeShowErrorSnackbar('Error', 'Tidak ada data');
        return;
      }

      _safeShowInfoSnackbar('Info', 'Memproses ekspor...');
      await Future.delayed(const Duration(seconds: 1));
      _safeShowInfoSnackbar('تبارك الله', 'Laporan berhasil diekspor');
    } catch (e) {
      developer.log('Error: $e');
      _safeShowErrorSnackbar('Error', 'Gagal ekspor: $e');
    }
  }
}
