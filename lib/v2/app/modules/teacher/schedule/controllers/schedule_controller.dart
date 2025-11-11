// lib/v2/app/modules/teacher/schedule/controllers/schedule_controller.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/routes/app_routes.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../attendance/bindings/attendance_binding.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/views/attendance_view.dart';

class ScheduleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

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
      developer.log('📅 Loading weekly schedule from API');

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
          '✅ Loaded schedules for ${schedulesByDay.keys.length} days from API',
        );

        // ✅ Check isDone status dari storage untuk semua schedules
        _updateSchedulesFromStorage();

        if (schedulesByDay.isEmpty) {
          developer.log('⚠️ No schedules found, loading sample data');
          _loadSampleWeeklyData();
        }
      } catch (apiError) {
        developer.log('❌ API request failed: $apiError, using sample data');
        _loadSampleWeeklyData();
      }
    } catch (e) {
      developer.log('❌ Error loading schedule: $e');
      _showErrorSnackbar('Error', 'Gagal memuat jadwal: $e');
      _loadSampleWeeklyData();
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Update schedules isDone status dari storage
  void _updateSchedulesFromStorage() {
    developer.log('🔄 Updating schedules isDone from storage...');

    int updatedCount = 0;
    for (var entry in schedulesByDay.entries) {
      final day = entry.key;
      final schedules = entry.value;

      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final scheduleDate = getDateForDay(schedule.day);
        final formattedDate =
            '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}';

        final isDoneInStorage = _storageService.isScheduleDone(
          schedule.id,
          formattedDate,
        );

        if (isDoneInStorage && !schedule.isDone) {
          schedulesByDay[day]![i] = schedule.copyWith(isDone: true);
          updatedCount++;
          developer.log(
            '✅ Updated ${schedule.subjectName} isDone from storage',
          );
        }
      }
    }

    if (updatedCount > 0) {
      developer.log('✅ Updated $updatedCount schedules from storage');
      schedulesByDay.refresh();
    }
  }

  void _loadSampleWeeklyData() {
    developer.log('📝 Loading sample weekly schedule data');
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
      '✅ Sample weekly data loaded for ${schedulesByDay.keys.length} days',
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
      developer.log('📅 Selected day: $day');
    }
  }

  void changeWeek(int weekOffset) {
    final newWeek = currentWeek.value.add(Duration(days: weekOffset * 7));
    currentWeek.value = _getWeekStart(newWeek);
    developer.log('📅 Changed to week: ${_getWeekStart(newWeek)}');

    // Reload schedules for new week
    loadWeeklySchedule();
  }

  // ✅ NEW: Update isDone status for specific schedule (optimistic update)
  void updateScheduleIsDone(String scheduleId, bool isDone) {
    developer.log('=== UPDATING SCHEDULE ISDONE ===');
    developer.log('Schedule ID: $scheduleId');
    developer.log('isDone: $isDone');

    bool found = false;

    // Update di semua hari
    for (var entry in schedulesByDay.entries) {
      final day = entry.key;
      final schedules = entry.value;

      // Cari schedule dengan ID yang sesuai
      final index = schedules.indexWhere((s) => s.id == scheduleId);

      if (index != -1) {
        // Update schedule dengan isDone baru
        final oldSchedule = schedules[index];
        final updatedSchedule = oldSchedule.copyWith(isDone: isDone);

        schedulesByDay[day]![index] = updatedSchedule;

        developer.log('✅ Updated schedule in day: $day');
        developer.log('   Subject: ${oldSchedule.subjectName}');
        developer.log('   Old isDone: ${oldSchedule.isDone}');
        developer.log('   New isDone: ${updatedSchedule.isDone}');

        found = true;

        // Trigger UI update
        schedulesByDay.refresh();
        break;
      }
    }

    if (!found) {
      developer.log('⚠️ Schedule not found in schedulesByDay');
      developer.log('   Searching schedule ID: $scheduleId');
      developer.log('   Available schedule IDs:');
      for (var entry in schedulesByDay.entries) {
        for (var schedule in entry.value) {
          developer.log(
            '     - ${schedule.id} (${schedule.subjectName} - ${schedule.day})',
          );
        }
      }
    }

    developer.log('================================');
  }

  /// Navigate to attendance and handle result
  void navigateToAttendance(TodayScheduleModel schedule) async {
    developer.log('=== NAVIGATING TO ATTENDANCE ===');
    developer.log('Schedule ID: ${schedule.id}');
    developer.log('Subject: ${schedule.subjectName}');
    developer.log('Class: ${schedule.className}');
    developer.log('Day: ${schedule.day}');

    final scheduleDate = getDateForDay(schedule.day);
    final formattedDate =
        '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}';

    developer.log('Calculated Date: $formattedDate');
    developer.log('================================');

    try {
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

      Get.parameters = arguments.map((k, v) => MapEntry(k, v.toString()));

      if (Get.isRegistered<AttendanceController>()) {
        Get.delete<AttendanceController>(force: true);
        developer.log('🗑️ Deleted old AttendanceController');
      }

      Get.put(AttendanceController());
      developer.log('✅ Put new AttendanceController');

      // ✅ Navigate dan tunggu result
      final result = await Navigator.of(Get.context!).push(
        MaterialPageRoute(
          builder: (context) {
            AttendanceBinding().dependencies();
            return const AttendanceView();
          },
          settings: RouteSettings(name: '/attendance', arguments: arguments),
        ),
      );

      // ✅ Handle result: jika true, refresh schedule
      if (result == true) {
        developer.log('🔄 Attendance submitted, refreshing schedule...');
        await loadWeeklySchedule();
        developer.log('✅ Schedule refreshed after attendance');
      }

      developer.log('✅ Navigation completed');
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
