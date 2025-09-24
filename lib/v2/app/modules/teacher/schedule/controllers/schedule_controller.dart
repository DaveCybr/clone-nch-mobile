// Fixed ScheduleController.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class ScheduleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final selectedDay = DateTime.now().weekday.obs;
  final weekSchedules = <List<TodayScheduleModel>>[].obs;
  final selectedDate = DateTime.now().obs;

  // Days of week
  final List<String> daysOfWeek = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  final List<String> arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  void onInit() {
    super.onInit();
    developer.log('ScheduleController: onInit called');
    loadWeekSchedule();
  }

  @override
  void onClose() {
    developer.log('ScheduleController: onClose called');
    super.onClose();
  }

  /// Load schedule for entire week
  Future<void> loadWeekSchedule() async {
    try {
      isLoading.value = true;
      developer.log('Loading week schedule');

      // Get current week's start and end
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      final response = await _apiService.getTeacherSchedules(
        date: startOfWeek.toIso8601String().split('T')[0],
      );

      // Group schedules by day
      final Map<int, List<TodayScheduleModel>> schedulesByDay = {};

      for (var schedule in response) {
        final model = TodayScheduleModel.fromJson(schedule);
        final dayIndex = _getDayIndex(model.day);

        if (schedulesByDay[dayIndex] == null) {
          schedulesByDay[dayIndex] = [];
        }
        schedulesByDay[dayIndex]!.add(model);
      }

      // Convert to list format
      final weekList = <List<TodayScheduleModel>>[];
      for (int i = 1; i <= 7; i++) {
        weekList.add(schedulesByDay[i] ?? []);
      }

      weekSchedules.value = weekList;
      developer.log('Loaded schedules for ${weekList.length} days');
    } catch (e) {
      developer.log('Error loading schedule: $e');
      _showErrorSnackbar('Error', 'Gagal memuat jadwal: $e');
      // Create empty week structure on error
      weekSchedules.value = List.generate(7, (_) => []);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get schedules for selected day
  List<TodayScheduleModel> get selectedDaySchedules {
    final schedules = weekSchedules.value;
    if (schedules.isEmpty) return [];

    final index = selectedDay.value - 1; // Convert to 0-based index
    if (index < 0 || index >= schedules.length) return [];

    return schedules[index];
  }

  /// Change selected day
  void selectDay(int dayIndex) {
    final newDay = dayIndex + 1; // Convert to 1-based weekday
    if (newDay != selectedDay.value) {
      selectedDay.value = newDay;
      developer.log('Selected day changed to: ${daysOfWeek[dayIndex]}');
    }
  }

  /// Navigate to attendance
  void navigateToAttendance(TodayScheduleModel schedule) {
    developer.log('Navigating to attendance for schedule: ${schedule.id}');

    try {
      Get.toNamed(
        '/teacher/attendance',
        arguments: {'schedule': schedule, 'schedule_id': schedule.id},
      );
    } catch (e) {
      developer.log('Navigation error: $e');
      _showErrorSnackbar('Error', 'Tidak dapat membuka halaman absensi');
    }
  }

  /// Get day index from string
  int _getDayIndex(String dayName) {
    switch (dayName.toLowerCase()) {
      case 'senin':
      case 'monday':
        return 1;
      case 'selasa':
      case 'tuesday':
        return 2;
      case 'rabu':
      case 'wednesday':
        return 3;
      case 'kamis':
      case 'thursday':
        return 4;
      case 'jumat':
      case 'friday':
        return 5;
      case 'sabtu':
      case 'saturday':
        return 6;
      case 'minggu':
      case 'sunday':
        return 7;
      default:
        return 1;
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
}
