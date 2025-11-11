// lib/v2/app/modules/student/dashboard/controllers/student_dashboard_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/models/student_dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/firebase_service.dart'; // ✅ TAMBAHKAN
import '../../../auth/controllers/auth_controller.dart';
import 'dart:developer' as developer; // ✅ TAMBAHKAN

class StudentDashboardController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find<AuthController>();

  // Dashboard data
  final isLoading = true.obs;
  final error = Rx<String?>(null);
  final dashboardData = Rx<StudentDashboardModel?>(null);

  // Computed observables from dashboard
  final schedulesToday = <StudentScheduleModel>[].obs;
  final attendanceToday = <StudentAttendanceItemModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();

    // ✅ TAMBAHKAN: Subscribe to notification topics
    _subscribeToNotificationTopics();
  }

  /// ✅ NEW: Subscribe to FCM topics for student notifications
  Future<void> _subscribeToNotificationTopics() async {
    try {
      developer.log('🔔 Student: Subscribing to notification topics...');

      final firebaseService = Get.find<FirebaseService>();

      // Subscribe ke topics yang relevan untuk student
      await firebaseService.subscribeToTopic('Berita');
      await firebaseService.subscribeToTopic('Siswa');
      await firebaseService.subscribeToTopic('Pengumuman-Siswa');

      developer.log('✅ Student successfully subscribed to topics:');
      developer.log('   - Berita');
      developer.log('   - Siswa');
      developer.log('   - Pengumuman-Siswa');
    } catch (e) {
      developer.log('❌ Error subscribing to notification topics: $e');
    }
  }

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

  /// Load dashboard data
  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await _apiService.getStudentDashboard();

      if (response['data'] != null) {
        dashboardData.value = StudentDashboardModel.fromJson(response['data']);
        schedulesToday.value = dashboardData.value!.schedulesToday;
        attendanceToday.value = dashboardData.value!.attendanceToday;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat dashboard: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard
  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  // ===== COMPUTED GETTERS =====

  int get totalSchedulesToday => schedulesToday.length;

  int get attendanceHadir =>
      attendanceToday.where((a) => a.status == 'HADIR').length;

  int get attendanceSakit =>
      attendanceToday.where((a) => a.status == 'SAKIT').length;

  int get attendanceIzin =>
      attendanceToday.where((a) => a.status == 'IZIN').length;

  int get attendanceAlpha =>
      attendanceToday.where((a) => a.status == 'ALPHA').length;

  // User & class info
  String get userName => dashboardData.value?.user.name ?? 'Santri';
  String get userEmail => dashboardData.value?.user.email ?? '';
  String get className => dashboardData.value?.classInfo.name ?? '-';
  String get classLevel => dashboardData.value?.classInfo.level ?? '';

  // Attendance percentage
  double get attendancePercentage {
    if (attendanceToday.isEmpty) return 0.0;
    return (attendanceHadir / attendanceToday.length) * 100;
  }
}
