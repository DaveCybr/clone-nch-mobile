// lib/v2/app/modules/student/schedule/views/student_schedule_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/student_schedule_controller.dart';

class StudentScheduleView extends GetView<StudentScheduleController> {
  const StudentScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: controller.goToToday,
            tooltip: 'Hari Ini',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => controller.pickDate(context),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value != null) {
                return _buildErrorState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshSchedules,
                child: _buildScheduleList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.previousDay,
              color: AppColors.primaryGreen,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    controller.formattedSelectedDate,
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  ),
                  if (controller.isToday)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Hari Ini',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: controller.nextDay,
              color: AppColors.primaryGreen,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScheduleList() {
    return Obx(() {
      if (controller.schedules.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.schedules.length,
        itemBuilder: (context, index) {
          final schedule = controller.schedules[index];
          return _buildScheduleCard(schedule, index);
        },
      );
    });
  }

  Widget _buildScheduleCard(schedule, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time indicator
            Container(
              width: 60.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color:
                    schedule.isOngoing
                        ? AppColors.attendancePresent.withOpacity(0.1)
                        : AppColors.primaryGreenLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Text(
                    schedule.startTime,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          schedule.isOngoing
                              ? AppColors.attendancePresent
                              : AppColors.primaryGreen,
                    ),
                  ),
                  Divider(height: 4.h),
                  Text(
                    schedule.endTime,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Schedule details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.subjectName,
                          style: AppTextStyles.cardTitle,
                        ),
                      ),
                      if (schedule.isOngoing)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.attendancePresent,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Berlangsung',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (schedule.teacherName != null)
                    _buildInfoRow(Icons.person_outline, schedule.teacherName!),
                  if (schedule.room != null)
                    _buildInfoRow(Icons.room_outlined, schedule.room!),
                  if (schedule.notes != null)
                    _buildInfoRow(
                      Icons.info_outline,
                      schedule.notes!,
                      color: Colors.orange,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color ?? AppColors.textHint),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: color ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
            Icon(Icons.event_available, size: 80.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text('Tidak Ada Jadwal', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              'Tidak ada jadwal pelajaran\npada tanggal yang dipilih',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.goToToday,
              icon: const Icon(Icons.today),
              label: const Text('Kembali ke Hari Ini'),
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
            Text('Gagal Memuat Jadwal', style: AppTextStyles.heading3),
            SizedBox(height: 8.h),
            Text(
              controller.error.value ?? 'Terjadi kesalahan',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.refreshSchedules,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
