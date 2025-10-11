// lib/v2/app/modules/student/attendance/controllers/student_attendance_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/models/student_dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class StudentAttendanceController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = Rx<String?>(null);

  final attendances = <StudentAttendanceItemModel>[].obs;
  final selectedDate = Rx<DateTime?>(null);

  // Pagination
  final currentPage = 1.obs;
  final lastPage = 1.obs;
  final totalItems = 0.obs;
  final perPage = 10.obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendances();
  }

  /// Load attendances with pagination and filter
  Future<void> loadAttendances({
    DateTime? date,
    int? page,
    bool append = false,
  }) async {
    try {
      if (append) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      error.value = null;

      final targetPage = page ?? currentPage.value;
      final dateString = date != null ? _formatDate(date) : null;

      final response = await _apiService.getStudentAttendance(
        date: dateString,
        page: targetPage,
        limit: perPage.value,
      );

      // Parse paginated response
      PaginatedAttendanceModel paginatedData;

      if (response['data'] != null &&
          response['data'] is Map &&
          response['data']['data'] is List) {
        // Laravel pagination structure
        paginatedData = PaginatedAttendanceModel.fromJson(response);
      } else if (response['data'] is List) {
        // Direct list
        paginatedData = PaginatedAttendanceModel(
          data:
              (response['data'] as List)
                  .map((e) => StudentAttendanceItemModel.fromJson(e))
                  .toList(),
          currentPage: 1,
          lastPage: 1,
          total: (response['data'] as List).length,
          perPage: 10,
        );
      } else {
        throw Exception('Invalid response structure');
      }

      // Update data
      if (append) {
        attendances.addAll(paginatedData.data);
      } else {
        attendances.value = paginatedData.data;
      }

      currentPage.value = paginatedData.currentPage;
      lastPage.value = paginatedData.lastPage;
      totalItems.value = paginatedData.total;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat data absensi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMorePages) return;

    await loadAttendances(
      date: selectedDate.value,
      page: currentPage.value + 1,
      append: true,
    );
  }

  /// Filter by date
  Future<void> filterByDate(DateTime? date) async {
    selectedDate.value = date;
    currentPage.value = 1;
    await loadAttendances(date: date);
  }

  /// Pick date from calendar
  Future<void> pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      await filterByDate(pickedDate);
    }
  }

  /// Clear date filter
  Future<void> clearDateFilter() async {
    selectedDate.value = null;
    currentPage.value = 1;
    await loadAttendances();
  }

  /// Refresh
  Future<void> refreshAttendances() async {
    currentPage.value = 1;
    await loadAttendances(date: selectedDate.value);
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get hasMorePages => currentPage.value < lastPage.value;

  String? get formattedSelectedDate {
    if (selectedDate.value == null) return null;

    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final date = selectedDate.value!;
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  // Statistics
  int get totalHadir => attendances.where((a) => a.status == 'HADIR').length;

  int get totalSakit => attendances.where((a) => a.status == 'SAKIT').length;

  int get totalIzin => attendances.where((a) => a.status == 'IZIN').length;

  int get totalAlpha => attendances.where((a) => a.status == 'ALPHA').length;

  double get attendancePercentage {
    if (attendances.isEmpty) return 0.0;
    return (totalHadir / attendances.length) * 100;
  }
}
