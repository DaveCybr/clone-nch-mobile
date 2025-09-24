abstract class Routes {
  // Common routes
  static const INITIAL = '/';
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // Teacher routes
  static const TEACHER_DASHBOARD = '/teacher/dashboard';
  static const TEACHER_SCHEDULE = '/teacher/schedule';
  static const TEACHER_ATTENDANCE = '/teacher/attendance';
  static const TEACHER_STUDENTS = '/teacher/students';
  static const TEACHER_ANNOUNCEMENTS = '/teacher/announcements';
  static const TEACHER_PROFILE = '/teacher/profile';
  static const STUDENT_ATTENDANCE_HISTORY = '/teacher/student-history';

  // Parent routes (for future development)
  static const PARENT_DASHBOARD = '/parent/dashboard';
  static const PARENT_CHILD_PROGRESS = '/parent/child-progress';
  static const PARENT_ANNOUNCEMENTS = '/parent/announcements';
  static const PARENT_PROFILE = '/parent/profile';
}
