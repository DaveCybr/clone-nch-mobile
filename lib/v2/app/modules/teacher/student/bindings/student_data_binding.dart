// lib/v2/app/modules/teacher/students/bindings/student_data_binding.dart
import 'package:get/get.dart';

import '../controllers/student_data_controller.dart';

class StudentDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentDataController>(
      () => StudentDataController(),
      fenix: true,
    );
  }
}

// lib/v2/app/modules/teacher/student/views/student_data_view.dart - UPDATE AppBar
