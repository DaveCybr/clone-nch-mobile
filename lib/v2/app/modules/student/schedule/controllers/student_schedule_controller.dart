// lib/v2/app/modules/student/schedule/controllers/student_schedule_controller.dart

import 'dart:developer' as developer show log;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/models/student_dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class StudentScheduleController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;
  final error = Rx<String?>(null);
  final schedules = <StudentScheduleModel>[].obs;
  final selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    developer.log('🚀 StudentScheduleController initialized');
    loadSchedules();
  }

  /// Load schedules by selected date
  Future<void> loadSchedules({DateTime? date}) async {
    try {
      isLoading.value = true;
      error.value = null;
      schedules.clear();

      final targetDate = date ?? selectedDate.value;
      final dateString = _formatDate(targetDate);
      final dayName = _getDayName(targetDate);

      developer.log('═══════════════════════════════════════');
      developer.log('🗓️  Loading schedules');
      developer.log('📅 Date: $dateString ($dayName)');
      developer.log('═══════════════════════════════════════');

      final response = await _apiService.getStudentSchedules(date: dateString);

      developer.log('📦 Response received');
      developer.log('📊 Response type: ${response.runtimeType}');
      developer.log('📋 Is List: ${response is List}');

      if (response is List) {
        developer.log('✅ Response length: ${response.length}');

        if (response.isEmpty) {
          developer.log('⚠️  No schedules found for $dayName');
          schedules.value = [];
          return;
        }

        // Log sample data
        developer.log('───────────────────────────────────────');
        developer.log('📄 Sample data (first item):');
        if (response.isNotEmpty) {
          final firstItem = response.first;
          developer.log('   Type: ${firstItem.runtimeType}');
          if (firstItem is Map) {
            developer.log('   Keys: ${firstItem.keys.join(", ")}');
            developer.log(
              '   Subject: ${firstItem['subject_name'] ?? firstItem['subject']}',
            );
            developer.log(
              '   Time: ${firstItem['start_time']} - ${firstItem['end_time']}',
            );
            developer.log(
              '   Teacher: ${firstItem['teacher_name'] ?? firstItem['teacher']}',
            );
          }
        }
        developer.log('───────────────────────────────────────');

        // Parse each item
        List<StudentScheduleModel> parsedSchedules = [];
        int successCount = 0;
        int errorCount = 0;

        for (var i = 0; i < response.length; i++) {
          try {
            final item = response[i];

            if (item is Map<String, dynamic>) {
              final schedule = StudentScheduleModel.fromJson(item);
              parsedSchedules.add(schedule);
              successCount++;

              developer.log(
                '✅ [$i] ${schedule.subjectName} (${schedule.startTime}-${schedule.endTime})',
              );
            } else {
              errorCount++;
              developer.log(
                '⚠️  [$i] Item is not Map<String, dynamic>: ${item.runtimeType}',
              );
            }
          } catch (e, stackTrace) {
            errorCount++;
            developer.log('❌ [$i] Error parsing: $e');
            developer.log('   Item: ${response[i]}');
          }
        }

        schedules.value = parsedSchedules;

        developer.log('───────────────────────────────────────');
        developer.log('📊 Parsing Summary:');
        developer.log('   ✅ Success: $successCount');
        developer.log('   ❌ Failed: $errorCount');
        developer.log('   📋 Total: ${schedules.length}');
        developer.log('───────────────────────────────────────');

        // Sort by time
        if (schedules.isNotEmpty) {
          schedules.sort((a, b) {
            try {
              return a.startTime.compareTo(b.startTime);
            } catch (e) {
              return 0;
            }
          });
          developer.log('✅ Schedules sorted by time');
        }
      } else {
        developer.log('❌ Response is not a List: ${response.runtimeType}');
        schedules.value = [];
      }

      if (schedules.isEmpty) {
        developer.log('⚠️  Final result: No schedules to display');
      } else {
        developer.log('✅ Final result: ${schedules.length} schedules loaded');
      }
    } catch (e, stackTrace) {
      developer.log('═══════════════════════════════════════');
      developer.log('❌ ERROR LOADING SCHEDULES');
      developer.log('═══════════════════════════════════════');
      developer.log('Error: $e');
      developer.log('Stack trace:');
      developer.log(stackTrace.toString());
      developer.log('═══════════════════════════════════════');

      error.value = e.toString();
      schedules.clear();

      Get.snackbar(
        'Error',
        'Gagal memuat jadwal: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      developer.log('🏁 Loading finished');
      developer.log('   isLoading: ${isLoading.value}');
      developer.log('   schedules.length: ${schedules.length}');
      developer.log('   error: ${error.value}');
      developer.log('═══════════════════════════════════════\n');
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

  String _getDayName(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return days[date.weekday % 7];
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
