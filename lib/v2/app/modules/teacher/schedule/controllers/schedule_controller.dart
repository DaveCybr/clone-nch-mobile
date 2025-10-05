// File: lib/v2/app/modules/teacher/schedule/controllers/schedule_controller.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class ScheduleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final selectedWeek = DateTime.now().obs;
  final currentWeek = DateTime.now().obs;
  final schedulesByDay = <String, List<TodayScheduleModel>>{}.obs;
  final selectedDay = 'SENIN'.obs;

  final List<String> daysOfWeek = [
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU',
    'MINGGU',
  ];

  final List<String> dayDisplayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void onInit() {
    super.onInit();
    developer.log('ScheduleController: onInit called');

    final today = DateTime.now();
    selectedDay.value = getTodayDayName();
    selectedWeek.value = _getWeekStart(today);
    currentWeek.value = _getWeekStart(today);

    loadWeeklySchedule();
  }

  Future<void> loadWeeklySchedule() async {
    try {
      isLoading.value = true;
      developer.log('Loading weekly schedule from API');

      try {
        // Call API
        final data = await _apiService.getTeacherScheduleList();

        schedulesByDay.clear();

        // Parse response
        for (var entry in data.entries) {
          final day = entry.key; // "SENIN", "SELASA", etc
          final schedules = entry.value as List;

          schedulesByDay[day] = schedules
              .map((json) => TodayScheduleModel.fromJson(json))
              .toList();

          // Sort by time
          schedulesByDay[day]!.sort(
            (a, b) => a.startTime.compareTo(b.startTime),
          );
        }

        developer.log(
          'Loaded schedules for ${schedulesByDay.keys.length} days from API',
        );

        if (schedulesByDay.isEmpty) {
          developer.log('No schedules found, loading sample data');
          _loadSampleWeeklyData();
        }
      } catch (apiError) {
        developer.log('API request failed: $apiError, using sample data');
        _loadSampleWeeklyData();
      }
    } catch (e) {
      developer.log('Error loading schedule: $e');
      _showErrorSnackbar('Error', 'Gagal memuat jadwal: $e');
      _loadSampleWeeklyData();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load sample weekly data
  void _loadSampleWeeklyData() {
    developer.log('Loading sample weekly schedule data');

    schedulesByDay.clear();

    final sampleSchedules = {
      'SENIN': [
        TodayScheduleModel(
          id: 'senin-1',
          subjectName: 'Fiqih (Thaharah)',
          className: 'Kelas 7A',
          timeSlot: 'Jam 1-2',
          startTime: '07:30',
          endTime: '08:40',
          day: 'SENIN',
          isDone: false,
          totalStudents: 25,
        ),
        TodayScheduleModel(
          id: 'senin-2',
          subjectName: 'Hadits Arba\'in',
          className: 'Kelas 8B',
          timeSlot: 'Jam 3-4',
          startTime: '09:15',
          endTime: '10:25',
          day: 'SENIN',
          isDone: false,
          totalStudents: 22,
        ),
      ],
      'SELASA': [
        TodayScheduleModel(
          id: 'selasa-1',
          subjectName: 'Bahasa Arab 7A',
          className: 'Kelas 7A',
          timeSlot: 'Jam 6',
          startTime: '10:35',
          endTime: '11:10',
          day: 'SELASA',
          isDone: true, // Example: already done
          totalStudents: 25,
        ),
      ],
    };

    schedulesByDay.value = sampleSchedules;
    developer.log(
      'Sample weekly data loaded for ${schedulesByDay.keys.length} days',
    );
  }

  /// Get schedules for selected day
  List<TodayScheduleModel> get selectedDaySchedules {
    return schedulesByDay[selectedDay.value] ?? [];
  }

  /// Check if day has schedules
  bool hasSchedule(String day) {
    return schedulesByDay.containsKey(day) && schedulesByDay[day]!.isNotEmpty;
  }

  /// Select day
  void selectDay(String day) {
    if (daysOfWeek.contains(day)) {
      selectedDay.value = day;
      developer.log('Selected day: $day');
    }
  }

  /// Change week
  void changeWeek(int weekOffset) {
    final newWeek = currentWeek.value.add(Duration(days: weekOffset * 7));
    currentWeek.value = _getWeekStart(newWeek);
    developer.log('Changed to week: ${_getWeekStart(newWeek)}');
  }

  /// Navigate to attendance
  void navigateToAttendance(TodayScheduleModel schedule) {
    developer.log('Navigating to attendance for schedule: ${schedule.id}');

    try {
      Get.toNamed(
        Routes.TEACHER_ATTENDANCE,
        arguments: {'schedule': schedule, 'schedule_id': schedule.id},
      );
    } catch (e) {
      developer.log('Navigation error: $e');
      _showErrorSnackbar('Error', 'Tidak dapat membuka halaman absensi');
    }
  }

  /// Get current day name in database format
  String getTodayDayName() {
    final today = DateTime.now();
    final dayIndex = today.weekday;

    switch (dayIndex) {
      case 1:
        return 'SENIN';
      case 2:
        return 'SELASA';
      case 3:
        return 'RABU';
      case 4:
        return 'KAMIS';
      case 5:
        return 'JUMAT';
      case 6:
        return 'SABTU';
      case 7:
        return 'MINGGU';
      default:
        return 'SENIN';
    }
  }

  /// Get week start date (Monday)
  DateTime _getWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Get display name for day
  String getDayDisplayName(String day) {
    final index = daysOfWeek.indexOf(day);
    return index != -1 ? dayDisplayNames[index] : day;
  }

  /// Get date for specific day in current week
  DateTime getDateForDay(String day) {
    final dayIndex = daysOfWeek.indexOf(day);
    if (dayIndex == -1) return DateTime.now();

    final weekStart = _getWeekStart(currentWeek.value);
    return weekStart.add(Duration(days: dayIndex));
  }

  /// Format week range for display
  String get weekRangeText {
    final weekStart = _getWeekStart(currentWeek.value);
    final weekEnd = weekStart.add(Duration(days: 6));

    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
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
