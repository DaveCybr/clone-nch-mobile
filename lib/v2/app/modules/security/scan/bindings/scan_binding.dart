// lib/v2/app/modules/security/scan/bindings/security_scan_binding.dart

import 'package:get/get.dart';
import '../controllers/scan_controller.dart';

class SecurityScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SecurityScanController>(() => SecurityScanController());
  }
}
