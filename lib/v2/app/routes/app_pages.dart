// lib/v2/app/routes/app_pages.dart - UPDATED VERSION dengan Student Profile
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/common/main_navigation_wrapper.dart';
import '../../core/widgets/common/parent_navigation_wrapper.dart';
import '../../core/widgets/common/student_navigation_wrapper.dart';
import '../../core/widgets/common/security_navigation_wrapper.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/onboarding/views/splash_view.dart';

// Teacher imports
import '../modules/security/scan/bindings/scan_binding.dart';
import '../modules/security/scan/views/scan_view.dart';
import '../modules/security/visit-logs/bindings/visit_log_binding.dart';
import '../modules/security/visit-logs/views/visit_logs_view.dart';
import '../modules/security/visitor/bindings/visitor_binding.dart';
import '../modules/security/visitor/views/visitor_view.dart';
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
import '../modules/student/announcements/bindings/student_announcements_binding.dart';
import '../modules/student/announcements/views/student_announcements_view.dart';

// ✅ TAMBAHKAN IMPORT Student Profile
import '../modules/student/profile/bindings/profile_binding.dart';
import '../modules/student/profile/views/profile_view.dart';

// Visit Schedule imports
import '../modules/student/visit_schedule/bindings/visit_schedule_binding.dart';
import '../modules/student/visit_schedule/views/visit_schedule_view.dart';
// import '../modules/student/visit_schedule/views/visit_qr_view.dart';

// Security imports
import '../modules/security/dashboard/bindings/security_dashboard_binding.dart';
import '../modules/security/dashboard/views/security_dashboard_view.dart';
import '../modules/security/profile/bindings/security_profile_binding.dart';
import '../modules/security/profile/views/security_profile_view.dart';

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
      participatesInRootNavigator: true,
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
      ],
    ),

    // ===== FULL SCREEN ROUTES (Outside Wrapper) =====
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.STUDENT_ATTENDANCE_HISTORY,
      page: () => const StudentHistoryView(),
      binding: StudentHistoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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
      name: Routes.STUDENT,
      page: () => const StudentNavigationWrapper(),
      participatesInRootNavigator: true,
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
          page: () => const StudentAnnouncementsView(),
          binding: StudentAnnouncementsBinding(),
        ),
        GetPage(
          name: Routes.STUDENT_VISIT_SCHEDULE,
          page: () => const VisitScheduleView(),
          binding: VisitScheduleBinding(),
        ),
        // ✅ TAMBAHKAN ROUTE Student Profile
        GetPage(
          name: Routes.STUDENT_PROFILE,
          page: () => const StudentProfileView(),
          binding: StudentProfileBinding(),
        ),
      ],
    ),

    // ===== SECURITY NAVIGATION WRAPPER =====
    GetPage(
      name: Routes.SECURITY,
      page: () => const SecurityNavigationWrapper(),
      participatesInRootNavigator: true,
      children: [
        GetPage(
          name: Routes.SECURITY_DASHBOARD,
          page: () => const SecurityDashboardView(),
          binding: SecurityDashboardBinding(),
        ),
        GetPage(
          name: Routes.SECURITY_SCAN,
          page: () => const SecurityScanView(),
          binding: SecurityScanBinding(),
        ),
        GetPage(
          name: Routes.SECURITY_TODAY_VISITORS,
          page: () => const TodayVisitorsView(),
          binding: TodayVisitorsBinding(),
        ),
        GetPage(
          name: Routes.SECURITY_PROFILE,
          page: () => const SecurityProfileView(),
          binding: SecurityProfileBinding(),
        ),
      ],
    ),

    // ===== SECURITY FULL SCREEN ROUTES =====
    GetPage(
      name: Routes.SECURITY_VISIT_LOGS,
      page: () => const VisitLogsView(),
      binding: VisitLogsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.SECURITY_CHECK_IN,
      page: () => _buildPlaceholderPage(
            'Check In Manual',
            'Form check-in manual pengunjung',
          ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.SECURITY_CHECK_OUT,
      page: () => _buildPlaceholderPage(
            'Check Out Manual',
            'Form check-out manual pengunjung',
          ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.SECURITY_HISTORY,
      page: () => _buildPlaceholderPage(
            'Riwayat Kunjungan',
            'Riwayat kunjungan yang sudah selesai',
          ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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
