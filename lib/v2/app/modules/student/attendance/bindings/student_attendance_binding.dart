// lib/v2/app/modules/student/attendance/bindings/student_attendance_binding.dart
import 'package:get/get.dart';
import '../controllers/student_attendance_controller.dart';

class StudentAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentAttendanceController>(
      () => StudentAttendanceController(),
    );
  }
}
