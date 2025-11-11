// lib/v2/app/modules/teacher/schedule/views/schedule_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/schedule_controller.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScheduleController>(
      init: ScheduleController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: _buildAppBar(),
          body: _buildBody(),
          // bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Jadwal Mengajar'),
      centerTitle: true,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Loading state check
        Obx(() {
          if (controller.isLoading.value) {
            return Expanded(child: _buildLoadingState());
          }
          return const SizedBox.shrink();
        }),

        // Main content - only show when not loading
        Obx(
          () =>
              controller.isLoading.value
                  ? const SizedBox.shrink()
                  : Expanded(
                    child: Column(
                      children: [
                        // Week Navigation Header
                        _buildWeekHeader(),

                        // Days of Week Tabs
                        _buildDayTabs(),

                        // Selected Day Schedule
                        Expanded(child: _buildSelectedDaySchedule()),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      color: AppColors.primaryGreen,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Week Button
          IconButton(
            onPressed: () => controller.changeWeek(-1),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),

          // Week Range Display
          Expanded(
            child: Column(
              children: [
                Text(
                  'Minggu Ini',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  controller.weekRangeText,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Next Week Button
          IconButton(
            onPressed: () => controller.changeWeek(1),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      color: AppColors.primaryGreen,
      child: Container(
        height: 70.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.daysOfWeek.length,
          itemBuilder: (context, index) {
            final day = controller.daysOfWeek[index];
            final dayDisplay = controller.dayDisplayNames[index];
            final dayDate = controller.getDateForDay(day);
            final isToday = _isToday(dayDate);

            return Obx(() {
              final isSelected = controller.selectedDay.value == day;
              final hasSchedule = controller.hasSchedule(day);

              return GestureDetector(
                onTap: () => controller.selectDay(day),
                child: Container(
                  width: 80.w,
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.goldAccent
                            : isToday
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    border:
                        isToday && !isSelected
                            ? Border.all(color: Colors.white.withOpacity(0.5))
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayDisplay,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.white,
                          fontWeight:
                              isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${dayDate.day}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Schedule indicator
                      if (hasSchedule)
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.goldAccent,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        SizedBox(height: 6.h),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDaySchedule() {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Column(
        children: [
          // Selected Day Header
          Obx(() {
            final selectedDay = controller.selectedDay.value;
            final selectedDayDisplay = controller.getDayDisplayName(
              selectedDay,
            );
            final schedules = controller.selectedDaySchedules;
            final selectedDate = controller.getDateForDay(selectedDay);

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primaryGreen,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Jadwal $selectedDayDisplay',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(selectedDate),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (schedules.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${schedules.length} jadwal',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Schedule List
          Expanded(
            child: Obx(() {
              final selectedDay = controller.selectedDay.value;
              final selectedDayDisplay = controller.getDayDisplayName(
                selectedDay,
              );
              final schedules = controller.selectedDaySchedules;

              return schedules.isEmpty
                  ? _buildNoScheduleState(selectedDayDisplay)
                  : _buildScheduleList(schedules);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List schedules) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    final isOngoing = _isScheduleOngoing(schedule);
    final isDone = schedule.isDone;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
            color:
                isDone
                    ? AppColors
                        .attendancePresent // Green for done
                    : isOngoing
                    ? AppColors.goldAccent
                    : AppColors.primaryGreen,
            width: 4.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(schedule, isOngoing, isDone),
              ],
            ),

            SizedBox(height: 12.h),

            // Subject Name
            Text(
              schedule.subjectName,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8.h),

            // Class and Student Info
            Row(
              children: [
                Icon(Icons.class_, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    schedule.className,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.people, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  '${schedule.totalStudents} santri',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Action Button - Change text based on isDone
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.navigateToAttendance(schedule),
                icon: Icon(isDone ? Icons.edit : Icons.how_to_reg, size: 18.sp),
                label: Text(
                  isDone ? 'Edit Absensi' : 'Buka Absensi',
                ), // ✅ Change label
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOngoing ? AppColors.goldAccent : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(dynamic schedule, bool isOngoing, bool isDone) {
    Color chipColor;
    String chipText;
    IconData chipIcon;

    // Priority: Done > Ongoing > Waiting
    if (isDone || schedule.isDone) {
      // ✅ Check schedule.isDone from backend
      chipColor = AppColors.attendancePresent;
      chipText = 'Selesai';
      chipIcon = Icons.check_circle;
    } else if (isOngoing) {
      chipColor = AppColors.goldAccent;
      chipText = 'Berlangsung';
      chipIcon = Icons.play_circle;
    } else {
      chipColor = AppColors.textHint;
      chipText = 'Menunggu';
      chipIcon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 12.sp, color: chipColor),
          SizedBox(width: 4.w),
          Text(
            chipText,
            style: AppTextStyles.bodySmall.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoScheduleState(String dayName) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
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
            SizedBox(height: 8.h),
            Text(
              'Tidak ada jadwal pada hari $dayName',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: controller.loadWeeklySchedule,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الجدول...',
            style: AppTextStyles.arabicText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Memuat jadwal mengajar...',
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
              Get.rootDelegate.offNamed('/teacher/announcements');
              break;
            case 3:
              Get.rootDelegate.offNamed('/teacher/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Pengumuman',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool _isScheduleOngoing(dynamic schedule) {
    try {
      final now = TimeOfDay.now();
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);
      return _isTimeBetween(now, start, end);
    } catch (e) {
      return false;
    }
  }

  bool _isScheduleDone(dynamic schedule) {
    try {
      final now = TimeOfDay.now();
      final end = _parseTime(schedule.endTime);
      final currentMinutes = now.hour * 60 + now.minute;
      final endMinutes = end.hour * 60 + end.minute;
      return currentMinutes > endMinutes;
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      // Return current time as fallback
    }
    return TimeOfDay.now();
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  String _formatDate(DateTime date) {
    final days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final months = [
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

    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }
}
