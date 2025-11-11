// lib/v2/app/modules/security/visit_logs/views/visit_logs_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/visit_log_controller.dart';
import '../../../../data/models/visit_log_model.dart';

class VisitLogsView extends GetView<VisitLogsController> {
  const VisitLogsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Riwayat Kunjungan', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: controller.showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterSummary(),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.cardBackground,
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.searchVisits,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Cari nama orang tua atau siswa...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 22.sp,
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20.sp,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  controller.searchController?.clear();
                  controller.searchVisits('');
                },
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: AppColors.scaffoldBackground,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Obx(() {
      if (!controller.hasActiveFilter) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.attendanceSick.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(color: AppColors.dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt,
              size: 20.sp,
              color: AppColors.attendanceSick,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                controller.filterSummary,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.attendanceSick,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.clearFilters,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              ),
              child: Text(
                'Reset',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.attendanceSick,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLogsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.visitLogs.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        );
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.visitLogs.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: AppColors.attendanceAbsent,
                ),
                SizedBox(height: 16.h),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.attendanceAbsent,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () => controller.loadVisitLogs(isRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: Text('Coba Lagi', style: AppTextStyles.buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.visitLogs.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list_alt, size: 64.sp, color: AppColors.textHint),
                SizedBox(height: 16.h),
                Text(
                  'Tidak ada data kunjungan',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SmartRefresher(
        controller: controller.refreshController,
        onRefresh: controller.onRefresh,
        onLoading: controller.onLoadMore,
        enablePullUp: controller.hasMoreData.value,
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.visitLogs.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final visit = controller.visitLogs[index];
            return _buildLogCard(visit);
          },
        ),
      );
    });
  }

  Widget _buildLogCard(VisitLog visit) {
    final status = visit.status;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => controller.showVisitDetail(visit),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.parent?.name ?? '-',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                _buildStatusBadge(status, statusColor),
              ],
            ),

            SizedBox(height: 12.h),

            // Student info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    visit.student?.user.name ?? '-',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 13.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  visit.student?.kelas?.name ?? '-',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Purpose
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    visit.visitPurpose,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            Divider(height: 24.h, color: AppColors.dividerColor),

            // Time info
            Row(
              children: [
                if (visit.checkInTime != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check In',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatDateTime(visit.checkInTime!),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (visit.checkOutTime != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check Out',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatDateTime(visit.checkOutTime!),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (visit.durationMinutes != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Durasi',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatDuration(visit.durationMinutes!),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VisitStatus status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours jam $mins menit';
    }
    return '$mins menit';
  }
}
