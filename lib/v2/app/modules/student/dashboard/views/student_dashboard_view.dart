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
        title: Text('Dashboard Santri'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(controller.error.value!),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadDashboard,
                  child: Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildTodaySchedule(),
                _buildAttendanceSummary(),
                _buildQuickActions(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    final user = controller.dashboardData.value?.user;
    final classInfo = controller.dashboardData.value?.classInfo;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
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
            style: AppTextStyles.arabicText.copyWith(color: Colors.white),
          ),
          SizedBox(height: 8.h),
          Text(
            user?.name ?? 'Santri',
            style: AppTextStyles.heading2.copyWith(color: Colors.white),
          ),
          SizedBox(height: 4.h),
          Text(
            'Kelas: ${classInfo?.name ?? '-'}',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jadwal Hari Ini', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () => Get.toNamed('/student/schedule'),
                child: Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...controller.schedulesToday.map(
            (schedule) => _buildScheduleCard(schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(schedule) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreenLight,
          child: Icon(Icons.book, color: AppColors.primaryGreen),
        ),
        title: Text(schedule.subjectName, style: AppTextStyles.cardTitle),
        subtitle: Text(
          '${schedule.timeRange} • ${schedule.teacherName ?? 'Ustadz/Ustadzah'}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primaryGreenLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            schedule.startTime,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kehadiran Hari Ini', style: AppTextStyles.heading3),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCard(
                  'Hadir',
                  controller.attendanceHadir,
                  AppColors.attendancePresent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAttendanceCard(
                  'Sakit',
                  controller.attendanceSakit,
                  AppColors.attendanceSick,
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
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAttendanceCard(
                  'Alpha',
                  controller.attendanceAlpha,
                  AppColors.attendanceAbsent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: AppTextStyles.heading1.copyWith(color: color),
            ),
            SizedBox(height: 4.h),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
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
                  'Pengumuman',
                  Icons.campaign,
                  () => Get.toNamed('/student/announcements'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildQuickActionCard(
                  'Raport',
                  Icons.description,
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
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primaryGreen),
              SizedBox(height: 8.h),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
