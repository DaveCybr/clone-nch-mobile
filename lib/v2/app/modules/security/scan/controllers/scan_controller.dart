// lib/v2/app/modules/security/scan/controllers/security_scan_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/models/scan_result_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'dart:developer' as developer;

class SecurityScanController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Scanner controller
  late MobileScannerController scannerController;

  // State
  final isScanning = true.obs;
  final isProcessing = false.obs;
  final Rx<ScanResult?> scanResult = Rx<ScanResult?>(null);
  final errorMessage = ''.obs;

  // Flash & Camera
  final isFlashOn = false.obs;
  final isFrontCamera = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeScanner();
  }

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
  }

  void _initializeScanner() {
    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
  }

  /// Handle barcode detected
  Future<void> onBarcodeDetected(BarcodeCapture capture) async {
    // Prevent multiple scans
    if (isProcessing.value) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Process barcode
    await processScan(code);
  }

  /// Process scanned barcode
  Future<void> processScan(String barcode) async {
    try {
      isProcessing.value = true;
      isScanning.value = false;
      errorMessage.value = '';

      developer.log('Processing barcode: $barcode');

      // Scan QR Code via API
      final response = await _apiService.scanQrCode(barcode);
      developer.log('API response: $response');

      if (response['success'] == true && response['data'] != null) {
        scanResult.value = ScanResult.fromJson(response['data']);

        // Show result dialog
        _showScanResultDialog(barcode);
      } else {
        throw Exception(response['message'] ?? 'QR Code tidak valid');
      }
    } catch (e) {
      developer.log('Error processing scan: $e');
      errorMessage.value = e.toString();

      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.attendanceAbsent,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
      );

      // Resume scanning after error
      Future.delayed(const Duration(seconds: 2), () {
        resumeScanning();
      });
    } finally {
      isProcessing.value = false;
    }
  }

  /// Show scan result dialog
  void _showScanResultDialog(String barcode) {
    final result = scanResult.value;
    developer.log('Showing scan result dialog for: $result');
    if (result == null) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: Get.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Hasil Scan',
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Status', result.status),
                      SizedBox(height: 12.h),
                      _buildInfoRow('Nama Orang Tua', result.parentName),
                      SizedBox(height: 12.h),
                      _buildInfoRow('Nama Siswa', result.studentName),
                      SizedBox(height: 12.h),
                      _buildInfoRow('Kelas', result.studentClass),
                      SizedBox(height: 12.h),
                      _buildInfoRow('Tujuan', result.visitPurpose),
                      SizedBox(height: 12.h),
                      _buildInfoRow('Jadwal', result.scheduleTitle),
                      if (result.location != null) ...[
                        SizedBox(height: 12.h),
                        _buildInfoRow('Lokasi', result.location!),
                      ],
                      if (result.checkInTime != null) ...[
                        SizedBox(height: 12.h),
                        _buildInfoRow(
                          'Check In',
                          _formatDateTime(result.checkInTime!),
                        ),
                      ],
                      if (result.checkOutTime != null) ...[
                        SizedBox(height: 12.h),
                        _buildInfoRow(
                          'Check Out',
                          _formatDateTime(result.checkOutTime!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: AppColors.dividerColor),

              // Actions
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (result.canCheckIn)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            confirmCheckIn(barcode, result.parentName);
                          },
                          icon: Icon(Icons.login, size: 18.sp),
                          label: Text(
                            'Check In',
                            style: AppTextStyles.buttonText.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.attendancePresent,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    if (result.canCheckIn && result.canCheckOut)
                      SizedBox(width: 8.w),
                    if (result.canCheckOut)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            confirmCheckOut(result.visitId, result.parentName);
                          },
                          icon: Icon(Icons.logout, size: 18.sp),
                          label: Text(
                            'Check Out',
                            style: AppTextStyles.buttonText.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.attendanceSick,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    if (!result.canCheckIn && !result.canCheckOut)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            resumeScanning();
                          },
                          child: Text(
                            'Tutup',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
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
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.dividerColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Confirm check in
  Future<void> confirmCheckIn(String barcode, String parentName) async {
    try {
      Get.dialog(
        Center(
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
                Text('Memproses Check In...', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final response = await _apiService.checkInVisitor(barcode: barcode);

      Get.back(); // Close loading

      if (response['success'] == true) {
        Get.snackbar(
          'Check In Berhasil',
          response['message'] ?? 'Pengunjung berhasil check in',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.attendancePresent,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: EdgeInsets.all(16.w),
          borderRadius: 12.r,
          icon: Icon(Icons.check_circle, color: Colors.white, size: 28.sp),
        );

        // Clear result and resume scanning
        scanResult.value = null;
        Future.delayed(const Duration(seconds: 2), () {
          resumeScanning();
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal check in');
      }
    } catch (e) {
      Get.back(); // Close loading if still open
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.attendanceAbsent,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
      );
      resumeScanning();
    }
  }

  /// Confirm check out
  Future<void> confirmCheckOut(String visitId, String parentName) async {
    try {
      Get.dialog(
        Center(
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
                Text('Memproses Check Out...', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final result = scanResult.value;
      if (result == null) return;

      final response = await _apiService.checkOutVisitor(visitId: visitId);

      Get.back(); // Close loading

      if (response['success'] == true) {
        Get.snackbar(
          'Check Out Berhasil',
          response['message'] ?? 'Pengunjung berhasil check out',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.attendanceSick,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: EdgeInsets.all(16.w),
          borderRadius: 12.r,
          icon: Icon(Icons.check_circle, color: Colors.white, size: 28.sp),
        );

        // Clear result and resume scanning
        scanResult.value = null;
        Future.delayed(const Duration(seconds: 2), () {
          resumeScanning();
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal check out');
      }
    } catch (e) {
      Get.back(); // Close loading if still open
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.attendanceAbsent,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
      );
      resumeScanning();
    }
  }

  /// Resume scanning
  void resumeScanning() {
    scanResult.value = null;
    errorMessage.value = '';
    isScanning.value = true;
    isProcessing.value = false;
  }

  /// Toggle flash
  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    scannerController.toggleTorch();
  }

  /// Toggle camera
  void toggleCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    scannerController.switchCamera();
  }

  /// Manual input barcode
  void manualInputBarcode() {
    final textController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Input Barcode Manual', style: AppTextStyles.heading3),
              SizedBox(height: 16.h),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  hintText: 'Masukkan kode barcode',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Batal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () {
                      final code = textController.text.trim();
                      if (code.isNotEmpty) {
                        Get.back();
                        processScan(code);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text('Proses', style: AppTextStyles.buttonText),
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
