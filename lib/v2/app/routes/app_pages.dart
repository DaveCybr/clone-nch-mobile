// lib/v2/app/routes/app_pages.dart - UPDATED VERSION

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/common/main_navigation_wrapper.dart';
import '../../core/widgets/common/parent_navigation_wrapper.dart';
import '../../core/widgets/common/student_navigation_wrapper.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/onboarding/views/splash_view.dart';

// Teacher imports
import '../modules/teacher/announcements/bindings/announcement_binding.dart';
import '../modules/teacher/announcements/views/announcement_view.dart';
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
import '../modules/teacher/dashboard/views/teacher_dashboard_view.dart';
import '../modules/teacher/profile/bindings/profile_binding.dart';
import '../modules/teacher/profile/views/profile_view.dart';
import '../modules/teacher/schedule/bindings/schedule_binding.dart';
import '../modules/teacher/schedule/views/schedule_view.dart';
import '../modules/teacher/student/bindings/student_data_binding.dart';
import '../modules/teacher/student/views/student_data_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';

// Student imports
import '../modules/student/dashboard/bindings/student_dashboard_binding.dart';
import '../modules/student/dashboard/views/student_dashboard_view.dart';
import '../modules/student/schedule/bindings/student_schedule_binding.dart';
import '../modules/student/schedule/views/student_schedule_view.dart';
import '../modules/student/attendance/bindings/student_attendance_binding.dart';
import '../modules/student/attendance/views/student_attendance_view.dart';

import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // ===== COMMON ROUTES =====
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.LOGIN, page: () => const LoginView()),

    // ===== TEACHER NAVIGATION WRAPPER =====
    GetPage(
      name: '/main',
      page: () => const MainNavigationWrapper(),
      children: [
        GetPage(
          name: Routes.TEACHER_DASHBOARD,
          page: () => const TeacherDashboardView(),
          binding: TeacherDashboardBinding(),
        ),
        GetPage(
          name: Routes.TEACHER_SCHEDULE,
          page: () => const ScheduleView(),
          binding: ScheduleBinding(),
        ),
        GetPage(
          name: Routes.TEACHER_STUDENTS,
          page: () => const StudentDataView(),
          binding: StudentDataBinding(),
        ),
        GetPage(
          name: Routes.TEACHER_PROFILE,
          page: () => const ProfileView(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: Routes.TEACHER_ANNOUNCEMENTS,
          page: () => const AnnouncementsView(),
          binding: AnnouncementsBinding(),
        ),
        GetPage(
          name: Routes.STUDENT_ATTENDANCE_HISTORY,
          page: () => const StudentHistoryView(),
          binding: StudentHistoryBinding(),
        ),
      ],
    ),

    // ===== PARENT NAVIGATION WRAPPER =====
    GetPage(
      name: '/parent',
      page: () => const ParentNavigationWrapper(),
      children: [
        GetPage(
          name: Routes.PARENT_DASHBOARD,
          page:
              () => _buildPlaceholderPage(
                'Parent Dashboard',
                'Dashboard wali santri',
              ),
        ),
        GetPage(
          name: Routes.PARENT_CHILD_PROGRESS,
          page:
              () => _buildPlaceholderPage(
                'Progress Anak',
                'Lihat perkembangan anak',
              ),
        ),
        GetPage(
          name: Routes.PARENT_ANNOUNCEMENTS,
          page:
              () => _buildPlaceholderPage(
                'Pengumuman',
                'Pengumuman untuk wali santri',
              ),
        ),
        GetPage(
          name: Routes.PARENT_PROFILE,
          page: () => _buildPlaceholderPage('Profil', 'Profil wali santri'),
        ),
      ],
    ),

    // ===== STUDENT NAVIGATION WRAPPER =====
    GetPage(
      name: '/student',
      page: () => const StudentNavigationWrapper(),
      children: [
        GetPage(
          name: Routes.STUDENT_DASHBOARD,
          page: () => const StudentDashboardView(),
          binding: StudentDashboardBinding(),
        ),
        GetPage(
          name: Routes.STUDENT_SCHEDULE,
          page: () => const StudentScheduleView(),
          binding: StudentScheduleBinding(),
        ),
        GetPage(
          name: Routes.STUDENT_ATTENDANCE,
          page: () => const StudentAttendanceView(),
          binding: StudentAttendanceBinding(),
        ),
        GetPage(
          name: Routes.STUDENT_ANNOUNCEMENTS,
          page:
              () => _buildPlaceholderPage(
                'Pengumuman',
                'Pengumuman untuk santri',
              ),
        ),
        GetPage(
          name: Routes.STUDENT_PROFILE,
          page: () => _buildPlaceholderPage('Profil', 'Profil santri'),
        ),
      ],
    ),

    // ===== FULL SCREEN ROUTES (Outside Wrapper) =====
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
  ];

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
