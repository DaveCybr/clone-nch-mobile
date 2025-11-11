// lib/v2/app/modules/security/dashboard/controllers/security_dashboard_controller.dart
// FIXED VERSION - Using NavigationService

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/security_dashboard_model.dart';
import '../../../../data/services/navigations_services.dart';
import '../../../../routes/app_routes.dart'; // ✅ ADDED
import 'dart:developer' as developer;

class SecurityDashboardController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  // Data
  final Rx<SecurityDashboardData?> dashboardData = Rx<SecurityDashboardData?>(
    null,
  );
  final Rx<DashboardStats?> stats = Rx<DashboardStats?>(null);
  final RxList<CurrentVisitor> currentVisitors = <CurrentVisitor>[].obs;
  final RxList<TodaySchedule> todaySchedules = <TodaySchedule>[].obs;

  // Refresh controller
  final refreshController = RefreshController(initialRefresh: false);

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.dispose();
  }

  /// Load dashboard data
  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getSecurityDashboard();
      developer.log('Dashboard Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = SecurityDashboardData.fromJson(response['data']);
        dashboardData.value = data;
        stats.value = data.stats;
        currentVisitors.value = data.currentVisitors;
        todaySchedules.value = data.todaySchedules;
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat dashboard');
      }
    } catch (e) {
      developer.log('Error loading dashboard: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat dashboard: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard
  Future<void> onRefresh() async {
    try {
      isRefreshing.value = true;
      await loadDashboard();
      refreshController.refreshCompleted();
    } catch (e) {
      refreshController.refreshFailed();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Manual check out visitor
  Future<void> manualCheckOut(String visitId, {String? notes}) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.manualCheckOut(
        visitId: visitId,
        notes: notes,
      );

      Get.back(); // Close loading

      if (response['success'] == true) {
        Get.snackbar(
          'Berhasil',
          response['message'] ?? 'Check out berhasil',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );

        // Reload dashboard
        await loadDashboard();
      } else {
        throw Exception(response['message'] ?? 'Gagal check out');
      }
    } catch (e) {
      Get.back(); // Close loading if still open
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }

  /// Check for overstay visitors
  Future<void> checkOverstay() async {
    try {
      final response = await _apiService.checkOverstayVisitors();

      if (response['success'] == true) {
        final count = response['overstay_count'] ?? 0;
        if (count > 0) {
          Get.snackbar(
            'Update Status',
            '$count pengunjung diupdate menjadi overstay',
            snackPosition: SnackPosition.BOTTOM,
          );
          await loadDashboard();
        }
      }
    } catch (e) {
      developer.log('Error checking overstay: $e');
    }
  }

  /// ✅ FIXED: Navigate to scan screen (Tab)
  void goToScanScreen() {
    // ✅ Security Scan is a bottom nav tab
    NavigationService.to.toBottomNavTab(Routes.SECURITY_SCAN);
  }

  /// ✅ FIXED: Navigate to visit logs (Fullscreen)
  void goToVisitLogs() {
    // ✅ Visit logs is fullscreen
    NavigationService.to.toFullscreen(Routes.SECURITY_LOGS);
  }

  /// ✅ FIXED: Navigate to history (if exists)
  void goToHistory() {
    // ✅ TODO: Confirm if this is fullscreen or tab
    // Assuming fullscreen based on naming convention
    NavigationService.to.toFullscreen('/security-history');
  }

  /// ✅ NEW: Navigate to visitors list (Tab)
  void goToVisitorsList() {
    NavigationService.to.toBottomNavTab(Routes.SECURITY_VISITORS);
  }

  /// ✅ NEW: Navigate to profile (Tab)
  void goToProfile() {
    NavigationService.to.toBottomNavTab(Routes.SECURITY_PROFILE);
  }

  /// ✅ NEW: Navigate to checkout page (Fullscreen)
  void goToCheckout(String visitId) {
    NavigationService.to.toFullscreen(
      Routes.SECURITY_CHECKOUT,
      arguments: {'visit_id': visitId},
    );
  }

  /// ✅ NEW: Navigate to checkin page (Fullscreen)
  void goToCheckin() {
    NavigationService.to.toFullscreen(Routes.SECURITY_CHECKIN);
  }
}
