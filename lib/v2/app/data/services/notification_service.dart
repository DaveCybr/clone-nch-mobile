// lib/v2/app/data/services/notification_service.dart
// FIXED VERSION - Using NavigationService

import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/services/navigations_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import '../../routes/app_routes.dart';
import 'dart:convert';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final notificationCount = 0.obs;
  final notifications = <NotificationModel>[].obs;

  final Rxn<PendingNotificationData> pendingNotification =
      Rxn<PendingNotificationData>();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNotifications();
    await _requestPermissions();
    await _setupFirebaseMessaging();
  }

  Future<void> _initializeNotifications() async {
    try {
      developer.log('📱 Initializing local notifications...');

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      developer.log('✅ Local notifications initialized');
    } catch (e) {
      developer.log('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        developer.log('✅ Notification permission granted');

        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        developer.log('📱 FCM Permission: ${settings.authorizationStatus}');
      } else {
        developer.log('⚠️ Notification permission denied');
      }
    } catch (e) {
      developer.log('❌ Error requesting permissions: $e');
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      final token = await _firebaseMessaging.getToken();
      developer.log('🔑 FCM Token: $token');

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      developer.log('✅ Firebase Messaging setup complete');
    } catch (e) {
      developer.log('❌ Error setting up FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('📨 Foreground message received');
    developer.log('Title: ${message.notification?.title}');
    developer.log('Body: ${message.notification?.body}');
    developer.log('Data: ${message.data}');

    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }

    _addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    developer.log('📨 Background message opened');
    developer.log('Data: ${message.data}');

    Future.delayed(const Duration(milliseconds: 1500), () {
      _processNotificationData(message.data);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    developer.log('👆 ===== LOCAL NOTIFICATION TAPPED =====');
    developer.log('📦 Payload: ${response.payload}');

    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _processNotificationData(data);
        }
      } catch (e) {
        developer.log('❌ Error processing notification tap: $e');
      }
    });
  }

  void _processNotificationData(Map<String, dynamic> data) {
    try {
      developer.log('📄 ===== PROCESSING NOTIFICATION DATA =====');
      developer.log('📦 Full Data: $data');
      developer.log('🔑 Data Keys: ${data.keys.toList()}');

      if (!Get.isRegistered<StorageService>()) {
        developer.log('⚠️ StorageService not ready, retrying...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _processNotificationData(data);
        });
        return;
      }

      final user = Get.find<StorageService>().getUser();
      if (user == null) {
        developer.log('❌ User not found');
        return;
      }

      final isTeacher = user.isTeacher ?? false;
      final rawType = data['type'];
      final type = (rawType ?? '').toString().toLowerCase().trim();

      developer.log('👤 Is Teacher: $isTeacher');
      developer.log('📋 Processed Type: "$type"');

      switch (type) {
        case 'payment_reminder':
        case 'payment':
        case 'payment_success':
        case 'tagihan':
          developer.log('✅ Matched: payment type');
          _handlePaymentNotification(data);
          break;

        case 'berita':
        case 'berita_update':
        case 'announcement':
        case 'pengumuman':
          developer.log('✅ Matched: announcement type');
          _handleAnnouncementNotification(isTeacher, data);
          break;

        case 'visit':
        case 'kunjungan':
        case 'parent':
        case 'parent_visit':
        case 'visit_schedule':
        case 'jadwal_kunjungan':
          developer.log('✅ Matched: visit type');
          _handleVisitNotification(data);
          break;

        case 'attendance':
        case 'absensi':
          developer.log('✅ Matched: attendance type');
          _handleAttendanceNotification(isTeacher);
          break;

        case 'schedule':
        case 'jadwal':
          developer.log('✅ Matched: schedule type');
          _handleScheduleNotification(isTeacher);
          break;

        default:
          developer.log('⚠️ ===== ENTERED DEFAULT CASE =====');
          developer.log('❌ No match for type: "$type"');

          if (type.contains('payment') || type.contains('tagihan')) {
            developer.log('🎯 Forcing payment handler based on keyword match');
            _handlePaymentNotification(data);
          } else {
            developer.log('🏠 Navigating to dashboard');
            // ✅ FIXED: Use NavigationService
            if (isTeacher) {
              NavigationService.to.toBottomNavTab(Routes.TEACHER_DASHBOARD);
            } else {
              NavigationService.to.toBottomNavTab(Routes.STUDENT_DASHBOARD);
            }
          }
      }
    } catch (e, stackTrace) {
      developer.log('❌ ===== ERROR IN _processNotificationData =====');
      developer.log('❌ Error: $e');
      developer.log('❌ Stack: $stackTrace');
    }
  }

  /// ✅ Handle payment notification
  void _handlePaymentNotification(Map<String, dynamic> data) {
    try {
      developer.log('💰 ===== HANDLING PAYMENT NOTIFICATION =====');
      developer.log('📦 Data: $data');

      final paymentId = data['payment_id']?.toString();
      final studentId = data['student_id']?.toString();
      final amount = data['amount']?.toString();
      final month = data['month']?.toString();
      final year = data['year']?.toString();
      final dueDate = data['due_date']?.toString();

      developer.log('💳 Payment ID: $paymentId');
      developer.log('👤 Student ID: $studentId');
      developer.log('💵 Amount: $amount');

      // ✅ FIXED: Navigate to student dashboard using NavigationService
      NavigationService.to.toBottomNavTab(Routes.STUDENT_DASHBOARD);

      // Then show payment detail dialog
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '⏰ Pengingat Tagihan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (amount != null) ...[
                      const Text(
                        'Jumlah Tagihan:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatCurrency(amount)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (month != null && year != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text('Periode: ${_getMonthName(month)} $year'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (dueDate != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jatuh Tempo: ${_formatDate(dueDate)}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Mohon segera lakukan pembayaran sebelum jatuh tempo.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Nanti'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.snackbar(
                      'Info',
                      'Hubungi bagian keuangan untuk melakukan pembayaran',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      duration: const Duration(seconds: 3),
                    );
                  },
                  icon: const Icon(Icons.payment, size: 20),
                  label: const Text('Bayar Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            barrierDismissible: false,
          );

          developer.log('✅ Payment notification dialog shown');
        } catch (e, stackTrace) {
          developer.log('❌ Error showing payment dialog: $e');
          developer.log('Stack: $stackTrace');

          Get.snackbar(
            '⏰ Pengingat Tagihan',
            amount != null
                ? 'Anda memiliki tagihan sebesar Rp ${_formatCurrency(amount)}'
                : 'Anda memiliki tagihan yang belum dibayar',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange[100],
            colorText: Colors.black87,
          );
        }
      });
    } catch (e, stackTrace) {
      developer.log('❌ Error handling payment notification: $e');
      developer.log('Stack: $stackTrace');
    }
  }

  /// ✅ FIXED: Handle announcement notification
  void _handleAnnouncementNotification(
    bool isTeacher,
    Map<String, dynamic> data,
  ) {
    developer.log('📰 ===== DEBUG ANNOUNCEMENT DATA =====');
    developer.log('📰 All data keys: ${data.keys.toList()}');
    developer.log('📰 Full data: $data');

    final identifier =
        data['berita_id']?.toString() ??
        data['announcement_id']?.toString() ??
        data['id']?.toString() ??
        data['slug']?.toString();

    developer.log('📰 Handling announcement notification');
    developer.log('🔗 Identifier: $identifier');

    if (identifier != null && identifier.isNotEmpty) {
      pendingNotification.value = PendingNotificationData(
        identifier: identifier,
        shouldOpenDetail: true,
        timestamp: DateTime.now(),
      );
      developer.log('💾 Saved to Rx: $identifier');

      _navigateToAnnouncementDetail(isTeacher, identifier);
    } else {
      _navigateToAnnouncementsList(isTeacher);
    }
  }

  /// ✅ FIXED: Handle visit notification
  void _handleVisitNotification(Map<String, dynamic> data) {
    try {
      developer.log('🚪 ===== HANDLING VISIT NOTIFICATION =====');
      developer.log('📦 Data: $data');

      final scheduleId =
          data['visit_schedule_id']?.toString() ??
          data['schedule_id']?.toString() ??
          data['id']?.toString();

      developer.log('🔑 Schedule ID: $scheduleId');

      // ✅ FIXED: Navigate to student visit tab
      NavigationService.to.toBottomNavTab(Routes.STUDENT_VISIT);

      // If schedule ID exists, controller will handle opening detail
      if (scheduleId != null && scheduleId.isNotEmpty) {
        developer.log('📌 Schedule ID to open: $scheduleId');
        // TODO: Pass schedule ID to visit page via arguments if needed
      }

      developer.log('✅ Navigation to visit schedule executed');
    } catch (e, stackTrace) {
      developer.log('❌ Error handling visit notification: $e');
      developer.log('Stack: $stackTrace');
    }
  }

  /// ✅ FIXED: Handle attendance notification
  void _handleAttendanceNotification(bool isTeacher) {
    developer.log('✅ Navigating to attendance');

    if (isTeacher) {
      // ✅ Teacher attendance = fullscreen
      NavigationService.to.toFullscreen(Routes.TEACHER_ATTENDANCE);
    } else {
      // ✅ Student attendance = tab
      NavigationService.to.toBottomNavTab(Routes.STUDENT_ATTENDANCE);
    }
  }

  /// ✅ FIXED: Handle schedule notification
  void _handleScheduleNotification(bool isTeacher) {
    developer.log('📅 Navigating to schedule');

    // ✅ Both teacher and student schedule are tabs
    if (isTeacher) {
      NavigationService.to.toBottomNavTab(Routes.TEACHER_SCHEDULE);
    } else {
      NavigationService.to.toBottomNavTab(Routes.STUDENT_SCHEDULE);
    }
  }

  /// ✅ FIXED: Navigate to announcement detail
  void _navigateToAnnouncementDetail(bool isTeacher, String identifier) {
    try {
      developer.log('🎯 ===== NAVIGATING TO ANNOUNCEMENT DETAIL =====');
      developer.log('🔗 Identifier: $identifier');

      pendingNotification.value = PendingNotificationData(
        identifier: identifier,
        shouldOpenDetail: true,
        timestamp: DateTime.now(),
      );
      developer.log('💾 Saved to Rx: $identifier');

      // ✅ FIXED: Navigate properly based on route type
      if (isTeacher) {
        // Teacher announcements = fullscreen
        NavigationService.to.toFullscreen(
          Routes.TEACHER_ANNOUNCEMENTS,
          arguments: {
            'from_notification': true,
            'identifier': identifier,
            'openDetail': true,
          },
        );
      } else {
        // Student announcements = tab
        NavigationService.to.toBottomNavTab(Routes.STUDENT_ANNOUNCEMENTS);
        // Controller will handle opening detail based on pendingNotification
      }

      developer.log('✅ Navigation executed');
    } catch (e, stackTrace) {
      developer.log('❌ Error navigating: $e');
      developer.log('Stack: $stackTrace');

      _navigateToAnnouncementsList(isTeacher);
    }
  }

  /// ✅ FIXED: Navigate to announcements list
  void _navigateToAnnouncementsList(bool isTeacher) {
    try {
      developer.log('📰 Navigating to announcements list');

      // ✅ FIXED: Proper navigation based on route type
      if (isTeacher) {
        // Teacher announcements = fullscreen
        NavigationService.to.toFullscreen(Routes.TEACHER_ANNOUNCEMENTS);
      } else {
        // Student announcements = tab
        NavigationService.to.toBottomNavTab(Routes.STUDENT_ANNOUNCEMENTS);
      }
    } catch (e) {
      developer.log('❌ Error navigating to list: $e');
    }
  }

  // ===== HELPER METHODS =====

  String _formatCurrency(String amount) {
    try {
      final number = int.tryParse(amount) ?? 0;
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      return amount;
    }
  }

  String _getMonthName(String month) {
    const monthNames = [
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

    try {
      final monthNum = int.tryParse(month);
      if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
        return monthNames[monthNum];
      }
    } catch (e) {
      // ignore
    }

    return month;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return dateStr;

      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // ===== PUBLIC METHODS =====

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'nch_channel_id',
        'NCH Notifications',
        channelDescription: 'Notification channel for NCH Mobile App',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2E7D32),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      notificationCount.value++;
      developer.log('✅ Notification shown: $title');
    } catch (e) {
      developer.log('❌ Error showing notification: $e');
    }
  }

  Future<void> showTestNotification() async {
    await showNotification(
      title: '🕌 Assalamu\'alaikum',
      body: 'Ini adalah test notifikasi dari My NCH. جزاك الله خيرا',
      payload: jsonEncode({'type': 'berita', 'berita_id': 'test123'}),
    );
  }

  Future<void> showTestVisitNotification() async {
    await showNotification(
      title: '🚪 Jadwal Kunjungan Baru',
      body: 'Ada jadwal kunjungan baru tersedia. Silakan cek aplikasi.',
      payload: jsonEncode({
        'type': 'parent_visit',
        'visit_schedule_id': 'test-schedule-123',
        'title': 'Kunjungan Rutin',
      }),
    );
  }

  Future<void> showTestPaymentNotification() async {
    developer.log('🧪 ===== CREATING TEST PAYMENT NOTIFICATION =====');

    final testPayload = {
      'type': 'payment_reminder',
      'payment_id': 'test-payment-123',
      'student_id': 'test-student-456',
      'amount': '500000',
      'month': '11',
      'year': '2025',
      'due_date': '2025-11-15',
    };

    developer.log('📦 Test Payload: $testPayload');

    await showNotification(
      title: '💰 Pengingat Tagihan',
      body: 'Anda memiliki tagihan SPP bulan November sebesar Rp 500.000',
      payload: jsonEncode(testPayload),
    );

    developer.log('✅ Test payment notification created and shown');
  }

  void testProcessPaymentData() {
    developer.log('🧪 ===== TESTING DIRECT PAYMENT DATA PROCESSING =====');

    final testData = {
      'type': 'payment_reminder',
      'payment_id': 'direct-test-789',
      'student_id': 'test-student-999',
      'amount': '750000',
      'month': '12',
      'year': '2025',
      'due_date': '2025-12-10',
    };

    developer.log('📦 Calling _processNotificationData with: $testData');
    _processNotificationData(testData);
  }

  void _addNotification(NotificationModel notification) {
    notifications.insert(0, notification);
    notificationCount.value = notifications.where((n) => !n.isRead).length;
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      notificationCount.value = notifications.where((n) => !n.isRead).length;
    }
  }

  void clearAllNotifications() {
    notifications.clear();
    notificationCount.value = 0;
    _localNotifications.cancelAll();
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      developer.log('❌ Error getting FCM token: $e');
      return null;
    }
  }
}

// ===== MODELS =====

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? route;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.route,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? route,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      route: route ?? this.route,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}

class PendingNotificationData {
  final String identifier;
  final bool shouldOpenDetail;
  final DateTime timestamp;

  PendingNotificationData({
    required this.identifier,
    required this.shouldOpenDetail,
    required this.timestamp,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 30;
  }
}
