import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/modules/teacher/dashboard/controllers/teacher_dashboard_controller.dart';


class TeacherDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherDashboardController>(
      () => TeacherDashboardController(),
      fenix: true, // Keep alive even when not used
    );
  }
}
