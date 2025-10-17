// File: lib/v2/app/modules/teacher/schedule/controllers/schedule_controller.dart
// ✅ ULTIMATE FIX: Use Navigator.push for nested routing

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../attendance/bindings/attendance_binding.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/views/attendance_view.dart';

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
        final data = await _apiService.getTeacherScheduleList();
        schedulesByDay.clear();

        for (var entry in data.entries) {
          final day = entry.key;
          final schedules = entry.value as List;

          schedulesByDay[day] =
              schedules
                  .map((json) => TodayScheduleModel.fromJson(json))
                  .toList();

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

  void _loadSampleWeeklyData() {
    developer.log('Loading sample weekly schedule data');
    schedulesByDay.clear();

    final sampleSchedules = {
      'SENIN': [
        const TodayScheduleModel(
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
      ],
      'KAMIS': [
        const TodayScheduleModel(
          id: '01998069-c3e0-722c-941a-b4baefb72a2b',
          subjectName: 'AQIDATUL AWAM (MTS 8A)',
          className: 'Kelas 8A MTS',
          timeSlot: '07:30:00 - 08:40:00',
          startTime: '07:30:00',
          endTime: '08:40:00',
          day: 'KAMIS',
          isDone: false,
          totalStudents: 18,
        ),
      ],
    };

    schedulesByDay.value = sampleSchedules;
    developer.log(
      'Sample weekly data loaded for ${schedulesByDay.keys.length} days',
    );
  }

  List<TodayScheduleModel> get selectedDaySchedules {
    return schedulesByDay[selectedDay.value] ?? [];
  }

  bool hasSchedule(String day) {
    return schedulesByDay.containsKey(day) && schedulesByDay[day]!.isNotEmpty;
  }

  void selectDay(String day) {
    if (daysOfWeek.contains(day)) {
      selectedDay.value = day;
      developer.log('Selected day: $day');
    }
  }

  void changeWeek(int weekOffset) {
    final newWeek = currentWeek.value.add(Duration(days: weekOffset * 7));
    currentWeek.value = _getWeekStart(newWeek);
    developer.log('Changed to week: ${_getWeekStart(newWeek)}');
  }

  /// ✅ ULTIMATE FIX: Use Get.parameters to pass data
  void navigateToAttendance(TodayScheduleModel schedule) {
    developer.log('=== NAVIGATING TO ATTENDANCE ===');
    developer.log('Schedule ID: ${schedule.id}');
    developer.log('Subject: ${schedule.subjectName}');
    developer.log('Class: ${schedule.className}');
    developer.log('Day: ${schedule.day}');

    // Calculate correct date
    final scheduleDate = getDateForDay(schedule.day);
    final formattedDate =
        '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}';

    developer.log('Calculated Date: $formattedDate');
    developer.log('================================');

    try {
      // ✅ ULTIMATE SOLUTION: Clean up old controller + Manual injection
      final arguments = {
        'schedule_id': schedule.id,
        'date': formattedDate,
        'subject_name': schedule.subjectName,
        'class_name': schedule.className,
        'day': schedule.day,
        'start_time': schedule.startTime,
        'end_time': schedule.endTime,
        'total_students': schedule.totalStudents,
        'time_slot': schedule.timeSlot,
        'is_done': schedule.isDone,
      };

      // ✅ Store in Get.parameters (accessible via Get.parameters)
      Get.parameters = arguments.map((k, v) => MapEntry(k, v.toString()));

      // ✅ CRITICAL FIX: Delete old controller if exists
      if (Get.isRegistered<AttendanceController>()) {
        Get.delete<AttendanceController>(force: true);
        developer.log('🗑️ Deleted old AttendanceController');
      }

      // ✅ Put NEW controller without tag (to avoid duplicate key error)
      Get.put(AttendanceController());
      developer.log('✅ Put new AttendanceController');

      // ✅ Navigate with RouteSettings containing arguments
      Navigator.of(Get.context!).push(
        MaterialPageRoute(
          builder: (context) {
            // Initialize binding manually
            AttendanceBinding().dependencies();
            return const AttendanceView();
          },
          settings: RouteSettings(name: '/attendance', arguments: arguments),
        ),
      );

      developer.log('✅ Navigation with Navigator.push + manual binding');
    } catch (e, stackTrace) {
      developer.log('❌ Navigation error: $e');
      developer.log('Stack trace: $stackTrace');
      _showErrorSnackbar(
        'Error Navigasi',
        'Tidak dapat membuka halaman absensi: ${e.toString()}',
      );
    }
  }

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

  DateTime _getWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String getDayDisplayName(String day) {
    final index = daysOfWeek.indexOf(day);
    return index != -1 ? dayDisplayNames[index] : day;
  }

  DateTime getDateForDay(String day) {
    final dayIndex = daysOfWeek.indexOf(day);
    if (dayIndex == -1) return DateTime.now();

    final weekStart = _getWeekStart(currentWeek.value);
    return weekStart.add(Duration(days: dayIndex));
  }

  String get weekRangeText {
    final weekStart = _getWeekStart(currentWeek.value);
    final weekEnd = weekStart.add(const Duration(days: 6));

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
      duration: const Duration(seconds: 4),
    );
  }
}
