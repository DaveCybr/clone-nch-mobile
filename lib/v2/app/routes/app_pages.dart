import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/onboarding/views/splash_view.dart';
import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
import '../modules/teacher/dashboard/views/teacher_dashboard_view.dart';
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/student/bindings/student_data_binding.dart';
import '../modules/teacher/student/views/student_data_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // Auth routes
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),

    // Teacher routes
    GetPage(
      name: Routes.TEACHER_DASHBOARD,
      page: () => const TeacherDashboardView(),
      binding: TeacherDashboardBinding(),
    ),

    // Attendance route - FIXED
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
      // Add transition for better UX
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Students route
    GetPage(
      name: Routes.TEACHER_STUDENTS,
      page: () => const StudentDataView(),
      binding: StudentDataBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Student history route
    GetPage(
      name: Routes.STUDENT_ATTENDANCE_HISTORY,
      page: () => const StudentHistoryView(),
      binding: StudentHistoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Placeholder routes for missing pages
    GetPage(
      name: Routes.TEACHER_SCHEDULE,
      page:
          () => _buildPlaceholderPage(
            'Jadwal',
            'Halaman jadwal sedang dalam pengembangan',
          ),
      binding: TeacherDashboardBinding(),
    ),

    GetPage(
      name: Routes.TEACHER_ANNOUNCEMENTS,
      page:
          () => _buildPlaceholderPage(
            'Pengumuman',
            'Halaman pengumuman sedang dalam pengembangan',
          ),
      binding: TeacherDashboardBinding(),
    ),

    GetPage(
      name: Routes.TEACHER_PROFILE,
      page:
          () => _buildPlaceholderPage(
            'Profil',
            'Halaman profil sedang dalam pengembangan',
          ),
      binding: TeacherDashboardBinding(),
    ),

    // Parent routes placeholder (for future development)
    GetPage(
      name: Routes.PARENT_DASHBOARD,
      page:
          () => _buildPlaceholderPage(
            'Parent Dashboard',
            'Halaman wali santri sedang dalam pengembangan',
          ),
    ),
  ];

  /// Build placeholder page for unimplemented features
  static Widget _buildPlaceholderPage(String title, String message) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
