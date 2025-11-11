// lib/v2/app/modules/security/profile/bindings/security_profile_binding.dart

import 'package:get/get.dart';
import '../controllers/security_profile_controller.dart';

class SecurityProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SecurityProfileController>(() => SecurityProfileController());
  }
}
