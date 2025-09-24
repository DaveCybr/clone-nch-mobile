// Fixed ScheduleView.dart - Resolved GetX Obx issues

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/teacher/schedule_card.dart';
import '../controllers/schedule_controller.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Jadwal Mengajar'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadWeekSchedule,
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _showCalendarPicker,
        ),
      ],
    );
  }

  Widget _buildBody() {
    // ✅ FIX: Single Obx wrapping entire body with proper observable access
    return Obx(() {
      // ✅ IMPORTANT: Access observables directly inside Obx
      final isLoading = controller.isLoading.value;

      if (isLoading) {
        return _buildLoadingState();
      }

      return Column(
        children: [
          // Day selector
          _buildDaySelector(),

          // Selected day info
          _buildSelectedDayInfo(),

          // Schedule list
          Expanded(child: _buildScheduleList()),
        ],
      );
    });
  }

  Widget _buildDaySelector() {
    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: controller.daysOfWeek.length,
        itemBuilder: (context, index) {
          // ✅ FIX: Access observables correctly within the builder
          return Obx(() {
            final selectedDay = controller.selectedDay.value;
            final isSelected = selectedDay == (index + 1);
            final isToday = DateTime.now().weekday == (index + 1);

            return GestureDetector(
              onTap: () => controller.selectDay(index),
              child: Container(
                width: 70.w,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color:
                        isToday && !isSelected
                            ? AppColors.goldAccent
                            : isSelected
                            ? AppColors.primaryGreen
                            : AppColors.dividerColor,
                    width: isToday && !isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.arabicDays[index],
                      style: AppTextStyles.arabicText.copyWith(
                        fontSize: 12.sp,
                        color:
                            isSelected ? Colors.white : AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      controller.daysOfWeek[index]
                          .substring(0, 3)
                          .toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (isToday)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.white : AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'Hari ini',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Obx(() {
        // ✅ FIX: Access observables inside this specific Obx
        final selectedDay = controller.selectedDay.value;
        final schedules = controller.selectedDaySchedules;
        final dayIndex = selectedDay - 1;
        final dayName = controller.daysOfWeek[dayIndex];

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${schedules.length} Jadwal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.schedule, color: Colors.white, size: 24.sp),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScheduleList() {
    return Obx(() {
      // ✅ FIX: Access observable inside Obx
      final schedules = controller.selectedDaySchedules;

      if (schedules.isEmpty) {
        return _buildEmptySchedule();
      }

      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: ScheduleCard(
              schedule: schedule,
              onTap: () => controller.navigateToAttendance(schedule),
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptySchedule() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64.sp, color: AppColors.textHint),
          SizedBox(height: 16.h),
          Text(
            'لا توجد جدولة',
            style: AppTextStyles.arabicText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Tidak ada jadwal pada hari ini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            'Memuat jadwal...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textHint,
        currentIndex: 1, // Schedule is selected
        onTap: (index) {
          switch (index) {
            case 0:
              Get.back(); // Back to dashboard
              break;
            case 1:
              // Already on schedule
              break;
            case 2:
              Get.toNamed('/teacher/announcements');
              break;
            case 3:
              Get.toNamed('/teacher/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Jadwal'),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Pengumuman',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _showCalendarPicker() {
    // Implement calendar picker if needed
    Get.snackbar(
      'Info',
      'Fitur kalender akan segera tersedia',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
