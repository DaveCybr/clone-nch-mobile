// lib/v2/app/modules/student/schedule/controllers/student_schedule_controller.dart

import 'dart:developer' as developer show log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/models/student_dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../auth/controllers/auth_controller.dart';

class StudentScheduleController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;
  final error = Rx<String?>(null);
  final schedules = <StudentScheduleModel>[].obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
  }

  /// Load schedules by selected date
  Future<void> loadSchedules({DateTime? date}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final targetDate = date ?? selectedDate.value;
      final dateString = _formatDate(targetDate);

      final response = await _apiService.getStudentSchedules(date: dateString);

      developer.log('Schedules response: $response');
      // Parse response
      // if (response is List) {
      //   schedules.value =
      //       response.map((e) => StudentScheduleModel.fromJson(e)).toList();
      // } else if (response['schedules'] != null) {
      //   schedules.value =
      //       (response['schedules'] as List)
      //           .map((e) => StudentScheduleModel.fromJson(e))
      //           .toList();
      // } else if (response['data'] != null) {
      //   schedules.value =
      //       (response['data'] as List)
      //           .map((e) => StudentScheduleModel.fromJson(e))
      //           .toList();
      // }

      // // Sort by time
      // schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat jadwal: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Change selected date
  Future<void> changeDate(DateTime newDate) async {
    selectedDate.value = newDate;
    await loadSchedules(date: newDate);
  }

  /// Pick date from calendar
  Future<void> pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      await changeDate(pickedDate);
    }
  }

  /// Navigate to today
  Future<void> goToToday() async {
    await changeDate(DateTime.now());
  }

  /// Navigate to previous day
  Future<void> previousDay() async {
    final newDate = selectedDate.value.subtract(const Duration(days: 1));
    await changeDate(newDate);
  }

  /// Navigate to next day
  Future<void> nextDay() async {
    final newDate = selectedDate.value.add(const Duration(days: 1));
    await changeDate(newDate);
  }

  /// Refresh schedules
  Future<void> refreshSchedules() async {
    await loadSchedules();
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get formattedSelectedDate {
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
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final date = selectedDate.value;
    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }

  bool get isToday {
    final now = DateTime.now();
    final selected = selectedDate.value;
    return now.year == selected.year &&
        now.month == selected.month &&
        now.day == selected.day;
  }
}
