// lib/v2/app/modules/student/visit_schedule/bindings/visit_schedule_binding.dart

import 'package:get/get.dart';
import '../controllers/visit_schedule_controller.dart';

class VisitScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitScheduleController>(() => VisitScheduleController());
  }
}
