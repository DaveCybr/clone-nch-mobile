// lib/v2/app/modules/teacher/attendance/bindings/attendance_binding.dart
import 'package:get/get.dart';
import '../controllers/attendance_controller.dart';

class AttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AttendanceController>(
      () => AttendanceController(),
      fenix: true,
    );
  }
}



// Update app_routes.dart - Tambahkan routes ini:
// Di class Routes, tambahkan:
/*
  static const TEACHER_ATTENDANCE = '/teacher/attendance';
  static const TEACHER_STUDENTS = '/teacher/students';
  static const STUDENT_ATTENDANCE_HISTORY = '/teacher/student-history';
*/

// Update app_pages.dart - Tambahkan pages ini:
/*
import '../modules/teacher/attendance/bindings/attendance_binding.dart';
import '../modules/teacher/attendance/views/attendance_view.dart';
import '../modules/teacher/students/bindings/student_data_binding.dart';
import '../modules/teacher/students/views/student_data_view.dart';
import '../modules/teacher/student_history/bindings/student_history_binding.dart';
import '../modules/teacher/student_history/views/student_history_view.dart';

// Tambahkan ke routes list:
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
*/