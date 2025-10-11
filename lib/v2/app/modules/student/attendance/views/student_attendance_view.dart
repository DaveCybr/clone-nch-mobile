// lib/v2/app/modules/student/attendance/views/student_attendance_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/student_attendance_controller.dart';

class StudentAttendanceView extends GetView<StudentAttendanceController> {
  const StudentAttendanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => controller.pickDate(context),
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChip(),
          _buildStatistics(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return Obx(() {
      if (controller.selectedDate.value == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        color: AppColors.lightGreenBg,
        child: Row(
          children: [
            Icon(Icons.filter_alt, size: 16.sp, color: AppColors.primaryGreen),
            SizedBox(width: 8.w),
            Text(
              'Filter: ${controller.formattedSelectedDate}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: controller.clearDateFilter,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatistics() {
    return Obx(() {
      if (controller.attendances.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Statistik Kehadiran',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  controller.totalHadir.toString(),
                  'Hadir',
                  Icons.check_circle,
                ),
                _buildStatItem(
                  controller.totalSakit.toString(),
                  'Sakit',
                  Icons.local_hospital,
                ),
                _buildStatItem(
                  controller.totalIzin.toString(),
                  'Izin',
                  Icons.event_busy,
                ),
                _buildStatItem(
                  controller.totalAlpha.toString(),
                  'Alpha',
                  Icons.cancel,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Persentase: ${controller.attendancePercentage.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value != null) {
        return _buildErrorState();
      }

      if (controller.attendances.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAttendances,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // Load more when reach bottom
            if (!controller.isLoadingMore.value &&
                controller.hasMorePages &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.attendances.length + 1,
            itemBuilder: (context, index) {
              // Show loading indicator at bottom
              if (index == controller.attendances.length) {
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!controller.hasMorePages) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'Semua data telah dimuat',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                });
              }

              final attendance = controller.attendances[index];
              return _buildAttendanceCard(attendance);
            },
          ),
        ),
      );
    });
  }

  Widget _buildAttendanceCard(attendance) {
    Color statusColor;
    IconData statusIcon;

    switch (attendance.status) {
      case 'HADIR':
        statusColor = AppColors.attendancePresent;
        statusIcon = Icons.check_circle;
        break;
      case 'SAKIT':
        statusColor = AppColors.attendanceSick;
        statusIcon = Icons.local_hospital;
        break;
      case 'IZIN':
        statusColor = AppColors.attendancePermit;
        statusIcon = Icons.event_busy;
        break;
      case 'ALPHA':
        statusColor = AppColors.attendanceAbsent;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textHint;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Status indicator
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(statusIcon, color: statusColor, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            // Attendance details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attendance.subjectName, style: AppTextStyles.cardTitle),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDate(attendance.date),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  if (attendance.timeRange != null) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          attendance.timeRange!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (attendance.teacherName != null) ...[
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14.sp,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          attendance.teacherName!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (attendance.notes != null &&
                      attendance.notes!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              attendance.notes!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                attendance.statusDisplay,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text('Belum Ada Data', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              'Belum ada riwayat kehadiran\nyang tersedia',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.refreshAttendances,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text('Gagal Memuat Data', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              controller.error.value ?? 'Terjadi kesalahan',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.refreshAttendances,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const days = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }
}
