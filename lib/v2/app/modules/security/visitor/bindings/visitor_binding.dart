// lib/v2/app/modules/security/today_visitors/bindings/today_visitors_binding.dart

import 'package:get/get.dart';
import '../controllers/visitor_controller.dart';

class TodayVisitorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TodayVisitorsController>(() => TodayVisitorsController());
  }
}
