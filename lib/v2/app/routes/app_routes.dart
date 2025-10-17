// lib/v2/app/routes/app_routes.dart - UPDATED

abstract class Routes {
  // ===== COMMON ROUTES =====
  static const SPLASH = '/';
  static const LOGIN = '/login';

  // ===== TEACHER ROUTES =====
  // Main wrapper untuk teacher: /main
  static const MAIN = '/main';
  static const STUDENT = '/student';
  static const PARENT = '/parent';

  // Child routes (nested under /main)
  static const TEACHER_DASHBOARD = '/dashboard';
  static const TEACHER_SCHEDULE = '/schedule';
  static const TEACHER_ATTENDANCE = '/attendance';
  static const TEACHER_STUDENTS = '/students';
  static const TEACHER_ANNOUNCEMENTS = '/announcements';
  static const TEACHER_PROFILE = '/profile';
  static const STUDENT_ATTENDANCE_HISTORY = '/student-history';

  // ===== PARENT ROUTES =====
  // Parent wrapper: /parent
  // Child routes (nested under /parent)
  static const PARENT_DASHBOARD = '/parent-dashboard';
  static const PARENT_CHILD_PROGRESS = '/parent-child-progress';
  static const PARENT_ANNOUNCEMENTS = '/parent-announcements';
  static const PARENT_PROFILE = '/parent-profile';

  // ===== STUDENT ROUTES =====
  // Student wrapper: /student
  // Child routes (nested under /student)
  static const STUDENT_DASHBOARD = '/student-dashboard';
  static const STUDENT_SCHEDULE = '/student-schedule';
  static const STUDENT_ATTENDANCE = '/student-attendance';
  static const STUDENT_ANNOUNCEMENTS = '/student-announcements';
  static const STUDENT_PROFILE = '/student-profile';

  // Helper methods untuk mendapatkan full path
  static String getTeacherRoute(String route) => '/main$route';
  static String getParentRoute(String route) => '/parent$route';
  static String getStudentRoute(String route) => '/student$route';
}
