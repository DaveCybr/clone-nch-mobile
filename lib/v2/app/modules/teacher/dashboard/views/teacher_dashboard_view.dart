import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/islamic/prayer_time_widget.dart';
import '../../../../../core/widgets/teacher/schedule_card.dart';
import '../../../../../core/widgets/teacher/statistic_card.dart';
import '../../../../data/models/dashboard_model.dart';
import '../controllers/teacher_dashboard_controller.dart';

class TeacherDashboardView extends GetView<TeacherDashboardController> {
  const TeacherDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RefreshController refreshController = RefreshController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.dashboardData.value == null) {
          return _buildLoadingState();
        }

        return SmartRefresher(
          controller: refreshController,
          enablePullDown: true,
          header: WaterDropMaterialHeader(
            backgroundColor: AppColors.primaryGreen,
          ),
          onRefresh: () async {
            await controller.refreshDashboard();
            refreshController.refreshCompleted();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Islamic Greeting Section
                if (controller.currentUser != null) _buildGreetingSection(),

                SizedBox(height: 16.h),

                // Statistics Cards
                _buildStatisticsSection(),

                SizedBox(height: 20.h),

                // Today's Schedule
                _buildTodayScheduleSection(),

                SizedBox(height: 20.h),

                // Prayer Times & Announcements Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prayer Times (Left)
                    Expanded(flex: 1, child: _buildPrayerTimesSection()),

                    SizedBox(width: 12.w),

                    // Announcements (Right)
                    Expanded(flex: 1, child: _buildAnnouncementsSection()),
                  ],
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Dashboard'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: controller.navigateToAnnouncements,
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primaryGreen),
                      SizedBox(width: 12.w),
                      Text('Profil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12.w),
                      Text('Keluar'),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'profile') {
              controller.navigateToProfile();
            } else if (value == 'logout') {
              controller.logout();
            }
          },
        ),
      ],
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
            'جاري التحميل...',
            style: AppTextStyles.arabicText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Memuat data dashboard...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 35.r,
            backgroundColor: AppColors.goldAccent,
            backgroundImage:
                controller.currentUser!.avatarUrl.isNotEmpty
                    ? NetworkImage(controller.currentUser!.avatarUrl)
                    : null,
            child:
                controller.currentUser!.avatarUrl.isEmpty
                    ? Icon(
                      Icons.person,
                      size: 35.sp,
                      color: AppColors.primaryGreen,
                    )
                    : null,
          ),

          SizedBox(width: 16.w),

          // Greeting Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic Greeting
                Obx(
                  () => Text(
                    controller.islamicGreeting,
                    style: AppTextStyles.arabicText.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Indonesian Greeting
                Obx(
                  () => Text(
                    controller.indonesianGreeting,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // User name
                Text(
                  controller.currentUser!.displayName,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  controller.currentUser!.roleDisplay,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                SizedBox(height: 8.h),

                // Current time and date
                Obx(
                  () => Text(
                    _formatCurrentDateTime(controller.currentTime.value),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Obx(() {
      final stats = controller.dashboardData.value?.stats;
      if (stats == null) return SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik Hari Ini', style: AppTextStyles.heading3),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: StatisticsCard(
                  title: 'Santri Aktif',
                  value: '${stats.totalStudents}',
                  icon: Icons.people,
                  color: AppColors.attendancePresent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: StatisticsCard(
                  title: 'Kelas Terjadwal',
                  value: '${stats.totalClasses}',
                  icon: Icons.class_,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: StatisticsCard(
                  title: 'Tugas Dinilai',
                  value: '${stats.todayTasks}',
                  icon: Icons.assignment,
                  color: AppColors.goldAccent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: StatisticsCard(
                  title: 'Pengumuman',
                  value: '${stats.totalAnnouncements}',
                  icon: Icons.campaign,
                  color: AppColors.attendancePermit,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTodayScheduleSection() {
    return Obx(() {
      final schedules = controller.dashboardData.value?.todaySchedules ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jadwal Hari Ini', style: AppTextStyles.heading3),
              TextButton(
                onPressed: controller.navigateToSchedule,
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

          if (schedules.isEmpty)
            _buildEmptySchedule()
          else
            ...schedules.map(
              (schedule) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ScheduleCard(
                  schedule: schedule,
                  onTap: () => controller.navigateToAttendance(schedule),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 48.sp, color: AppColors.textHint),
          SizedBox(height: 12.h),
          Text(
            'لا توجد جدولة اليوم',
            style: AppTextStyles.arabicText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Tidak ada jadwal mengajar hari ini',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSection() {
    return Obx(
      () => PrayerTimeWidget(
        prayerTimes: controller.prayerTimes,
        currentIndex: controller.currentPrayerIndex.value,
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Obx(() {
      final announcements = controller.dashboardData.value?.announcements ?? [];

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.campaign,
                      color: AppColors.primaryGreen,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text('Pengumuman', style: AppTextStyles.cardTitle),
                  ],
                ),
                TextButton(
                  onPressed: controller.navigateToAnnouncements,
                  child: Text(
                    'Semua',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            if (announcements.isEmpty)
              _buildEmptyAnnouncements()
            else
              ...announcements
                  .take(3)
                  .map((announcement) => _buildAnnouncementItem(announcement)),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyAnnouncements() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 32.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 8.h),
            Text(
              'Belum ada pengumuman',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(AnnouncementModel announcement) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(8.r),
        border:
            announcement.isPriority
                ? Border.all(color: Colors.orange, width: 1)
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPriority)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'PENTING',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (announcement.isPriority) SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            announcement.content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            announcement.timeAgo,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
              fontSize: 11.sp,
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
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textHint,
        currentIndex: 0, // Dashboard is selected
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              controller.navigateToSchedule();
              break;
            case 2:
              controller.navigateToAnnouncements();
              break;
            case 3:
              controller.navigateToProfile();
              break;
          }
        },
        items: [
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

  String _formatCurrentDateTime(DateTime dateTime) {
    final months = [
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

    return '${days[dateTime.weekday]}, ${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
  }
}
