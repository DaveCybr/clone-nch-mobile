abstract class Routes {
  // ===== COMMON ROUTES =====
  static const SPLASH = '/';
  static const LOGIN = '/login';

  // ===== TEACHER ROUTES =====
  // Main wrapper untuk teacher: /main
  static const MAIN = '/main';
  static const STUDENT = '/student';
  static const PARENT = '/parent';
  static const SECURITY = '/security';

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

  // ✅ TAMBAHKAN INI - Visit Schedule Routes
  static const STUDENT_VISIT_SCHEDULE = '/visit-schedule';
  static const STUDENT_VISIT_QR = '/visit-schedule/qr';
  // ===== SECURITY ROUTES =====
  // Security wrapper: /security
  // Child routes (nested under /security)
  static const SECURITY_DASHBOARD = '/security-dashboard';
  static const SECURITY_SCAN = '/security-scan'; // Scan barcode/QR
  static const SECURITY_VISIT_LOGS = '/security-visit-logs'; // Daftar kunjungan
  static const SECURITY_CHECK_IN = '/security-check-in'; // Check-in manual
  static const SECURITY_CHECK_OUT = '/security-check-out'; // Check-out manual
  static const SECURITY_TODAY_VISITORS =
      '/security-today-visitors'; // Pengunjung hari ini
  static const SECURITY_HISTORY = '/security-history'; // Riwayat kunjungan
  static const SECURITY_PROFILE = '/security-profile';

  // Helper methods untuk mendapatkan full path
  static String getTeacherRoute(String route) => '/main$route';
  static String getParentRoute(String route) => '/parent$route';
  static String getStudentRoute(String route) => '/student$route';
  static String getSecurityRoute(String route) => '/security$route';
}

