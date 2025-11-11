// lib/v2/app/modules/teacher/announcements/views/announcements_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildAnnouncementsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_ios, size: 20.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            'Pengumuman',
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.tune, size: 24.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      color: Colors.white,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: controller.searchAnnouncements,
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: 'Cari pengumuman...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF9E9E9E),
              fontSize: 15.sp,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF9E9E9E),
              size: 22.sp,
            ),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: const Color(0xFF9E9E9E),
                    size: 20.sp,
                  ),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.searchAnnouncements('');
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final isLoadingMore = controller.isLoadingMore.value;
      final query = controller.searchQuery.value;

      final announcements = controller.filteredAnnouncements;

      if (isLoading && controller.announcements.isEmpty) {
        return _buildLoadingState();
      }

      if (announcements.isEmpty && !isLoading) {
        return _buildEmptyState(
          query.isNotEmpty
              ? 'Tidak ada pengumuman yang sesuai dengan pencarian'
              : 'Belum ada pengumuman tersedia',
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terbaru',
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                Obx(() {
                  final unreadCount = controller.unreadCount;
                  if (unreadCount > 0) {
                    return TextButton(
                      onPressed: controller.markAllAsRead,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Tandai Semua',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          // Category Filter Chips
          _buildCategoryChips(),
          SizedBox(height: 12.h),
          // Articles List
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!isLoadingMore &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                  controller.loadMore();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: controller.refreshAnnouncements,
                color: AppColors.primaryGreen,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: announcements.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == announcements.length) {
                      return _buildLoadingMoreIndicator();
                    }
                    return _buildAnnouncementCard(announcements[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36.h,
      child: Obx(() {
        final selectedCat = controller.selectedCategory.value;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories.keys.elementAt(index);
            final categoryName = controller.categories[category]!;
            final isSelected = selectedCat == category;

            return GestureDetector(
              onTap: () => controller.filterByCategory(category),
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? _getCategoryColor(category).withOpacity(0.15)
                          : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  categoryName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isSelected
                            ? _getCategoryColor(category)
                            : const Color(0xFF616161),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    return GestureDetector(
      onTap: () => controller.viewAnnouncementDetail(announcement),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          announcement.category,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        announcement.category.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getCategoryColor(announcement.category),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // Title with unread indicator
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight:
                                  announcement.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                              color:
                                  announcement.isRead
                                      ? const Color(0xFF424242)
                                      : const Color(0xFF212121),
                              fontSize: 16.sp,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ✅ Unread indicator dot
                        if (!announcement.isRead) ...[
                          SizedBox(width: 6.w),
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Author and Time
                    Row(
                      children: [
                        Text(
                          'Admin',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF757575),
                            fontSize: 13.sp,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 8.w),
                          width: 3.w,
                          height: 3.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF757575),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          announcement.timeAgo,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF757575),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Image Section
            if (announcement.image != null && announcement.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
                child: Container(
                  width: 110.w,
                  height: 130.h,
                  color: const Color(0xFFF5F5F5),
                  child: Stack(
                    children: [
                      Image.network(
                        announcement.image!,
                        width: 110.w,
                        height: 130.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 32.sp,
                              color: const Color(0xFFBDBDBD),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                strokeWidth: 2,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          );
                        },
                      ),
                      // Priority overlay badge
                      if (announcement.isPriority)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ),
                        ),
                      // ✅ NEW badge di gambar jika unread
                      if (!announcement.isRead)
                        Positioned(
                          top: 8.h,
                          left: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'BARU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              // Placeholder if no image
              Container(
                width: 110.w,
                height: 130.h,
                decoration: BoxDecoration(
                  color: _getCategoryColor(
                    announcement.category,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getCategoryIcon(announcement.category),
                        size: 40.sp,
                        color: _getCategoryColor(
                          announcement.category,
                        ).withOpacity(0.4),
                      ),
                    ),
                    // ✅ NEW badge di placeholder jika unread
                    if (!announcement.isRead)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'BARU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Memuat pengumuman...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF757575),
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
        child: SizedBox(
          width: 24.w,
          height: 24.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.campaign_outlined,
                size: 64.sp,
                color: AppColors.primaryGreen.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF757575),
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: controller.refreshAnnouncements,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'penting':
        return const Color(0xFFE53935);
      case 'akademik':
        return const Color(0xFF1E88E5);
      case 'kegiatan':
        return const Color(0xFFFB8C00);
      case 'umum':
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'penting':
        return Icons.priority_high;
      case 'akademik':
        return Icons.school_outlined;
      case 'kegiatan':
        return Icons.event_outlined;
      case 'umum':
      default:
        return Icons.campaign_outlined;
    }
  }

  void _showFilterDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Kategori',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 20.h),
              ...controller.categories.entries.map((entry) {
                return Obx(() {
                  final isSelected =
                      controller.selectedCategory.value == entry.key;
                  return InkWell(
                    onTap: () {
                      controller.filterByCategory(entry.key);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primaryGreen.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(entry.key),
                            color:
                                isSelected
                                    ? AppColors.primaryGreen
                                    : const Color(0xFF757575),
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color:
                                    isSelected
                                        ? AppColors.primaryGreen
                                        : const Color(0xFF212121),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primaryGreen,
                              size: 20.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                });
              }),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.filterByCategory('all');
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Reset Filter',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
