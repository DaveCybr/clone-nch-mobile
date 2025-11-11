// lib/v2/app/modules/student/profile/bindings/profile_binding.dart
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class StudentProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentProfileController>(
      () => StudentProfileController(),
      fenix: true,
    );
  }
}
