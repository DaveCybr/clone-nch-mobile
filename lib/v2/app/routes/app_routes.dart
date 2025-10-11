abstract class Routes {
  // Common routes
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

<<<<<<< HEAD
  // Main wrapper
  static const MAIN = '/';

  // Teacher routes (relative ke MAIN)
=======
<<<<<<< HEAD
  // Main wrapper - gunakan sebagai base
  static const MAIN = '/main';

  // Teacher routes (nested under /main)
=======
  // Main wrapper
  static const MAIN = '/';

  // Teacher routes (relative ke MAIN)
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
>>>>>>> prod
  static const TEACHER_DASHBOARD = '/dashboard';
  static const TEACHER_SCHEDULE = '/schedule';
  static const TEACHER_ATTENDANCE = '/attendance';
  static const TEACHER_STUDENTS = '/students';
  static const TEACHER_ANNOUNCEMENTS = '/announcements';
  static const TEACHER_PROFILE = '/profile';
  static const STUDENT_ATTENDANCE_HISTORY = '/student-history';

<<<<<<< HEAD
  // Parent routes (relative ke MAIN juga, jika perlu nanti)
=======
<<<<<<< HEAD
  // Parent routes (nested under /main)
=======
  // Parent routes (relative ke MAIN juga, jika perlu nanti)
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
>>>>>>> prod
  static const PARENT_DASHBOARD = '/parent-dashboard';
  static const PARENT_CHILD_PROGRESS = '/parent-child-progress';
  static const PARENT_ANNOUNCEMENTS = '/parent-announcements';
  static const PARENT_PROFILE = '/parent-profile';
<<<<<<< HEAD
=======
<<<<<<< HEAD

  // Helper methods untuk mendapatkan full path
  static String getTeacherRoute(String route) => '/main$route';
  static String getParentRoute(String route) => '/main$route';
=======
>>>>>>> 49d3e7f6c546314a0079c5f85aecd72981ffaa46
>>>>>>> prod
}
