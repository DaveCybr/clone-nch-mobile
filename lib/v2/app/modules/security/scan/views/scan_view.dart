// lib/v2/app/modules/security/scan/views/security_scan_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/scan_controller.dart';

class SecurityScanView extends GetView<SecurityScanController> {
  const SecurityScanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Scan QR Code',
          style: AppTextStyles.appBarTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 24.sp,
              ),
              onPressed: controller.toggleFlash,
              tooltip: 'Flash',
            ),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24.sp),
            onPressed: controller.toggleCamera,
            tooltip: 'Switch Camera',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          Obx(() {
            if (!controller.isScanning.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Memulai kamera...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return MobileScanner(
              controller: controller.scannerController,
              onDetect: controller.onBarcodeDetected,
            );
          }),

          // Scan Overlay
          _buildScanOverlay(),

          // Processing Indicator
          Obx(() {
            if (controller.isProcessing.value) {
              return Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 40.w),
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Memproses...',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Mohon tunggu sebentar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Bottom Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Arahkan kamera ke QR Code',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 250.w,
        height: 250.w,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Stack(
          children: [
            // Top-left corner
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryGreen, width: 4),
                    left: BorderSide(color: AppColors.primaryGreen, width: 4),
                  ),
                ),
              ),
            ),
            // Top-right corner
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.primaryGreen, width: 4),
                    right: BorderSide(color: AppColors.primaryGreen, width: 4),
                  ),
                ),
              ),
            ),
            // Bottom-left corner
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryGreen, width: 4),
                    left: BorderSide(color: AppColors.primaryGreen, width: 4),
                  ),
                ),
              ),
            ),
            // Bottom-right corner
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primaryGreen, width: 4),
                    right: BorderSide(color: AppColors.primaryGreen, width: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
