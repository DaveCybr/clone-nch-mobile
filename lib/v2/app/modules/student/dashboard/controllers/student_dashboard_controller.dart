// lib/v2/app/modules/student/dashboard/controllers/student_dashboard_controller.dart

import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/models/attendance_model.dart';
import '../../../../data/models/student_dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class StudentDashboardController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = true.obs;
  final error = Rx<String?>(null);

  final dashboardData = Rx<StudentDashboardModel?>(null);
  final schedulesToday = <ScheduleModel>[].obs;
  final attendanceToday = <StudentAttendanceModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      error.value = null;

      final response = await _apiService.getStudentDashboard();

      if (response['data'] != null) {
        dashboardData.value = StudentDashboardModel.fromJson(response['data']);
        schedulesToday.value = dashboardData.value!.schedulesToday;
        attendanceToday.value = dashboardData.value!.attendanceToday;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  int get totalSchedulesToday => schedulesToday.length;

  int get attendanceHadir =>
      attendanceToday.where((a) => a.currentStatus == 'HADIR').length;

  int get attendanceSakit =>
      attendanceToday.where((a) => a.currentStatus == 'SAKIT').length;

  int get attendanceIzin =>
      attendanceToday.where((a) => a.currentStatus == 'IZIN').length;

  int get attendanceAlpha =>
      attendanceToday.where((a) => a.currentStatus == 'ALPHA').length;
}
