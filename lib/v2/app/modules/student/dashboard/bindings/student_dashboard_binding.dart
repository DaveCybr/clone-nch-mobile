// lib/v2/app/modules/student/dashboard/bindings/student_dashboard_binding.dart

import 'package:get/get.dart';
import '../controllers/student_dashboard_controller.dart';

class StudentDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentDashboardController>(() => StudentDashboardController());
  }
}
