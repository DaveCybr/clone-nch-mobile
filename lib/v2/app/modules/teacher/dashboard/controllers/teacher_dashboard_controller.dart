// Fixed TeacherDashboardController.dart

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/navigations_services.dart';
import '../../../../data/services/storage_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../announcements/bindings/announcement_binding.dart';
import '../../announcements/views/announcement_detail_view.dart';
import '../../announcements/views/announcement_view.dart';
import '../../attendance/bindings/attendance_binding.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/views/attendance_view.dart';

class TeacherDashboardController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthController _authController = Get.find<AuthController>();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final dashboardData = Rxn<TeacherDashboardModel>();
  final currentTime = DateTime.now().obs;
  final selectedNavIndex = 0.obs;
  final unreadAnnouncementsCount = 0.obs; // ✅ Observable untuk unread count

  // Prayer times
  final prayerTimes = <PrayerTimeModel>[].obs;
  final currentPrayerIndex = 0.obs;

  // Reactive greeting variables
  final islamicGreeting = 'السلام عليكم'.obs;
  final indonesianGreeting = 'Selamat datang'.obs;

  @override
  void onInit() {
    super.onInit();
    _updateGreetings();
    _initializeDashboard();
    _startTimeUpdater();
  }

  Future<void> _initializeDashboard() async {
    await loadDashboardData();
    _loadPrayerTimes();
    _updateUnreadCount(); // ✅ Update unread count on init
  }

  // ✅ NEW: Method untuk update unread count
  void _updateUnreadCount() {
    final announcements = dashboardData.value?.announcements ?? [];

    // Count berdasarkan isRead property (yang sudah sync dengan storage)
    unreadAnnouncementsCount.value =
        announcements.where((a) => !a.isRead).length;

    developer.log(
      '📊 Dashboard unread count updated: ${unreadAnnouncementsCount.value}',
    );
  }

  // ✅ NEW: Method untuk mark announcement as read
  Future<void> markAnnouncementAsRead(String announcementId) async {
    try {
      developer.log(
        '📖 Dashboard: Marking announcement as read: $announcementId',
      );

      // Update local data
      final announcements = dashboardData.value?.announcements ?? [];
      bool hasChanges = false;

      final updatedAnnouncements =
          announcements.map((announcement) {
            if (announcement.id == announcementId && !announcement.isRead) {
              announcement.isRead = true;
              hasChanges = true;
              return announcement;
            }
            return announcement;
          }).toList();

      if (hasChanges) {
        // Update dashboard data
        if (dashboardData.value != null) {
          dashboardData.value = dashboardData.value!.copyWith(
            announcements: updatedAnnouncements,
          );
        }

        // Save to storage
        await _storageService.markAnnouncementAsRead(announcementId);

        // Update unread count
        _updateUnreadCount();

        developer.log(
          '✅ Dashboard: Marked announcement $announcementId as read',
        );
      }
    } catch (e) {
      developer.log('❌ Dashboard: Error marking announcement as read: $e');
    }
  }

  // ✅ NEW: Method untuk view announcement detail
  void viewAnnouncementDetail(AnnouncementModel announcement) {
    developer.log(
      '👀 Dashboard: Opening announcement detail: ${announcement.id}',
    );

    // Mark as read if not already (sync dengan storage)
    if (!announcement.isRead) {
      markAnnouncementAsRead(announcement.id);
    }

    // Navigate to detail view
    Get.to(
      () => AnnouncementDetailView(announcement: announcement),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Load dashboard data from API with better error handling
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      final response = await _apiService.getTeacherDashboard();

      developer.log('📦 Dashboard API Response:');
      developer.log('Stats: ${response['stats']}');
      developer.log(
        'Announcements count: ${(response['announcements'] as List?)?.length ?? 0}',
      );

      dashboardData.value = TeacherDashboardModel.fromJson(response);

      // Update prayer times if available
      if (response['prayer_times'] != null) {
        prayerTimes.value =
            (response['prayer_times'] as List)
                .map((e) => PrayerTimeModel.fromJson(e))
                .toList();
      }

      // ✅ Update unread count after loading data
      _updateUnreadCount();

      developer.log('✅ Dashboard loaded successfully');
      developer.log(
        '📊 Total announcements: ${dashboardData.value?.announcements.length ?? 0}',
      );
      developer.log(
        '📊 Unread announcements: ${unreadAnnouncementsCount.value}',
      );
    } catch (e, stackTrace) {
      developer.log('❌ Error loading dashboard: $e');
      developer.log('Stack trace: $stackTrace');

      // Provide fallback data instead of just showing error
      _loadFallbackData();
      _showErrorSnackbar(
        'خطأ في تحميل البيانات',
        'Menggunakan data offline. Periksa koneksi internet Anda.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Provide fallback data when API fails
  void _loadFallbackData() {
    dashboardData.value = TeacherDashboardModel(
      stats: const DashboardStats(
        totalStudents: 0,
        totalClasses: 0,
        todayTasks: 0,
        totalAnnouncements: 0,
      ),
      todaySchedules: [],
      prayerTimes: PrayerTimeModel.getDefaultTimes(),
      announcements: [],
      teacher: _authController.user.value!,
    );
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    try {
      isRefreshing.value = true;
      await loadDashboardData();
      // ✅ _updateUnreadCount() already called in loadDashboardData()
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
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      currentTime.value = DateTime.now();
      _updateCurrentPrayer();
      _updateGreetings();
    });
  }

  /// Update greeting secara reactive
  void _updateGreetings() {
    final hour = DateTime.now().hour;

    // Update Islamic greeting
    if (hour >= 4 && hour < 11) {
      islamicGreeting.value = 'صَبَاح الْخَيْر';
    } else if (hour >= 11 && hour < 15) {
      islamicGreeting.value = 'ظُهْر مُبَارَك';
    } else if (hour >= 15 && hour < 18) {
      islamicGreeting.value = 'عَصْر سَعِيد';
    } else if (hour >= 18 && hour < 20) {
      islamicGreeting.value = 'مَسَاء الْخَيْر';
    } else {
      islamicGreeting.value = 'لَيْلَة مُبَارَكَة';
    }

    // Update Indonesian greeting
    if (hour >= 4 && hour < 11) {
      indonesianGreeting.value = 'Selamat Pagi';
    } else if (hour >= 11 && hour < 15) {
      indonesianGreeting.value = 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      indonesianGreeting.value = 'Selamat Sore';
    } else if (hour >= 18 && hour < 20) {
      indonesianGreeting.value = 'Selamat Petang';
    } else {
      indonesianGreeting.value = 'Selamat Malam';
    }
  }

  /// Get current user
  UserModel? get currentUser => _authController.user.value;

  void navigateToAttendance(TodayScheduleModel schedule) {
    try {
      // ✅ ULTIMATE SOLUTION: Clean up old controller + Manual injection
      final arguments = {
        'schedule_id': schedule.id,
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

  void navigateToAnnouncements() async {
    try {
      // Initialize binding sebelum navigate
      AnnouncementsBinding().dependencies();

      await Get.to(
        () => const AnnouncementsView(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );

      // Refresh dashboard when returning from announcements
      await refreshDashboard();
    } catch (e) {
      developer.log('❌ Error navigating to announcements: $e');
      _showErrorSnackbar('Info', 'Halaman pengumuman belum tersedia');
    }
  }

  /// Navigate to students
  void navigateToStudents() {
    try {
      NavigationService.to.toBottomNavTab(Routes.TEACHER_STUDENTS);
    } catch (e) {
      _showErrorSnackbar('Error', 'Tidak dapat membuka halaman siswa: $e');
    }
  }

  /// Navigate to schedule
  void navigateToSchedule() {
    try {
      NavigationService.to.toBottomNavTab(Routes.TEACHER_SCHEDULE);
    } catch (e) {
      _showErrorSnackbar('Info', 'Halaman jadwal belum tersedia');
    }
  }

  /// Navigate to profile
  void navigateToProfile() {
    try {
      NavigationService.to.toBottomNavTab(Routes.TEACHER_PROFILE);
    } catch (e) {
      _showErrorSnackbar('Info', 'Halaman profil belum tersedia');
    }
  }

  /// Handle bottom navigation
  void onBottomNavTapped(int index) {
    selectedNavIndex.value = index;

    switch (index) {
      case 0:
        // Already on dashboard, refresh data
        refreshDashboard();
        break;
      case 1:
        navigateToSchedule();
        break;
      case 2:
        navigateToAnnouncements();
        break;
      case 3:
        navigateToProfile();
        break;
    }
  }

  /// Show schedule options when tapping schedule card - IMPROVED
  void showScheduleOptions(TodayScheduleModel schedule) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                schedule.subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${schedule.className} • ${schedule.timeRange}',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 20),

              // Options - IMPROVED with error handling
              ListTile(
                leading: const Icon(Icons.how_to_reg, color: Colors.green),
                title: const Text('Absensi Siswa'),
                subtitle: const Text('Input kehadiran siswa'),
                onTap: () {
                  Get.back();
                  // Add delay to ensure bottom sheet is closed
                  Future.delayed(const Duration(milliseconds: 300), () {
                    navigateToAttendance(schedule);
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text('Lihat Data Siswa'),
                subtitle: const Text('Data dan rekap kehadiran'),
                onTap: () {
                  Get.back();
                  Future.delayed(const Duration(milliseconds: 300), () {
                    navigateToStudents();
                  });
                },
              ),

              if (schedule.isDone)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('Edit Absensi'),
                  subtitle: const Text('Perbaiki data kehadiran'),
                  onTap: () {
                    Get.back();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      navigateToAttendance(schedule);
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Logout with confirmation
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟\nApakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _authController.logout();
            },
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
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
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white),
        snackPosition: SnackPosition.TOP,
      ),
    );
  }
}
