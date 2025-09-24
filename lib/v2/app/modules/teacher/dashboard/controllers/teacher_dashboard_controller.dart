import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../auth/controllers/auth_controller.dart';

class TeacherDashboardController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final dashboardData = Rxn<TeacherDashboardModel>();
  final currentTime = DateTime.now().obs;

  // Prayer times
  final prayerTimes = <PrayerTimeModel>[].obs;
  final currentPrayerIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDashboard();
    _startTimeUpdater();
  }

  Future<void> _initializeDashboard() async {
    await loadDashboardData();
    _loadPrayerTimes();
  }

  /// Load dashboard data from API
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      final response = await _apiService.getTeacherDashboard();
      dashboardData.value = TeacherDashboardModel.fromJson(response);

      // Update prayer times if available
      if (response['prayer_times'] != null) {
        prayerTimes.value =
            (response['prayer_times'] as List)
                .map((e) => PrayerTimeModel.fromJson(e))
                .toList();
      }
    } catch (e) {
      _showErrorSnackbar('خطأ في تحميل البيانات', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    try {
      isRefreshing.value = true;
      await loadDashboardData();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Load prayer times (fallback to default if API fails)
  void _loadPrayerTimes() {
    if (prayerTimes.isEmpty) {
      prayerTimes.value = PrayerTimeModel.getDefaultTimes();
    }
    _updateCurrentPrayer();
  }

  /// Update current prayer based on time
  void _updateCurrentPrayer() {
    final now = DateTime.now();
    final currentTimeMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < prayerTimes.length; i++) {
      final prayerTime = prayerTimes[i];
      final prayerMinutes = _parseTimeToMinutes(prayerTime.time);

      if (currentTimeMinutes < prayerMinutes) {
        currentPrayerIndex.value = i;
        return;
      }
    }

    // If past all prayers, next is Subuh tomorrow
    currentPrayerIndex.value = 0;
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Start time updater
  void _startTimeUpdater() {
    // Update every minute
    Stream.periodic(Duration(minutes: 1)).listen((_) {
      currentTime.value = DateTime.now();
      _updateCurrentPrayer();
    });
  }

  /// Get Islamic greeting based on time
  String get islamicGreeting {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) {
      return 'صَبَاح الْخَيْر';
    } else if (hour >= 11 && hour < 15) {
      return 'ظُهْر مُبَارَك';
    } else if (hour >= 15 && hour < 18) {
      return 'عَصْر سَعِيد';
    } else if (hour >= 18 && hour < 20) {
      return 'مَسَاء الْخَيْر';
    } else {
      return 'لَيْلَة مُبَارَكَة';
    }
  }

  String get indonesianGreeting {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else if (hour >= 18 && hour < 20) {
      return 'Selamat Petang';
    } else {
      return 'Selamat Malam';
    }
  }

  /// Get current user
  UserModel? get currentUser => _authController.user.value;

  /// Navigate to attendance for specific schedule
  void navigateToAttendance(TodayScheduleModel schedule) {
    Get.toNamed('/teacher/attendance', arguments: {'schedule': schedule});
  }

  /// Navigate to announcements
  void navigateToAnnouncements() {
    Get.toNamed('/teacher/announcements');
  }

  /// Navigate to students
  void navigateToStudents() {
    Get.toNamed('/teacher/students');
  }

  /// Navigate to schedule
  void navigateToSchedule() {
    Get.toNamed('/teacher/schedule');
  }

  /// Navigate to profile
  void navigateToProfile() {
    Get.toNamed('/teacher/profile');
  }

  /// Logout
  void logout() {
    Get.dialog(
      AlertDialog(
        title: Text('تسجيل الخروج'),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج؟\nApakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _authController.logout();
            },
            child: Text('خروج'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.showSnackbar(
      GetSnackBar(
        title: title,
        message: message,
        backgroundColor: Colors.red,
        // colorText: Colors.white,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
        borderRadius: 8,
        icon: Icon(Icons.error, color: Colors.white),
        snackPosition: SnackPosition.TOP,
      ),
    );
  }
}
