// lib/v2/app/modules/student/visit_schedule/controllers/visit_schedule_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../../../data/models/visit_schedule_model.dart';
import '../../../../routes/app_routes.dart';
import '../views/visit_qr_view.dart';
import 'dart:developer' as developer;
import 'dart:async';

class VisitScheduleController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  final isLoading = false.obs;
  final error = Rx<String?>(null);
  final upcomingVisits = <VisitLogModel>[].obs;
  final completedVisits = <VisitLogModel>[].obs;
  final activeSchedules = <VisitScheduleModel>[].obs;
  final isGeneratingQR = false.obs;

  // ✅ Track schedule IDs yang sudah punya visit
  final usedScheduleIds = <String>[].obs;

  // ✅ Lazy Loading untuk Riwayat Kunjungan
  final displayedCompletedCount = 3.obs; // Tampilkan 3 data awal
  final itemsPerPage = 3; // Load 3 data setiap kali
  final isLoadingMore = false.obs; // Status loading more
  Timer? _autoLoadTimer; // Timer untuk auto load

  // Getter untuk completed visits yang ditampilkan
  List<VisitLogModel> get displayedCompletedVisits {
    return completedVisits.take(displayedCompletedCount.value).toList();
  }

  // Check apakah masih ada data yang bisa di-load
  bool get hasMoreCompletedVisits {
    return displayedCompletedCount.value < completedVisits.length;
  }

  // Load more completed visits secara otomatis
  void loadMoreCompletedVisits() {
    if (hasMoreCompletedVisits && !isLoadingMore.value) {
      isLoadingMore.value = true;

      // Delay 1.5 detik untuk efek loading
      Future.delayed(Duration(milliseconds: 1500), () {
        displayedCompletedCount.value += itemsPerPage;
        isLoadingMore.value = false;
        developer.log(
          '📄 Auto-loaded more: ${displayedCompletedCount.value}/${completedVisits.length}',
        );

        // Trigger load berikutnya jika masih ada data
        if (hasMoreCompletedVisits) {
          _scheduleAutoLoad();
        }
      });
    }
  }

  // Schedule auto load dengan timer
  void _scheduleAutoLoad() {
    _autoLoadTimer?.cancel();
    _autoLoadTimer = Timer(Duration(milliseconds: 800), () {
      if (hasMoreCompletedVisits) {
        loadMoreCompletedVisits();
      }
    });
  }

  // Reset displayed count
  void resetDisplayedCount() {
    displayedCompletedCount.value = itemsPerPage;
    isLoadingMore.value = false;
    _autoLoadTimer?.cancel();
  }

  // Start auto loading
  void startAutoLoadCompleted() {
    if (hasMoreCompletedVisits && !isLoadingMore.value) {
      _scheduleAutoLoad();
    }
  }

  // ✅ Check if user has pending visit
  bool get hasPendingVisit => upcomingVisits.any(
    (visit) => visit.status == 'PENDING' || visit.status == 'CHECKED_IN',
  );

  @override
  void onInit() {
    super.onInit();
    loadVisitSchedules();
  }

  @override
  void onClose() {
    _autoLoadTimer?.cancel();
    super.onClose();
  }

  Future<void> loadVisitSchedules() async {
    try {
      isLoading.value = true;
      error.value = null;
      developer.log('===== LOADING VISIT SCHEDULES =====');

      final response = await _apiService.getParentVisitSchedules();
      developer.log('📋 Visit Schedules Response: $response');

      if (response['upcoming_visits'] != null) {
        final data = response['upcoming_visits'] as List;
        final allVisits =
            data.map((json) => VisitLogModel.fromJson(json)).toList();

        // ✅ PISAHKAN: Upcoming (pending/checked_in) dan Completed (checked_out/cancelled/overstay)
        upcomingVisits.value =
            allVisits.where((visit) {
              return visit.status == 'PENDING' || visit.status == 'CHECKED_IN';
            }).toList();

        completedVisits.value =
            allVisits.where((visit) {
              return visit.status == 'CHECKED_OUT' ||
                  visit.status == 'CANCELLED' ||
                  visit.status == 'OVERSTAY';
            }).toList();

        // ✅ Reset displayed count saat reload
        resetDisplayedCount();

        // ✅ TRACK schedule IDs yang sudah pernah digunakan (aktif + selesai)
        usedScheduleIds.value =
            allVisits.map((visit) => visit.visitScheduleId).toSet().toList();

        developer.log('✅ Loaded ${upcomingVisits.length} upcoming visits');
        developer.log('✅ Loaded ${completedVisits.length} completed visits');
        developer.log(
          '✅ Displaying ${displayedCompletedCount.value} completed visits initially',
        );
        developer.log(
          '✅ Used schedule IDs: ${usedScheduleIds.length} - $usedScheduleIds',
        );

        // ✅ Auto-start loading jika ada data lebih
        if (hasMoreCompletedVisits) {
          startAutoLoadCompleted();
        }
      }

      if (response['active_schedules'] != null) {
        final data = response['active_schedules'] as List;
        activeSchedules.value =
            data.map((json) => VisitScheduleModel.fromJson(json)).toList();
        developer.log('✅ Loaded ${activeSchedules.length} active schedules');
      }

      developer.log('===== SUMMARY =====');
      developer.log('Upcoming visits loaded: ${upcomingVisits.length}');
      developer.log('Completed visits loaded: ${completedVisits.length}');
      developer.log('Active schedules loaded: ${activeSchedules.length}');
      developer.log('Used schedules (hidden): ${usedScheduleIds.length}');
    } catch (e) {
      error.value = e.toString();
      developer.log('❌ Error loading schedules: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat data jadwal',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadVisitSchedules();
  }

  void navigateToQRCode(VisitLogModel visit) {
    developer.log('🎫 Navigating to QR Code: ${visit.id}');
    developer.log('Barcode: ${visit.barcode}');
    Get.to(
      () => VisitQRView(visit: visit),
      transition: Transition.rightToLeft,
      duration: Duration(milliseconds: 300),
    );
  }

  Future<void> generateQRFromSchedule(VisitScheduleModel schedule) async {
    try {
      isGeneratingQR.value = true;
      developer.log('🔄 Generating QR for schedule: ${schedule.id}');

      final studentId = _getStudentId();
      if (studentId == null || studentId.isEmpty) {
        developer.log('❌ Student ID not found');
        Get.snackbar(
          'Error',
          'Data siswa tidak ditemukan. Silakan login ulang.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isGeneratingQR.value = false;
        return;
      }

      final result = await _showVisitPurposeDialog(schedule);
      if (result == null) {
        developer.log('ℹ️ User cancelled dialog');
        isGeneratingQR.value = false;
        return;
      }

      developer.log('📤 Calling API to generate QR...');
      final response = await _apiService.generateVisitQRCode(
        scheduleId: schedule.id,
        studentId: result['student_id'],
        visitPurpose: result['visit_purpose'],
      );

      developer.log('📥 API Response: $response');

      if (response['id'] != null && response['barcode'] != null) {
        developer.log('✅ QR Code generated successfully');

        Get.snackbar(
          'Berhasil',
          'QR Code berhasil dibuat',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );

        await loadVisitSchedules();

        final visitLog = VisitLogModel(
          id: response['id'],
          visitScheduleId: schedule.id,
          studentId: response['student_id'] ?? result['student_id'],
          parentId: response['parent_id'] ?? '',
          barcode: response['barcode'],
          status: 'PENDING',
          visitPurpose: result['visit_purpose'],
          visitSchedule: schedule,
          student: StudentVisitInfo(
            id: response['student_id'] ?? result['student_id'],
            name: response['student'] ?? '',
            className: response['student_class'],
          ),
        );

        developer.log('🎫 Showing QR Code dialog');
        _showQRCodeDialog(visitLog);
      } else {
        developer.log('❌ Failed to generate QR Code');
        Get.snackbar(
          'Gagal',
          'Gagal membuat QR Code. Response tidak valid.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error: $e');
      developer.log('StackTrace: $stackTrace');

      String errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      if (e is String) errorMessage = e;

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } finally {
      isGeneratingQR.value = false;
    }
  }

  Future<Map<String, dynamic>?> _showVisitPurposeDialog(
    VisitScheduleModel schedule,
  ) async {
    final purposeController = TextEditingController();

    return await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.event, color: Colors.blue),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Daftar Kunjungan',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            schedule.dateRange,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            schedule.location,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: purposeController,
                decoration: InputDecoration(
                  labelText: 'Keperluan Kunjungan *',
                  hintText: 'Contoh: Mengantarkan barang, bertemu wali kelas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Batal')),
          ElevatedButton.icon(
            onPressed: () {
              final purpose = purposeController.text.trim();

              if (purpose.isEmpty) {
                Get.snackbar(
                  'Perhatian',
                  'Keperluan kunjungan harus diisi',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              if (purpose.length < 5) {
                Get.snackbar(
                  'Perhatian',
                  'Keperluan kunjungan minimal 5 karakter',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back(
                result: {
                  'visit_purpose': purpose,
                  'student_id': _getStudentId() ?? '',
                },
              );
            },
            icon: Icon(Icons.qr_code_2),
            label: Text('Buat QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showQRCodeDialog(VisitLogModel visit) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400.w),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.qr_code_2, color: Colors.green, size: 32.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR Code Kunjungan',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              visit.visitSchedule?.title ?? 'Kunjungan',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(visit.status),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      visit.statusText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // QR Code
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.green, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: visit.barcode,
                      version: QrVersions.auto,
                      size: 220.w,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.green,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Barcode Text - ✅ DIHAPUS, tidak ditampilkan lagi
                  // Container(
                  //   padding: EdgeInsets.symmetric(
                  //     horizontal: 12.w,
                  //     vertical: 8.h,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey[100],
                  //     borderRadius: BorderRadius.circular(8.r),
                  //   ),
                  //   child: SelectableText(
                  //     visit.barcode,
                  //     style: TextStyle(
                  //       fontFamily: 'monospace',
                  //       fontSize: 10.sp,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ),
                  // SizedBox(height: 24.h),
                  SizedBox(height: 8.h),

                  // Quick Info
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuickInfo(
                          Icons.person,
                          'Tujuan',
                          visit.student?.name ?? '-',
                        ),
                        SizedBox(height: 8.h),
                        _buildQuickInfo(
                          Icons.location_on,
                          'Lokasi',
                          visit.visitSchedule?.location ?? '-',
                        ),
                        SizedBox(height: 8.h),
                        _buildQuickInfo(
                          Icons.access_time,
                          'Waktu',
                          visit.visitSchedule?.dateRange ?? '-',
                        ),
                        SizedBox(height: 8.h),
                        _buildQuickInfo(
                          Icons.notes,
                          'Keperluan',
                          visit.visitPurpose,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Tunjukkan QR Code ini kepada petugas keamanan untuk check-in',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.back();
                            navigateToQRCode(visit);
                          },
                          icon: Icon(Icons.fullscreen, size: 18.sp),
                          label: Text('Fullscreen'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          child: Text('Tutup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildQuickInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16.sp, color: Colors.blue[700]),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _getStudentId() {
    try {
      final user = _storageService.getUser();
      if (user == null) return null;

      developer.log('🔍 Getting student ID for: ${user.name}');

      if (user.student != null) {
        developer.log('✅ Student ID: ${user.student!.id}');
        return user.student!.id;
      }

      if (user.isStudent) {
        developer.log('✅ Using user.id: ${user.id}');
        return user.id;
      }

      developer.log('❌ Student ID not found');
      return null;
    } catch (e) {
      developer.log('❌ Error getting student ID: $e');
      return null;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CHECKED_IN':
        return Colors.green;
      case 'CHECKED_OUT':
        return Colors.grey;
      case 'OVERSTAY':
        return Colors.red;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
}
