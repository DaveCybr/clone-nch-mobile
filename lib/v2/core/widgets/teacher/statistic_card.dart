import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/app_text_styles.dart';

class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatisticsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
