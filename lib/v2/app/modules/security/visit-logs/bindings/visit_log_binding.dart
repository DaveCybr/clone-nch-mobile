// lib/v2/app/modules/security/visit_logs/bindings/visit_logs_binding.dart

import 'package:get/get.dart';
import '../controllers/visit_log_controller.dart';

class VisitLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitLogsController>(() => VisitLogsController());
  }
}
