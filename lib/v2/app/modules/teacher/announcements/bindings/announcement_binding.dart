// lib/v2/app/modules/teacher/announcements/bindings/announcements_binding.dart
import 'package:get/get.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnnouncementsController>(
      () => AnnouncementsController(),
      fenix: true,
    );
  }
}
