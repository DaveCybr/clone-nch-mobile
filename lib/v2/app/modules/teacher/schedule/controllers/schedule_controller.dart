import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class ScheduleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final currentMonth = DateTime.now().obs;
  final schedulesByDate = <String, List<TodayScheduleModel>>{}.obs;
  final datesWithSchedule = <DateTime>[].obs;

  // Islamic months in Arabic
  final List<String> islamicMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  // Days of week
  final List<String> daysOfWeek = [
    'Ahad',
    'Isn',
    'Tsa',
    'Rab',
    'Kha',
    'Jum',
    'Sab',
  ];

  @override
  void onInit() {
    super.onInit();
    developer.log('ScheduleController: onInit called');

    // Check for passed arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['selectedDate'] != null) {
      final passedDate = arguments['selectedDate'] as DateTime;
      selectedDate.value = passedDate;
      currentMonth.value = DateTime(passedDate.year, passedDate.month, 1);
      developer.log(
        'ScheduleController: Selected date from arguments: $passedDate',
      );
    }

    try {
      if (Get.isRegistered<ApiService>()) {
        developer.log('ScheduleController: ApiService is registered');
        loadMonthSchedule();
      } else {
        developer.log(
          'ScheduleController: ApiService not registered, retrying...',
        );
        Future.delayed(Duration(milliseconds: 100), () {
          if (Get.isRegistered<ApiService>()) {
            loadMonthSchedule();
          } else {
            developer.log('ScheduleController: ApiService still not available');
            _showErrorSnackbar('Error', 'Layanan API tidak tersedia');
          }
        });
      }
    } catch (e) {
      developer.log('ScheduleController: Error in onInit: $e');
      _showErrorSnackbar('Error', 'Gagal menginisialisasi controller: $e');
    }
  }

  @override
  void onClose() {
    developer.log('ScheduleController: onClose called');
    super.onClose();
  }

  /// Load schedule for entire month - OPTIMIZED
  Future<void> loadMonthSchedule() async {
    try {
      isLoading.value = true;
      developer.log('Loading month schedule for: ${currentMonth.value}');

      // Get first and last day of current month
      final firstDay = DateTime(
        currentMonth.value.year,
        currentMonth.value.month,
        1,
      );
      final lastDay = DateTime(
        currentMonth.value.year,
        currentMonth.value.month + 1,
        0,
      );

      try {
        // Try to get real data from API first
        final response = await _apiService.getTeacherScheduleList(
          startDate: firstDay,
          endDate: lastDay,
        );

        // Clear previous data
        schedulesByDate.clear();
        datesWithSchedule.clear();

        // Group schedules by date
        for (var scheduleJson in response) {
          final schedule = TodayScheduleModel.fromJson(scheduleJson);

          // Parse schedule date (assuming it's in the response)
          DateTime scheduleDate;
          if (scheduleJson['date'] != null) {
            try {
              scheduleDate = DateTime.parse(scheduleJson['date']);
            } catch (e) {
              // If date parsing fails, skip this schedule
              developer.log('Failed to parse date: ${scheduleJson['date']}');
              continue;
            }
          } else {
            // Skip schedules without dates
            developer.log('Schedule without date found, skipping');
            continue;
          }

          final dateKey = _formatDateKey(scheduleDate);

          if (schedulesByDate[dateKey] == null) {
            schedulesByDate[dateKey] = [];
            datesWithSchedule.add(scheduleDate);
          }

          schedulesByDate[dateKey]!.add(schedule);
        }

        developer.log(
          'Loaded schedules for ${datesWithSchedule.length} days from API',
        );

        // If no data from API, use sample data
        if (datesWithSchedule.isEmpty) {
          developer.log('No API data, loading sample data');
          _loadSampleData();
        }
      } catch (apiError) {
        developer.log('API request failed: $apiError, using sample data');
        _loadSampleData();
      }
    } catch (e) {
      developer.log('Error loading schedule: $e');
      _showErrorSnackbar('Error', 'Gagal memuat jadwal: $e');
      _loadSampleData(); // Fallback to sample data
    } finally {
      isLoading.value = false;
    }
  }

  /// Load specific date schedule - NEW METHOD
  Future<void> loadDateSchedule(DateTime date) async {
    try {
      developer.log('Loading schedule for specific date: $date');

      final dateKey = _formatDateKey(date);

      // If already have data for this date, skip API call
      if (schedulesByDate.containsKey(dateKey)) {
        developer.log('Schedule data already exists for $dateKey');
        return;
      }

      final response = await _apiService.getSchedulesByDate(date);

      final schedules = <TodayScheduleModel>[];
      for (var scheduleJson in response) {
        schedules.add(TodayScheduleModel.fromJson(scheduleJson));
      }

      if (schedules.isNotEmpty) {
        schedulesByDate[dateKey] = schedules;
        if (!datesWithSchedule.any((d) => _formatDateKey(d) == dateKey)) {
          datesWithSchedule.add(date);
        }
      }

      developer.log('Loaded ${schedules.length} schedules for $dateKey');
    } catch (e) {
      developer.log('Error loading date schedule: $e');
      // Don't show error for single date requests
    }
  }

  /// Load sample data for development/testing
  void _loadSampleData() {
    developer.log('Loading sample schedule data');

    schedulesByDate.clear();
    datesWithSchedule.clear();

    // Sample schedules for different dates
    final sampleDates = [
      DateTime(2024, 9, 6), // Friday
      DateTime(2024, 9, 10), // Tuesday
      DateTime(2024, 9, 12), // Thursday
      DateTime(2024, 9, 13), // Friday
      DateTime(2024, 9, 15), // Sunday
      DateTime(2024, 9, 17), // Tuesday
      DateTime(2024, 9, 19), // Thursday
      DateTime(2024, 9, 22), // Sunday
      DateTime(2024, 9, 25), // Wednesday
      DateTime(2024, 9, 27), // Friday
    ];

    for (final date in sampleDates) {
      final dateKey = _formatDateKey(date);
      datesWithSchedule.add(date);

      schedulesByDate[dateKey] = [
        TodayScheduleModel(
          id: '${date.day}-1',
          subjectName:
              date.day == 15
                  ? 'Fiqih (Thaharah)'
                  : date.day == 15
                  ? 'Tafsir Al-Qur\'an (Juz \'Amma)'
                  : date.day == 15
                  ? 'Hadits (Arba\'in an-Nawawiyah)'
                  : 'Fiqih (Thaharah)',
          className: date.day == 15 ? 'Kelas 7A - Ikhwan' : 'Kelas 8B - Akhwat',
          timeSlot:
              date.day == 15
                  ? 'Ba\'da Subuh (05:30-06:30)'
                  : date.hour < 12
                  ? 'Ba\'da Subuh (05:30-06:30)'
                  : 'Ba\'da Dzuhur (12:30-13:30)',
          startTime: date.day == 15 ? '05:30' : '12:30',
          endTime: date.day == 15 ? '06:30' : '13:30',
          day: _getDayName(date.weekday),
          isDone: false,
          totalStudents: 25,
        ),
        if (date.day == 15) ...[
          TodayScheduleModel(
            id: '${date.day}-2',
            subjectName: 'Tafsir Al-Qur\'an (Juz \'Amma)',
            className: 'Kelas 8B - Akhwat',
            timeSlot: 'Ba\'da Dzuhur (12:30-13:30)',
            startTime: '12:30',
            endTime: '13:30',
            day: _getDayName(date.weekday),
            isDone: false,
            totalStudents: 22,
          ),
          TodayScheduleModel(
            id: '${date.day}-3',
            subjectName: 'Hadits (Arba\'in an-Nawawiyah)',
            className: 'Kelas 9C - Ikhwan',
            timeSlot: 'Ba\'da Ashar (15:45-16:45)',
            startTime: '15:45',
            endTime: '16:45',
            day: _getDayName(date.weekday),
            isDone: false,
            totalStudents: 20,
          ),
        ],
      ];
    }

    developer.log('Sample data loaded for ${datesWithSchedule.length} days');
  }

  /// Get schedules for selected date
  List<TodayScheduleModel> get selectedDateSchedules {
    final dateKey = _formatDateKey(selectedDate.value);
    return schedulesByDate[dateKey] ?? [];
  }

  /// Check if date has schedules
  bool hasSchedule(DateTime date) {
    return datesWithSchedule.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  /// Select date
  void selectDate(DateTime date) {
    selectedDate.value = date;
    developer.log('Selected date: ${_formatDateKey(date)}');
  }

  /// Change month
  void changeMonth(int monthOffset) {
    final newMonth = DateTime(
      currentMonth.value.year,
      currentMonth.value.month + monthOffset,
      1,
    );

    currentMonth.value = newMonth;
    developer.log('Changed to month: ${newMonth.month}/${newMonth.year}');

    // Load new month data
    loadMonthSchedule();
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

  /// Format date as key for storage
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const dayNames = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return dayNames[weekday];
  }

  /// Get Islamic month name (approximate)
  String get islamicMonthName {
    // This is approximate - you'd need proper Hijri calendar conversion
    final month = currentMonth.value.month;
    final islamicMonthIndex = (month + 1) % 12; // Rough approximation
    return islamicMonths[islamicMonthIndex];
  }

  /// Get Islamic year (approximate)
  String get islamicYear {
    // Rough approximation: Gregorian year - 579
    final gregorianYear = currentMonth.value.year;
    final islamicYear = gregorianYear - 579;
    return '$islamicYear H';
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
