// lib/v2/app/routes/app_routes.dart - CLEAN VERSION

abstract class Routes {
  // ===== ROOT ROUTES =====
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // ===== MAIN WRAPPERS =====
  static const TEACHER = '/teacher';
  static const STUDENT = '/student';
  static const PARENT = '/parent';
  static const SECURITY = '/security';

  // ===== TEACHER ROUTES (Nested dalam Bottom Nav) =====
  static const TEACHER_DASHBOARD = '/teacher/dashboard';
  static const TEACHER_SCHEDULE = '/teacher/schedule';
  static const TEACHER_STUDENTS = '/teacher/students';
  static const TEACHER_PROFILE = '/teacher/profile';

  // ===== TEACHER FULLSCREEN (Di luar Bottom Nav) =====
  static const TEACHER_ATTENDANCE = '/teacher/attendance';
  static const TEACHER_ANNOUNCEMENTS = '/teacher/announcements';
  static const STUDENT_HISTORY = '/teacher/student-history';

  // ===== STUDENT ROUTES (Nested dalam Bottom Nav) =====
  static const STUDENT_DASHBOARD = '/student/dashboard';
  static const STUDENT_SCHEDULE = '/student/schedule';
  static const STUDENT_ATTENDANCE = '/student/attendance';
  static const STUDENT_ANNOUNCEMENTS = '/student/announcements';
  static const STUDENT_VISIT = '/student/visit';
  static const STUDENT_PROFILE = '/student/profile';

  // ===== STUDENT FULLSCREEN =====
  static const STUDENT_VISIT_QR = '/student/visit-qr';

  // ===== PARENT ROUTES (Nested) =====
  static const PARENT_DASHBOARD = '/parent/dashboard';
  static const PARENT_CHILD = '/parent/child';
  static const PARENT_ANNOUNCEMENTS = '/parent/announcements';
  static const PARENT_PROFILE = '/parent/profile';

  // ===== SECURITY ROUTES (Nested) =====
  static const SECURITY_DASHBOARD = '/security/dashboard';
  static const SECURITY_SCAN = '/security/scan';
  static const SECURITY_VISITORS = '/security/visitors';
  static const SECURITY_PROFILE = '/security/profile';

  // ===== SECURITY FULLSCREEN =====
  static const SECURITY_LOGS = '/security/logs';
  static const SECURITY_CHECKIN = '/security/checkin';
  static const SECURITY_CHECKOUT = '/security/checkout';

  // ===== HELPER: Check if route needs bottom nav =====
  static bool hasBottomNav(String route) {
    return route == TEACHER_DASHBOARD ||
        route == TEACHER_SCHEDULE ||
        route == TEACHER_STUDENTS ||
        route == TEACHER_PROFILE ||
        route == STUDENT_DASHBOARD ||
        route == STUDENT_SCHEDULE ||
        route == STUDENT_ATTENDANCE ||
        route == STUDENT_ANNOUNCEMENTS ||
        route == STUDENT_VISIT ||
        route == STUDENT_PROFILE ||
        route == PARENT_DASHBOARD ||
        route == PARENT_CHILD ||
        route == PARENT_ANNOUNCEMENTS ||
        route == PARENT_PROFILE ||
        route == SECURITY_DASHBOARD ||
        route == SECURITY_SCAN ||
        route == SECURITY_VISITORS ||
        route == SECURITY_PROFILE;
  }

  // ===== HELPER: Get default route by role =====
  static String getDefaultRouteByRole(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
      case 'guru':
        return TEACHER_DASHBOARD;
      case 'student':
      case 'santri':
        return STUDENT_DASHBOARD;
      case 'parent':
      case 'wali':
        return PARENT_DASHBOARD;
      case 'security':
      case 'satpam':
        return SECURITY_DASHBOARD;
      default:
        return LOGIN;
    }
  }
}
