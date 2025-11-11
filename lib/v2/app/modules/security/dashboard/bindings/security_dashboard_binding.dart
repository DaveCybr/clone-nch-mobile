// lib/v2/app/modules/security/dashboard/bindings/security_dashboard_binding.dart

import 'package:get/get.dart';
import '../controllers/security_dashboard_controller.dart';

class SecurityDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SecurityDashboardController>(
      () => SecurityDashboardController(),
    );
  }
}
