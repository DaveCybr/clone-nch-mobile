import 'package:get/get.dart';
// import '../modules/auth/bindings/auth_binding.dart';
// import '../modules/auth/views/splash_view.dart';
// import '../modules/auth/views/login_view.dart';
// import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
// import '../modules/teacher/dashboard/views/teacher_dashboard_view.dart';
// ... import other modules

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/onboarding/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL =
      Routes.TEACHER_DASHBOARD; // Will change based on auth status

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

    // // Teacher routes
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
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
    GetPage(
      name: Routes.TEACHER_STUDENTS,
      page: () => const StudentDataView(),
      binding: StudentBinding(),
    ),
    GetPage(
      name: Routes.TEACHER_ANNOUNCEMENTS,
      page: () => const AnnouncementView(),
      binding: AnnouncementBinding(),
    ),
    GetPage(
      name: Routes.TEACHER_PROFILE,
      page: () => const TeacherProfileView(),
      binding: TeacherProfileBinding(),
    ),
    GetPage(
      name: Routes.STUDENT_ATTENDANCE_HISTORY,
      page: () => const StudentAttendanceHistoryView(),
      binding: AttendanceBinding(),
    ),
  ];
}
