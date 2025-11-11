// lib/v2/app/modules/security/today_visitors/controllers/today_visitors_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/security_dashboard_model.dart';
import 'dart:developer' as developer;

class TodayVisitorsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Data
  final RxList<CurrentVisitor> visitors = <CurrentVisitor>[].obs;
  final RxList<CurrentVisitor> filteredVisitors = <CurrentVisitor>[].obs;

  // Filter
  final searchQuery = ''.obs;
  final selectedFilter = 'ALL'.obs; // ALL, NORMAL, OVERSTAY

  // Refresh controller
  final refreshController = RefreshController(initialRefresh: false);

  @override
  void onInit() {
    super.onInit();
    loadVisitors();

    // Auto refresh every 15 seconds
    // _startAutoRefresh();
  }

  @override
  void onClose() {
    refreshController.dispose();
    super.onClose();
  }

  /// Load current visitors
  Future<void> loadVisitors() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.getCurrentVisitors();

      visitors.value =
          response.map((json) => CurrentVisitor.fromJson(json)).toList();

      _applyFilters();
    } catch (e) {
      developer.log('Error loading visitors: $e');
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Gagal memuat data pengunjung: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh visitors
  Future<void> onRefresh() async {
    try {
      await loadVisitors();
      refreshController.refreshCompleted();
    } catch (e) {
      refreshController.refreshFailed();
    }
  }

  /// Apply filters
  void _applyFilters() {
    var result = visitors.toList();

    // Filter by status
    if (selectedFilter.value == 'OVERSTAY') {
      result = result.where((v) => v.isOverstay).toList();
    } else if (selectedFilter.value == 'NORMAL') {
      result = result.where((v) => !v.isOverstay).toList();
    }

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result =
          result.where((v) {
            return v.parentName.toLowerCase().contains(query) ||
                v.studentName.toLowerCase().contains(query) ||
                v.studentClass.toLowerCase().contains(query);
          }).toList();
    }

    filteredVisitors.value = result;
  }

  /// Search visitors
  void searchVisitors(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Change filter
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  /// Manual check out visitor
  Future<void> checkOutVisitor(CurrentVisitor visitor) async {
    try {
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Konfirmasi Check Out'),
          content: Text(
            'Check out ${visitor.parentName}?\n\n'
            'Durasi kunjungan: ${visitor.durationText}',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Check Out'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.manualCheckOut(visitId: visitor.id);

      Get.back(); // Close loading

      if (response['success'] == true) {
        Get.snackbar(
          'Berhasil',
          'Check out berhasil',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
        );

        await loadVisitors();
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

  /// Auto refresh every 15 seconds
  // void _startAutoRefresh() {
  //   Future.delayed(const Duration(seconds: 15), () {
  //     if (!isClosed) {
  //       loadVisitors();
  //       _startAutoRefresh();
  //     }
  //   });
  // }

  /// Get statistics
  int get totalVisitors => visitors.length;
  int get overstayCount => visitors.where((v) => v.isOverstay).length;
  int get normalCount => visitors.where((v) => !v.isOverstay).length;
}
