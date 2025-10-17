// Fixed TeacherDashboardView.dart - BottomNav DIHAPUS (dihandle oleh parent)

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
      body: _buildBody(refreshController, context),
      // ✅ DIHAPUS - BottomNav dihandle oleh parent widget
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: controller.navigateToAnnouncements,
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, color: AppColors.primaryGreen),
                      SizedBox(width: 12.w),
                      const Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(width: 12.w),
                      const Text('Profil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12.w),
                      const Text('Keluar'),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                controller.refreshDashboard();
                break;
              case 'profile':
                controller.navigateToProfile();
                break;
              case 'logout':
                controller.logout();
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody(RefreshController refreshController, context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final dashboardData = controller.dashboardData.value;

      if (isLoading && dashboardData == null) {
        return _buildLoadingState();
      }

      return SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        header: const WaterDropMaterialHeader(
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
              if (controller.currentUser != null) _buildGreetingSection(),
              SizedBox(height: 16.h),
              _buildStatisticsSection(),
              SizedBox(height: 20.h),
              _buildTodayScheduleSection(context),
              SizedBox(height: 20.h),
              _buildPrayerTimesSection(),
              SizedBox(height: 20.h),
              _buildAnnouncementsSection(),
              SizedBox(
                height: 80.h,
              ), // Extra space untuk bottom nav dari parent
            ],
          ),
        ),
      );
    });
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.islamicGreeting.value,
                    style: AppTextStyles.arabicText.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Obx(
                  () => Text(
                    controller.indonesianGreeting.value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
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
    final stats = controller.dashboardData.value?.stats;
    if (stats == null) return _buildStatisticsSkeleton();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rekap Aktivitas', style: AppTextStyles.heading3),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: StatisticsCard(
                title: 'Santri Aktif',
                value: '${stats.totalStudents}',
                icon: Icons.people,
                color: AppColors.attendancePresent,
                onTap: controller.navigateToStudents,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatisticsCard(
                title: 'Kelas Terjadwal',
                value: '${stats.totalClasses}',
                icon: Icons.class_,
                color: AppColors.primaryGreen,
                onTap: controller.navigateToSchedule,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistik Hari Ini', style: AppTextStyles.heading3),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            SizedBox(width: 12.w),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 100.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _buildTodayScheduleSection(BuildContext context) {
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
        if (schedules.isEmpty)
          _buildEmptySchedule(context)
        else
          ...schedules.map(
            (schedule) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ScheduleCard(
                schedule: schedule,
                onTap: () => controller.showScheduleOptions(schedule),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySchedule(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.dividerColor),
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
            offset: const Offset(0, 4),
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
          if (announcement.isPriority)
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
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
          Text(
            announcement.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (announcement.content.isNotEmpty)
            Text(
              announcement.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
