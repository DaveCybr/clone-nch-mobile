// lib/v2/app/modules/teacher/announcements/views/announcements_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/dashboard_model.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementsView extends GetView<AnnouncementsController> {
  const AnnouncementsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilter(),

          // Category Tabs
          _buildCategoryTabs(),

          // Announcements List
          Expanded(child: _buildAnnouncementsList()),
        ],
      ),
      floatingActionButton: _buildRefreshFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Pengumuman'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: controller.refreshAnnouncements,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.searchAnnouncements,
                decoration: InputDecoration(
                  hintText: 'Cari pengumuman...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                  border: InputBorder.none,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: IconButton(
              onPressed: _showFilterDialog,
              icon: Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories.keys.elementAt(index);
            final categoryName = controller.categories[category]!;
            final isSelected = controller.selectedCategory.value == category;

            return GestureDetector(
              onTap: () => controller.filterByCategory(category),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primaryGreen
                            : AppColors.dividerColor,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: Text(
                    categoryName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.announcements.isEmpty) {
        return _buildLoadingState();
      }

      final announcements = controller.filteredAnnouncements;

      if (announcements.isEmpty && !controller.isLoading.value) {
        return _buildEmptyState();
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!controller.isLoadingMore.value &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            controller.loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshAnnouncements,
          color: AppColors.primaryGreen,
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount:
                announcements.length + (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == announcements.length) {
                return _buildLoadingMoreIndicator();
              }

              return _buildAnnouncementCard(announcements[index]);
            },
          ),
        ),
      );
    });
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border:
            announcement.isPriority
                ? Border.all(color: Colors.red, width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.viewAnnouncementDetail(announcement),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority badge and category
              Row(
                children: [
                  if (announcement.isPriority)
                    Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'PENTING',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(child: SizedBox.shrink()),

                  // Category Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        announcement.category,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _getCategoryColor(
                          announcement.category,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      announcement.category.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getCategoryColor(announcement.category),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Title
              Text(
                announcement.title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8.h),

              // Content Preview
              Text(
                announcement.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12.h),

              // Image Preview if available
              if (announcement.image != null && announcement.image!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 120.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    image: DecorationImage(
                      image: NetworkImage(announcement.image!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Handle image error
                      },
                    ),
                  ),
                ),

              // Footer with time and action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: AppColors.textHint,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        announcement.timeAgo,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),

                  TextButton.icon(
                    onPressed:
                        () => controller.viewAnnouncementDetail(announcement),
                    icon: Icon(Icons.read_more, size: 16.sp),
                    label: Text('Baca Selengkapnya'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            'Memuat pengumuman...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Memuat lebih banyak...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
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
            Icon(
              Icons.campaign_outlined,
              size: 64.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد إعلانات',
              style: AppTextStyles.arabicText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            // Text(
            //   Obx(
            //     () =>
            //         controller.searchQuery.value.isNotEmpty
            //             ? 'Tidak ada pengumuman yang sesuai dengan pencarian'
            //             : 'Belum ada pengumuman tersedia',
            //   ),
            //   style: AppTextStyles.bodyMedium.copyWith(
            //     color: AppColors.textSecondary,
            //   ),
            //   textAlign: TextAlign.center,
            // ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: controller.refreshAnnouncements,
              icon: Icon(Icons.refresh),
              label: Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshFAB() {
    return Obx(
      () => FloatingActionButton(
        onPressed: controller.refreshAnnouncements,
        backgroundColor: AppColors.primaryGreen,
        child:
            controller.isLoading.value
                ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'penting':
        return Colors.red;
      case 'akademik':
        return Colors.blue;
      case 'kegiatan':
        return Colors.orange;
      case 'umum':
      default:
        return AppColors.primaryGreen;
    }
  }

  void _showFilterDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Pengumuman', style: AppTextStyles.heading3),
              SizedBox(height: 16.h),

              Text(
                'Kategori:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),

              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children:
                    controller.categories.entries.map((entry) {
                      return Obx(
                        () => FilterChip(
                          label: Text(entry.value),
                          selected:
                              controller.selectedCategory.value == entry.key,
                          onSelected: (selected) {
                            controller.filterByCategory(entry.key);
                            Get.back();
                          },
                          selectedColor: AppColors.primaryGreen.withOpacity(
                            0.2,
                          ),
                          checkmarkColor: AppColors.primaryGreen,
                        ),
                      );
                    }).toList(),
              ),

              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: Text('Batal')),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      controller.filterByCategory('all');
                      Get.back();
                    },
                    child: Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
