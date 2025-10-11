
// lib/v2/app/modules/teacher/student_history/bindings/student_history_binding.dart
import 'package:get/get.dart';

import '../controllers/student_history_controller.dart';

class StudentHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentHistoryController>(
      () => StudentHistoryController(),
      fenix: true,
    );
  }
}