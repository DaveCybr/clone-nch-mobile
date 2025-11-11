// lib/v2/app/modules/security/today_visitors/views/today_visitors_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/visitor_controller.dart';

class TodayVisitorsView extends GetView<TodayVisitorsController> {
  const TodayVisitorsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Pengunjung Hari Ini', style: AppTextStyles.appBarTitle),
        centerTitle: true,
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildStatsSummary(),
          Expanded(child: _buildVisitorsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.cardBackground,
      child: TextField(
        // controller: controller.se,
        onChanged: controller.searchVisitors,
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
                  controller.searchQuery.value = '';
                  controller.searchVisitors('');
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

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: AppColors.cardBackground,
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Semua',
                value: 'ALL',
                color: AppColors.primaryGreen,
              ),
              SizedBox(width: 8.w),
              _buildFilterChip(
                label: 'Normal',
                value: 'NORMAL',
                color: AppColors.attendancePresent,
                count: controller.normalCount,
              ),
              SizedBox(width: 8.w),
              _buildFilterChip(
                label: 'Overstay',
                value: 'OVERSTAY',
                color: AppColors.attendanceAbsent,
                count: controller.overstayCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color color,
    int? count,
  }) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;

      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 12.sp,
              ),
            ),
            if (count != null && count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) controller.changeFilter(value);
        },
        selectedColor: color.withOpacity(0.15),
        backgroundColor: AppColors.scaffoldBackground,
        checkmarkColor: color,
        side: BorderSide(
          color: isSelected ? color : AppColors.dividerColor,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      );
    });
  }

  Widget _buildStatsSummary() {
    return Obx(
      () => Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  controller.totalVisitors.toString(),
                  Icons.people_outline,
                  AppColors.attendanceSick,
                ),
              ),
              Container(
                width: 1,
                color: AppColors.dividerColor,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              Expanded(
                child: _buildStatItem(
                  'Normal',
                  controller.normalCount.toString(),
                  Icons.check_circle_outline,
                  AppColors.attendancePresent,
                ),
              ),
              Container(
                width: 1,
                color: AppColors.dividerColor,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              Expanded(
                child: _buildStatItem(
                  'Overstay',
                  controller.overstayCount.toString(),
                  Icons.warning_amber_outlined,
                  AppColors.attendanceAbsent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(color: color, fontSize: 20.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
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
                  onPressed: controller.loadVisitors,
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

      final visitors = controller.filteredVisitors;

      if (visitors.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16.h),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'Tidak ditemukan pengunjung'
                      : 'Belum ada pengunjung hari ini',
                  textAlign: TextAlign.center,
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
        child: ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: visitors.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            return _buildVisitorCard(visitors[index]);
          },
        ),
      );
    });
  }

  Widget _buildVisitorCard(visitor) {
    final isOverstay = visitor.isOverstay ?? false;
    final statusColor =
        isOverstay ? AppColors.attendanceAbsent : AppColors.attendancePresent;

    return GestureDetector(
      onTap: () => _showVisitorDetail(visitor),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOverstay ? Icons.warning_amber : Icons.person_outline,
                      color: statusColor,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          visitor.parentName ?? '',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Mengunjungi: ${visitor.studentName ?? ''}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      isOverstay ? 'Overstay' : 'Normal',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.dividerColor, height: 1),

            // Details
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    Icons.school_outlined,
                    'Kelas',
                    visitor.studentClass ?? '-',
                  ),
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    Icons.description_outlined,
                    'Tujuan',
                    visitor.visitPurpose ?? '-',
                  ),
                  SizedBox(height: 8.h),
                  _buildDetailRow(
                    Icons.access_time,
                    'Check In',
                    visitor.checkInTime != null
                        ? _formatTime(visitor.checkInTime!)
                        : '-',
                  ),
                  SizedBox(height: 12.h),

                  // Time Stats
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Durasi',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                visitor.durationText ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  fontSize: 14.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.attendancePermit.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.attendancePermit.withOpacity(
                                0.2,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOverstay ? 'Lewat' : 'Sisa',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                visitor.remainingText ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isOverstay
                                          ? AppColors.attendanceAbsent
                                          : AppColors.attendancePermit,
                                  fontSize: 14.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.checkOutVisitor(visitor),
                      icon: Icon(Icons.logout, size: 18.sp),
                      label: Text(
                        'Check Out',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${_formatTime(dt)}';
  }

  void _showFilterBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Pengunjung', style: AppTextStyles.heading3),
              SizedBox(height: 20.h),
              _buildFilterOption(
                icon: Icons.people_outline,
                title: 'Semua Pengunjung',
                value: 'ALL',
                color: AppColors.primaryGreen,
              ),
              _buildFilterOption(
                icon: Icons.check_circle_outline,
                title: 'Normal',
                value: 'NORMAL',
                color: AppColors.attendancePresent,
              ),
              _buildFilterOption(
                icon: Icons.warning_amber_outlined,
                title: 'Overstay',
                value: 'OVERSTAY',
                color: AppColors.attendanceAbsent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Obx(
      () => InkWell(
        onTap: () {
          controller.changeFilter(value);
          Get.back();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: controller.selectedFilter.value,
                onChanged: (val) {
                  controller.changeFilter(val!);
                  Get.back();
                },
                activeColor: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitorDetail(visitor) {
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
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text('Detail Pengunjung', style: AppTextStyles.heading3),
              ),
              Divider(height: 1, color: AppColors.dividerColor),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Barcode', visitor.barcode ?? '-'),
                      _buildInfoRow('Status', visitor.status ?? '-'),
                      Divider(color: AppColors.dividerColor),
                      _buildInfoRow('Orang Tua', visitor.parentName ?? '-'),
                      if (visitor.parentPhone != null)
                        _buildInfoRow('No. HP', visitor.parentPhone ?? '-'),
                      Divider(color: AppColors.dividerColor),
                      _buildInfoRow('Siswa', visitor.studentName ?? '-'),
                      _buildInfoRow('Kelas', visitor.studentClass ?? '-'),
                      Divider(color: AppColors.dividerColor),
                      _buildInfoRow('Tujuan', visitor.visitPurpose ?? '-'),
                      _buildInfoRow(
                        'Check In',
                        visitor.checkInTime != null
                            ? _formatDateTime(visitor.checkInTime!)
                            : '-',
                      ),
                      _buildInfoRow('Durasi', visitor.durationText ?? '-'),
                      _buildInfoRow(
                        visitor.isOverstay == true ? 'Melebihi' : 'Sisa Waktu',
                        visitor.remainingText ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.dividerColor),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Tutup',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        controller.checkOutVisitor(visitor);
                      },
                      icon: Icon(Icons.logout, size: 18.sp),
                      label: Text(
                        'Check Out',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                      ),
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

  Widget _buildInfoRow(String label, String value) {
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
}
