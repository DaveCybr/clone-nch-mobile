import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/modules/auth/views/login_view.dart';
import 'package:nch_mobile/v2/app/modules/onboarding/views/splash_view.dart';
import '../../core/widgets/common/main_navigation_wrapper.dart';

// Teacher modules
import '../modules/teacher/announcements/bindings/announcement_binding.dart';
import '../modules/teacher/announcements/views/announcement_view.dart';
import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
import '../modules/teacher/dashboard/views/teacher_dashboard_view.dart';
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/profile/bindings/profile_binding.dart';
import '../modules/teacher/profile/views/profile_view.dart';
import '../modules/teacher/student/bindings/student_data_binding.dart';
import '../modules/teacher/student/views/student_data_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';
import '../modules/teacher/schedule/bindings/schedule_binding.dart';
import '../modules/teacher/schedule/views/schedule_view.dart';

import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // Splash & Login
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.LOGIN, page: () => const LoginView()),

    // MAIN WRAPPER with nested routes
    GetPage(
      name: Routes.MAIN,
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
          // transition: Transition.rightToLeft,
          transitionDuration: Duration(milliseconds: 300),
        ),

        GetPage(
          name: Routes.TEACHER_STUDENTS,
          page: () => const StudentDataView(),
          binding: StudentDataBinding(),
          transition: Transition.fadeIn,
          transitionDuration: Duration(milliseconds: 300),
        ),
        GetPage(
          name: Routes.STUDENT_ATTENDANCE_HISTORY,
          page: () => const StudentHistoryView(),
          binding: StudentHistoryBinding(),
          transition: Transition.fadeIn,
          transitionDuration: Duration(milliseconds: 300),
        ),
        GetPage(
          name: Routes.TEACHER_ANNOUNCEMENTS,
          page: () => const AnnouncementsView(),
          binding: AnnouncementsBinding(),
          transition: Transition.fadeIn,
          transitionDuration: Duration(milliseconds: 300),
        ),
        GetPage(
          name: Routes.TEACHER_PROFILE,
          page: () => const ProfileView(),
          binding: ProfileBinding(),
          transition: Transition.fadeIn,
          transitionDuration: Duration(milliseconds: 300),
        ),
      ],
    ),
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
      // transition: Transition.rightToLeft,
      transitionDuration: Duration(milliseconds: 300),
    ),
    // Teacher routes
    // GetPage(
    //   name: Routes.TEACHER_DASHBOARD,
    //   page: () => const TeacherDashboardView(),
    //   binding: TeacherDashboardBinding(),
    // ),
    // GetPage(
    //   name: Routes.TEACHER_SCHEDULE,
    //   page: () => const ScheduleView(),
    //   binding: ScheduleBinding(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: Duration(milliseconds: 300),
    // ),

    // Parent routes placeholder
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
