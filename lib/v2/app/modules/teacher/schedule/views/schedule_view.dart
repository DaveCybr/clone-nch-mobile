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
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Jadwal'),
      centerTitle: true,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadMonthSchedule,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState();
      }

      return Column(
        children: [
          // Calendar Section
          _buildCalendarSection(),

          // Selected Date Schedule
          Expanded(child: _buildSelectedDateSchedule()),
        ],
      );
    });
  }

  Widget _buildCalendarSection() {
    return Container(
      color: AppColors.primaryGreen,
      child: Column(
        children: [
          // Month/Year Header with Islamic Date
          _buildMonthHeader(),

          // Calendar Grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Month Button
            IconButton(
              onPressed: () => controller.changeMonth(-1),
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),

            // Month/Year Display
            Column(
              children: [
                Text(
                  _getMonthYearText(),
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${controller.islamicMonthName} ${controller.islamicYear}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),

            // Next Month Button
            IconButton(
              onPressed: () => controller.changeMonth(1),
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Days of week header
          _buildDaysOfWeekHeader(),

          SizedBox(height: 12.h),

          // Calendar dates grid
          _buildCalendarDates(),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeekHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          controller.daysOfWeek
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCalendarDates() {
    return Obx(() {
      final currentMonth = controller.currentMonth.value;
      final firstDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month,
        1,
      );
      final lastDayOfMonth = DateTime(
        currentMonth.year,
        currentMonth.month + 1,
        0,
      );
      final firstWeekdayOfMonth = firstDayOfMonth.weekday;
      final daysInMonth = lastDayOfMonth.day;

      // Calculate grid
      final totalCells =
          ((daysInMonth + firstWeekdayOfMonth - 1) / 7).ceil() * 7;
      final weeks = (totalCells / 7).ceil();

      return Column(
        children: List.generate(weeks, (weekIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (dayIndex) {
              final cellIndex = weekIndex * 7 + dayIndex;
              final dayNumber = cellIndex - firstWeekdayOfMonth + 2;

              // Check if this cell should show a date
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: SizedBox(height: 45.h));
              }

              final date = DateTime(
                currentMonth.year,
                currentMonth.month,
                dayNumber,
              );
              final hasSchedule = controller.hasSchedule(date);
              final isSelected =
                  controller.selectedDate.value.day == dayNumber &&
                  controller.selectedDate.value.month == currentMonth.month &&
                  controller.selectedDate.value.year == currentMonth.year;
              final isToday = _isToday(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectDate(date),
                  child: Container(
                    height: 45.h,
                    margin: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.goldAccent
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(22.r),
                      border:
                          isToday && !isSelected
                              ? Border.all(
                                color: AppColors.goldAccent,
                                width: 1,
                              )
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.white,
                            fontWeight:
                                isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        SizedBox(height: 2.h),
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
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      );
    });
  }

  Widget _buildSelectedDateSchedule() {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Obx(() {
        final selectedDate = controller.selectedDate.value;
        final schedules = controller.selectedDateSchedules;

        return Column(
          children: [
            // Selected Date Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSelectedDateTitle(selectedDate),
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (schedules.isNotEmpty)
                    Text(
                      '${schedules.length} jadwal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Schedule List
            Expanded(
              child:
                  schedules.isEmpty
                      ? _buildNoScheduleState()
                      : _buildScheduleList(schedules),
            ),
          ],
        );
      }),
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: AppColors.primaryGreen, width: 4.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    schedule.timeSlot,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (schedule.isDone)
                  Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
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

            // Class Info
            Row(
              children: [
                Icon(Icons.class_, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  schedule.className,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.navigateToAttendance(schedule),
                icon: Icon(Icons.how_to_reg, size: 18.sp),
                label: Text('Buka Absensi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
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

  Widget _buildNoScheduleState() {
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
              'Tidak ada jadwal pada tanggal ini',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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

  String _getMonthYearText() {
    final currentMonth = controller.currentMonth.value;
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${months[currentMonth.month]} ${currentMonth.year}';
  }

  String _getSelectedDateTitle(DateTime date) {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return 'Jadwal ${days[date.weekday]}, ${date.day} ${_getMonthName(date.month)}';
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month];
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }
}
