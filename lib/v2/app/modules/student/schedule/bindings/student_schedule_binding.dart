// lib/v2/app/modules/student/schedule/bindings/student_schedule_binding.dart
import 'package:get/get.dart';
import '../controllers/student_schedule_controller.dart';

class StudentScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentScheduleController>(() => StudentScheduleController());
  }
}
