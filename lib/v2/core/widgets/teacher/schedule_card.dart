import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../../app/data/models/dashboard_model.dart';

class ScheduleCard extends StatelessWidget {
  final TodayScheduleModel schedule;
  final VoidCallback? onTap;

  const ScheduleCard({Key? key, required this.schedule, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                schedule.isOngoing
                    ? AppColors.primaryGreen
                    : AppColors.dividerColor,
            width: schedule.isOngoing ? 2 : 1,
          ),
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
                Expanded(
                  child: Text(
                    schedule.subjectName,
                    style: AppTextStyles.cardTitle.copyWith(
                      color:
                          schedule.isOngoing
                              ? AppColors.primaryGreen
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),

            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.class_, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  schedule.className,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.people, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text(
                  '${schedule.totalStudents} Santri',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16.sp,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      schedule.timeRange,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                if (onTap != null)
                  TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(Icons.how_to_reg, size: 16.sp),
                    label: const Text('Absensi'),
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
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (schedule.isDone) {
      chipColor = AppColors.attendancePresent;
      chipText = 'Selesai';
      chipIcon = Icons.check_circle;
    } else if (schedule.isOngoing) {
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
}
