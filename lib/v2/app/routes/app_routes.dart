abstract class Routes {
  // Common routes
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // Main wrapper
  static const MAIN = '/';

  // Teacher routes (relative ke MAIN)
  static const TEACHER_DASHBOARD = '/dashboard';
  static const TEACHER_SCHEDULE = '/schedule';
  static const TEACHER_ATTENDANCE = '/attendance';
  static const TEACHER_STUDENTS = '/students';
  static const TEACHER_ANNOUNCEMENTS = '/announcements';
  static const TEACHER_PROFILE = '/profile';
  static const STUDENT_ATTENDANCE_HISTORY = '/student-history';

  // Parent routes (relative ke MAIN juga, jika perlu nanti)
  static const PARENT_DASHBOARD = '/parent-dashboard';
  static const PARENT_CHILD_PROGRESS = '/parent-child-progress';
  static const PARENT_ANNOUNCEMENTS = '/parent-announcements';
  static const PARENT_PROFILE = '/parent-profile';
}
