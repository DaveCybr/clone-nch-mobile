
import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/onboarding/views/splash_view.dart';
import '../modules/teacher/dashboard/bindings/teacher_dashboard_binding.dart';
import '../modules/teacher/dashboard/views/teacher_dashboard_view.dart';
// ← ADD THESE IMPORTS
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/student/bindings/student_data_binding.dart';
import '../modules/teacher/student/views/student_data_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.TEACHER_DASHBOARD;

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
    // ← ADD THESE NEW PAGES
    GetPage(
      name: Routes.TEACHER_ATTENDANCE,
      page: () => const AttendanceView(),
      binding: AttendanceBinding(),
    ),
    GetPage(
      name: Routes.TEACHER_STUDENTS,
      page: () => const StudentDataView(),
      binding: StudentDataBinding(),
    ),
    GetPage(
      name: Routes.STUDENT_ATTENDANCE_HISTORY,
      page: () => const StudentHistoryView(),
      binding: StudentHistoryBinding(),
    ),
  ];
}