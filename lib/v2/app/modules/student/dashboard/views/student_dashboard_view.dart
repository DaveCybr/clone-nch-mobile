// lib/v2/app/modules/student/dashboard/views/student_dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/student_dashboard_controller.dart';

class StudentDashboardView extends GetView<StudentDashboardController> {
  const StudentDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Santri'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildStatistics(),
                _buildTodaySchedule(),
                _buildAttendanceSummary(),
                _buildQuickActions(),
                SizedBox(height: 80.h), // Bottom nav space
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text('Gagal Memuat Data', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              controller.error.value ?? 'Terjadi kesalahan',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: controller.loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السَّلاَمُ عَلَيْكُمْ',
            style: AppTextStyles.arabicText.copyWith(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            controller.userName,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.school, color: Colors.white70, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                'Kelas: ${controller.className}',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.event_note,
            '${controller.totalSchedulesToday}',
            'Jadwal Hari Ini',
            AppColors.primaryGreen,
          ),
          Container(height: 40.h, width: 1, color: AppColors.dividerColor),
          _buildStatItem(
            Icons.check_circle,
            '${controller.attendancePercentage.toStringAsFixed(0)}%',
            'Kehadiran',
            AppColors.attendancePresent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jadwal Hari Ini', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () {
                  // Navigate to full schedule page
                  Get.toNamed('/student/schedule');
                },
                child: Text(
                  'Lihat Semua',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (controller.schedulesToday.isEmpty)
            _buildEmptySchedule()
          else
            ...controller.schedulesToday.map(
              (schedule) => _buildScheduleCard(schedule),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48.sp, color: AppColors.textHint),
            SizedBox(height: 12.h),
            Text(
              'Tidak ada jadwal hari ini',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(schedule) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color:
                schedule.isOngoing
                    ? AppColors.attendancePresent.withOpacity(0.1)
                    : AppColors.primaryGreenLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.book,
            color:
                schedule.isOngoing
                    ? AppColors.attendancePresent
                    : AppColors.primaryGreen,
          ),
        ),
        title: Text(schedule.subjectName, style: AppTextStyles.cardTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 14.sp, color: AppColors.textHint),
                SizedBox(width: 4.w),
                Text(schedule.timeRange, style: AppTextStyles.bodySmall),
              ],
            ),
            if (schedule.teacherName != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.person, size: 14.sp, color: AppColors.textHint),
                  SizedBox(width: 4.w),
                  Text(schedule.teacherName!, style: AppTextStyles.bodySmall),
                ],
              ),
            ],
            if (schedule.room != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.room, size: 14.sp, color: AppColors.textHint),
                  SizedBox(width: 4.w),
                  Text(schedule.room!, style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ],
        ),
        trailing:
            schedule.isOngoing
                ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.attendancePresent,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Berlangsung',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kehadiran Hari Ini', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () {
                  // Navigate to attendance page
                  Get.toNamed('/student/attendance');
                },
                child: Text(
                  'Detail',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCard(
                  'Hadir',
                  controller.attendanceHadir,
                  AppColors.attendancePresent,
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAttendanceCard(
                  'Sakit',
                  controller.attendanceSakit,
                  AppColors.attendanceSick,
                  Icons.local_hospital,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCard(
                  'Izin',
                  controller.attendanceIzin,
                  AppColors.attendancePermit,
                  Icons.event_busy,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAttendanceCard(
                  'Alpha',
                  controller.attendanceAlpha,
                  AppColors.attendanceAbsent,
                  Icons.cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            count.toString(),
            style: AppTextStyles.heading1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu Cepat', style: AppTextStyles.heading3),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Jadwal Lengkap',
                  Icons.calendar_today,
                  AppColors.primaryGreen,
                  () => Get.toNamed('/student/schedule'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildQuickActionCard(
                  'Riwayat Absensi',
                  Icons.history,
                  Colors.blue,
                  () => Get.toNamed('/student/attendance'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Pengumuman',
                  Icons.campaign,
                  Colors.orange,
                  () => Get.toNamed('/student/announcements'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildQuickActionCard(
                  'Raport',
                  Icons.assessment,
                  Colors.purple,
                  () => Get.toNamed('/student/raport'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
