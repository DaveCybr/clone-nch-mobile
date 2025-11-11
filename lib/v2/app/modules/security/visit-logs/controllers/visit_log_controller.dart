// lib/v2/app/modules/security/visit_logs/controllers/visit_logs_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/visit_log_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'dart:developer' as developer;

class VisitLogsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // State
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  // Data
  final RxList<VisitLog> visitLogs = <VisitLog>[].obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasMoreData = true.obs;

  // Filters
  final selectedStatus = Rx<VisitStatus?>(null);
  final searchQuery = ''.obs;
  final startDate = Rx<DateTime?>(null);
  final endDate = Rx<DateTime?>(null);

  // Controllers
  final refreshController = RefreshController(initialRefresh: false);
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadVisitLogs();
  }

  @override
  void onClose() {
    refreshController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Load visit logs
  Future<void> loadVisitLogs({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
      }

      if (currentPage.value == 1) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      errorMessage.value = '';

      final response = await _apiService.getVisitHistory(
        startDate: startDate.value?.toIso8601String().split('T')[0],
        endDate: endDate.value?.toIso8601String().split('T')[0],
        status: selectedStatus.value?.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        page: currentPage.value,
        perPage: 20,
      );

      developer.log('Visit Logs Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final paginationData = response['data'];

        // Parse pagination data (Laravel structure)
        final List<dynamic> data = paginationData['data'] ?? [];
        final newLogs = data.map((json) => VisitLog.fromJson(json)).toList();

        if (isRefresh || currentPage.value == 1) {
          visitLogs.value = newLogs;
        } else {
          visitLogs.addAll(newLogs);
        }

        // Update pagination info
        totalPages.value = paginationData['last_page'] ?? 1;
        hasMoreData.value = currentPage.value < totalPages.value;

        developer.log(
          'Loaded ${newLogs.length} logs, page ${currentPage.value}/${totalPages.value}',
        );
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      developer.log('Error loading visit logs: $e');
      errorMessage.value = e.toString();

      if (currentPage.value == 1) {
        Get.snackbar(
          'Error',
          'Gagal memuat data: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.attendanceAbsent,
          colorText: Colors.white,
          margin: EdgeInsets.all(16.w),
          borderRadius: 12.r,
        );
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Refresh data
  Future<void> onRefresh() async {
    try {
      await loadVisitLogs(isRefresh: true);
      refreshController.refreshCompleted();
    } catch (e) {
      refreshController.refreshFailed();
    }
  }

  /// Load more data
  Future<void> onLoadMore() async {
    if (!hasMoreData.value || isLoadingMore.value) {
      refreshController.loadComplete();
      return;
    }

    try {
      currentPage.value++;
      await loadVisitLogs();
      refreshController.loadComplete();
    } catch (e) {
      currentPage.value--;
      refreshController.loadFailed();
    }
  }

  /// Search visits
  void searchVisits(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    loadVisitLogs(isRefresh: true);
  }

  /// Filter by status
  void filterByStatus(VisitStatus? status) {
    selectedStatus.value = status;
    currentPage.value = 1;
    loadVisitLogs(isRefresh: true);
  }

  /// Filter by date range
  void filterByDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    currentPage.value = 1;
    loadVisitLogs(isRefresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    selectedStatus.value = null;
    searchQuery.value = '';
    searchController.clear();
    startDate.value = null;
    endDate.value = null;
    currentPage.value = 1;
    loadVisitLogs(isRefresh: true);
  }

  /// Show filter dialog
  void showFilterDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'Filter Kunjungan',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Filter
                      Text(
                        'Status',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Obx(
                        () => Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _buildFilterChip(
                              label: 'Semua',
                              isSelected: selectedStatus.value == null,
                              onTap: () => filterByStatus(null),
                              color: AppColors.primaryGreen,
                            ),
                            ...VisitStatus.values.map((status) {
                              return _buildFilterChip(
                                label: status.label,
                                isSelected: selectedStatus.value == status,
                                onTap: () => filterByStatus(status),
                                color: _getStatusColor(status),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Date Range
                      Text(
                        'Tanggal',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => OutlinedButton.icon(
                                icon: Icon(Icons.calendar_today, size: 18.sp),
                                label: Text(
                                  startDate.value != null
                                      ? _formatDate(startDate.value!)
                                      : 'Dari',
                                  style: AppTextStyles.bodySmall,
                                ),
                                onPressed: () => _selectStartDate(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 12.h,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.dividerColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Obx(
                              () => OutlinedButton.icon(
                                icon: Icon(Icons.calendar_today, size: 18.sp),
                                label: Text(
                                  endDate.value != null
                                      ? _formatDate(endDate.value!)
                                      : 'Sampai',
                                  style: AppTextStyles.bodySmall,
                                ),
                                onPressed: () => _selectEndDate(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 12.h,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.dividerColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: AppColors.dividerColor),

              // Actions
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        clearFilters();
                        Get.back();
                      },
                      child: Text(
                        'Reset',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: Text('Terapkan', style: AppTextStyles.buttonText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? color : AppColors.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(VisitStatus status) {
    switch (status) {
      case VisitStatus.pending:
        return AppColors.attendancePermit;
      case VisitStatus.checkedIn:
        return AppColors.attendancePresent;
      case VisitStatus.checkedOut:
        return AppColors.attendanceSick;
      case VisitStatus.overstay:
        return AppColors.attendanceAbsent;
      case VisitStatus.cancelled:
        return AppColors.textHint;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      startDate.value = picked;
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: endDate.value ?? DateTime.now(),
      firstDate: startDate.value ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      endDate.value = picked;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Show visit detail
  void showVisitDetail(VisitLog visit) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Detail Kunjungan',
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Barcode', visit.barcode),
                      _buildDetailRow('Status', visit.status.label),
                      Divider(height: 24.h, color: AppColors.dividerColor),
                      _buildDetailRow('Orang Tua', visit.parent?.name ?? '-'),
                      _buildDetailRow(
                        'No. HP',
                        visit.parent?.phoneNumber ?? '-',
                      ),
                      _buildDetailRow('Siswa', visit.student?.user.name ?? '-'),
                      _buildDetailRow(
                        'Kelas',
                        visit.student?.kelas?.name ?? '-',
                      ),
                      Divider(height: 24.h, color: AppColors.dividerColor),
                      _buildDetailRow('Tujuan', visit.visitPurpose),
                      _buildDetailRow(
                        'Jadwal',
                        visit.visitSchedule?.title ?? '-',
                      ),
                      _buildDetailRow(
                        'Lokasi',
                        visit.visitSchedule?.location ?? '-',
                      ),
                      Divider(height: 24.h, color: AppColors.dividerColor),
                      if (visit.checkInTime != null) ...[
                        _buildDetailRow(
                          'Check In',
                          _formatDateTime(visit.checkInTime!),
                        ),
                        if (visit.checkedInBy != null)
                          _buildDetailRow('Oleh', visit.checkedInBy!.name),
                      ],
                      if (visit.checkOutTime != null) ...[
                        SizedBox(height: 8.h),
                        _buildDetailRow(
                          'Check Out',
                          _formatDateTime(visit.checkOutTime!),
                        ),
                        if (visit.checkedOutBy != null)
                          _buildDetailRow('Oleh', visit.checkedOutBy!.name),
                      ],
                      if (visit.durationMinutes != null) ...[
                        SizedBox(height: 8.h),
                        _buildDetailRow(
                          'Durasi',
                          '${visit.durationMinutes} menit',
                        ),
                      ],
                      if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        _buildDetailRow('Catatan', visit.notes!),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: AppColors.dividerColor),

              // Actions
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Tutup',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Get filter summary text
  String get filterSummary {
    List<String> filters = [];

    if (selectedStatus.value != null) {
      filters.add(selectedStatus.value!.label);
    }

    if (startDate.value != null && endDate.value != null) {
      filters.add(
        '${_formatDate(startDate.value!)} - ${_formatDate(endDate.value!)}',
      );
    } else if (startDate.value != null) {
      filters.add('Dari ${_formatDate(startDate.value!)}');
    } else if (endDate.value != null) {
      filters.add('Sampai ${_formatDate(endDate.value!)}');
    }

    if (searchQuery.value.isNotEmpty) {
      filters.add('"${searchQuery.value}"');
    }

    return filters.isEmpty ? 'Semua Data' : filters.join(' • ');
  }

  /// Check if any filter is active
  bool get hasActiveFilter {
    return selectedStatus.value != null ||
        startDate.value != null ||
        endDate.value != null ||
        searchQuery.value.isNotEmpty;
  }
}
