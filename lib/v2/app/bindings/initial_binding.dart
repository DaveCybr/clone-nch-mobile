// lib/v2/app/bindings/initial_binding.dart

import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AuthController
    // fenix: true means it will be recreated if disposed
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
