// lib/v2/app/modules/teacher/announcements/views/announcement_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../data/models/dashboard_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailView({Key? key, required this.announcement})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                _buildContentSection(),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: EdgeInsets.only(left: 8.w),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF212121),
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: const Color(0xFF212121),
            size: 24.sp,
          ),
          onPressed: _shareAnnouncement,
        ),
        IconButton(
          icon: Icon(
            Icons.bookmark_border,
            color: const Color(0xFF212121),
            size: 24.sp,
          ),
          onPressed: () {
            // Bookmark functionality
            Get.snackbar(
              'Tersimpan',
              'Pengumuman disimpan ke bookmark',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primaryGreen,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: EdgeInsets.all(16.w),
              borderRadius: 12.r,
            );
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildImageSection() {
    if (announcement.image == null || announcement.image!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showFullImage,
      child: Hero(
        tag: 'announcement-image-${announcement.id}',
        child: Container(
          width: double.infinity,
          height: 280.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            child: Image.network(
              announcement.image!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 64.sp,
                        color: const Color(0xFFBDBDBD),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    color: AppColors.primaryGreen,
                    strokeWidth: 3,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _getCategoryColor(announcement.category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              announcement.category.toUpperCase(),
              style: TextStyle(
                color: _getCategoryColor(announcement.category),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Title
          Text(
            announcement.title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 20.h),

          // Author and Time Info
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primaryGreen,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Sekolah',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          announcement.timeAgo,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF757575),
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
                          '16 Comments',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Priority Badge
              if (announcement.isPriority)
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                ),
            ],
          ),

          SizedBox(height: 28.h),

          // Content
          _isHtmlContent(announcement.content)
              ? Html(
                data: announcement.content,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(16.sp),
                    lineHeight: LineHeight.number(1.7),
                    color: const Color(0xFF424242),
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 16),
                    fontSize: FontSize(16.sp),
                    lineHeight: LineHeight.number(1.7),
                    color: const Color(0xFF424242),
                  ),
                  "h1": Style(
                    fontSize: FontSize(24.sp),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(bottom: 12, top: 20),
                    color: const Color(0xFF212121),
                  ),
                  "h2": Style(
                    fontSize: FontSize(22.sp),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(bottom: 10, top: 16),
                    color: const Color(0xFF212121),
                  ),
                  "h3": Style(
                    fontSize: FontSize(20.sp),
                    fontWeight: FontWeight.bold,
                    margin: Margins.only(bottom: 8, top: 12),
                    color: const Color(0xFF212121),
                  ),
                  "strong": Style(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
                  "em": Style(fontStyle: FontStyle.italic),
                  "ul": Style(
                    margin: Margins.only(bottom: 16, left: 20),
                    padding: HtmlPaddings.zero,
                  ),
                  "ol": Style(
                    margin: Margins.only(bottom: 16, left: 20),
                    padding: HtmlPaddings.zero,
                  ),
                  "li": Style(
                    margin: Margins.only(bottom: 8),
                    fontSize: FontSize(16.sp),
                    lineHeight: LineHeight.number(1.6),
                  ),
                  "a": Style(
                    color: AppColors.primaryGreen,
                    textDecoration: TextDecoration.underline,
                  ),
                  "blockquote": Style(
                    margin: Margins.symmetric(vertical: 16),
                    padding: HtmlPaddings.only(left: 16),
                    border: Border(
                      left: BorderSide(color: AppColors.primaryGreen, width: 4),
                    ),
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                },
              )
              : Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF424242),
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ),

          SizedBox(height: 32.h),

          // Divider
          Divider(color: const Color(0xFFE0E0E0), thickness: 1),

          SizedBox(height: 24.h),

          // Info Footer
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengumuman Penting',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Harap dibaca dan dipahami dengan baik',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isHtmlContent(String content) {
    return content.contains('<') &&
        content.contains('>') &&
        (content.contains('<p>') ||
            content.contains('<div>') ||
            content.contains('<span>') ||
            content.contains('<h1>') ||
            content.contains('<h2>') ||
            content.contains('<h3>') ||
            content.contains('<strong>') ||
            content.contains('<em>') ||
            content.contains('<ul>') ||
            content.contains('<ol>'));
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

  void _shareAnnouncement() {
    // Share functionality
    Get.snackbar(
      'Bagikan',
      'Fitur bagikan akan segera tersedia',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF424242),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
    );
  }

  void _showFullImage() {
    if (announcement.image == null || announcement.image!.isEmpty) return;

    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: 'announcement-image-${announcement.id}',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      announcement.image!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 64.sp,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Close Button
              Positioned(
                top: 16.h,
                left: 16.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
              // Download Button
              Positioned(
                top: 16.h,
                right: 16.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.download_outlined,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      Get.snackbar(
                        'Download',
                        'Gambar akan diunduh',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.white,
                        colorText: Colors.black,
                        margin: EdgeInsets.all(16.w),
                        borderRadius: 12.r,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      transition: Transition.fade,
      fullscreenDialog: true,
    );
  }
}
