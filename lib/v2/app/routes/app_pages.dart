// lib/v2/app/routes/app_pages.dart - FIXED VERSION WITH WRAPPERS

import 'package:get/get.dart';
import 'package:nch_mobile/v2/core/widgets/common/main_navigation_wrapper.dart';
import 'package:nch_mobile/v2/core/widgets/common/security_navigation_wrapper.dart';
import 'package:nch_mobile/v2/core/widgets/common/student_navigation_wrapper.dart';
import '../routes/app_routes.dart';

// Auth
import '../modules/auth/views/auth_wrapper.dart';
import '../modules/auth/views/login_view.dart';

// ✅ Navigation Wrappers

// Teacher
import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
import '../modules/teacher/schedule/bindings/schedule_binding.dart';
import '../modules/teacher/student/bindings/student_data_binding.dart';
import '../modules/teacher/profile/bindings/profile_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/announcements/views/announcement_view.dart';
import '../modules/teacher/announcements/bindings/announcement_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';

// Student
import '../modules/student/dashboard/bindings/student_dashboard_binding.dart';
import '../modules/student/schedule/bindings/student_schedule_binding.dart';
import '../modules/student/attendance/bindings/student_attendance_binding.dart';
import '../modules/student/announcements/bindings/student_announcements_binding.dart';
import '../modules/student/visit_schedule/bindings/visit_schedule_binding.dart';
import '../modules/student/profile/bindings/profile_binding.dart'
    as student_profile_binding;

// Security
import '../modules/security/dashboard/bindings/security_dashboard_binding.dart';
import '../modules/security/scan/bindings/scan_binding.dart';
import '../modules/security/visitor/bindings/visitor_binding.dart';
import '../modules/security/profile/bindings/security_profile_binding.dart';
import '../modules/security/visit-logs/views/visit_logs_view.dart';
import '../modules/security/visit-logs/bindings/visit_log_binding.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // ===== ROOT ROUTES =====
    GetPage(
      name: Routes.SPLASH,
      page: () => const AuthWrapper(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),

    // ===== TEACHER WRAPPER (Main Entry Point) =====
    GetPage(
      name: Routes.TEACHER,
      page: () => const TeacherNavigationWrapper(),
      bindings: [
        TeacherDashboardBinding(),
        ScheduleBinding(),
        StudentDataBinding(),
        ProfileBinding(),
      ],
      transition: Transition.fadeIn,
    ),

    // ===== TEACHER TAB ROUTES (Inside Wrapper - No Transition) =====
    GetPage(
      name: Routes.TEACHER_DASHBOARD,
      page: () => const TeacherNavigationWrapper(),
      bindings: [
        TeacherDashboardBinding(),
        ScheduleBinding(),
        StudentDataBinding(),
        ProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.TEACHER_SCHEDULE,
      page: () => const TeacherNavigationWrapper(),
      bindings: [
        TeacherDashboardBinding(),
        ScheduleBinding(),
        StudentDataBinding(),
        ProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.TEACHER_STUDENTS,
      page: () => const TeacherNavigationWrapper(),
      bindings: [
        TeacherDashboardBinding(),
        ScheduleBinding(),
        StudentDataBinding(),
        ProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.TEACHER_PROFILE,
      page: () => const TeacherNavigationWrapper(),
      bindings: [
        TeacherDashboardBinding(),
        ScheduleBinding(),
        StudentDataBinding(),
        ProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),

    // ===== TEACHER FULLSCREEN ROUTES (Outside Wrapper) =====
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.TEACHER_ANNOUNCEMENTS,
      page: () => const AnnouncementsView(),
      binding: AnnouncementsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.STUDENT_HISTORY,
      page: () => const StudentHistoryView(),
      binding: StudentHistoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ===== STUDENT WRAPPER (Main Entry Point) =====
    GetPage(
      name: Routes.STUDENT,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.fadeIn,
    ),

    // ===== STUDENT TAB ROUTES (Inside Wrapper) =====
    GetPage(
      name: Routes.STUDENT_DASHBOARD,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.STUDENT_SCHEDULE,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.STUDENT_ATTENDANCE,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.STUDENT_ANNOUNCEMENTS,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.STUDENT_VISIT,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.STUDENT_PROFILE,
      page: () => const StudentNavigationWrapper(),
      bindings: [
        StudentDashboardBinding(),
        StudentScheduleBinding(),
        StudentAttendanceBinding(),
        StudentAnnouncementsBinding(),
        VisitScheduleBinding(),
        student_profile_binding.StudentProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),

    // ===== SECURITY WRAPPER (Main Entry Point) =====
    GetPage(
      name: Routes.SECURITY,
      page: () => const SecurityNavigationWrapper(),
      bindings: [
        SecurityDashboardBinding(),
        SecurityScanBinding(),
        TodayVisitorsBinding(),
        SecurityProfileBinding(),
      ],
      transition: Transition.fadeIn,
    ),

    // ===== SECURITY TAB ROUTES (Inside Wrapper) =====
    GetPage(
      name: Routes.SECURITY_DASHBOARD,
      page: () => const SecurityNavigationWrapper(),
      bindings: [
        SecurityDashboardBinding(),
        SecurityScanBinding(),
        TodayVisitorsBinding(),
        SecurityProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.SECURITY_SCAN,
      page: () => const SecurityNavigationWrapper(),
      bindings: [
        SecurityDashboardBinding(),
        SecurityScanBinding(),
        TodayVisitorsBinding(),
        SecurityProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.SECURITY_VISITORS,
      page: () => const SecurityNavigationWrapper(),
      bindings: [
        SecurityDashboardBinding(),
        SecurityScanBinding(),
        TodayVisitorsBinding(),
        SecurityProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),
    GetPage(
      name: Routes.SECURITY_PROFILE,
      page: () => const SecurityNavigationWrapper(),
      bindings: [
        SecurityDashboardBinding(),
        SecurityScanBinding(),
        TodayVisitorsBinding(),
        SecurityProfileBinding(),
      ],
      transition: Transition.noTransition,
    ),

    // ===== SECURITY FULLSCREEN ROUTES =====
    GetPage(
      name: Routes.SECURITY_LOGS,
      page: () => const VisitLogsView(),
      binding: VisitLogsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
