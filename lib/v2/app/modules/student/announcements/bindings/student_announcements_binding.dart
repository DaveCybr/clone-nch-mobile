// lib/v2/app/modules/student/announcements/bindings/student_announcements_binding.dart
import 'package:get/get.dart';
import '../controllers/student_announcements_controller.dart';

class StudentAnnouncementsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentAnnouncementsController>(
      () => StudentAnnouncementsController(),
      fenix: true, // ✅ Sama seperti teacher, biar controller tetap hidup
    );
  }
}
