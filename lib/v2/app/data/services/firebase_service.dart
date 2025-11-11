// lib/v2/app/data/services/firebase_service.dart
// FIXED VERSION - Using NavigationService

import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nch_mobile/v2/app/data/services/navigations_services.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../../routes/app_routes.dart';
import '../models/user_model.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('📨 Background message received: ${message.messageId}');
  developer.log('Title: ${message.notification?.title}');
  developer.log('Body: ${message.notification?.body}');
  developer.log('Data: ${message.data}');
}

class FirebaseService extends GetxService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  get firebaseMessaging => _firebaseMessaging;
  get storageService => _storageService;
  get apiService => _apiService;
  get currentUser => _storageService.getUser();
  get hasValidToken => _storageService.hasValidToken;

  final fcmToken = Rxn<String>();
  final isTokenSent = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      developer.log('🔥 Initializing Firebase Service...');

      await _requestPermission();
      await _getFCMToken();

      _setupMessageHandlers();
      _setupTokenRefreshListener();
      await _checkInitialMessage();

      developer.log('✅ Firebase Service initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing Firebase: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      developer.log('📱 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('✅ User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('⚠️ User granted provisional permission');
      } else {
        developer.log('❌ User declined or has not accepted permission');
      }
    } catch (e) {
      developer.log('❌ Error requesting permission: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        fcmToken.value = token;
        developer.log('🔑 FCM Token obtained: ${token.substring(0, 20)}...');

        if (_storageService.hasValidToken) {
          await sendTokenToServer(token);
        }
      } else {
        developer.log('⚠️ FCM Token is null');
      }
    } catch (e) {
      developer.log('❌ Error getting FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 Foreground message received');
      developer.log('Notification: ${message.notification?.title}');
      developer.log('Data: ${message.data}');
    });

    // Background/Terminated - When user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('📱 Notification opened from background');
      developer.log('📦 Message data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      developer.log('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      fcmToken.value = newToken;

      if (_storageService.hasValidToken) {
        sendTokenToServer(newToken);
      }
    });
  }

  /// ✅ Check if app was opened from notification (terminated state)
  Future<void> _checkInitialMessage() async {
    try {
      developer.log('🔍 Checking for initial notification message...');

      final initialMessage = await _firebaseMessaging.getInitialMessage();

      if (initialMessage != null) {
        developer.log('🎯 ===== APP OPENED FROM TERMINATED STATE =====');
        developer.log('📦 Message ID: ${initialMessage.messageId}');
        developer.log('📦 Title: ${initialMessage.notification?.title}');
        developer.log('📦 Body: ${initialMessage.notification?.body}');
        developer.log('📦 Data: ${initialMessage.data}');

        // Delay untuk memastikan app sudah fully initialized
        Future.delayed(const Duration(milliseconds: 3000), () {
          developer.log('🚀 Processing initial notification...');
          _handleNotificationTap(initialMessage);
        });
      } else {
        developer.log('ℹ️ No initial notification found');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error checking initial message: $e');
      developer.log('Stack: $stackTrace');
    }
  }

  /// ✅ FIXED: Handle notification tap dengan NavigationService
  void _handleNotificationTap(RemoteMessage message) {
    try {
      developer.log('👆 ===== NOTIFICATION TAPPED =====');
      developer.log('📦 Message data: ${message.data}');
      developer.log('📦 Notification: ${message.notification?.toMap()}');

      final data = message.data;

      // Detect notification type
      String? notifType;

      if (data.containsKey('type')) {
        notifType = data['type'] as String;
      } else if (data.containsKey('notification_type')) {
        notifType = data['notification_type'] as String;
      } else if (data.containsKey('berita_id')) {
        notifType = 'berita';
      } else if (data.containsKey('announcement_id')) {
        notifType = 'announcement';
      }

      developer.log('🔍 Detected notification type: $notifType');

      if (notifType != null) {
        _handleNotificationType(notifType, data);
        return;
      }

      // Check route field
      if (data.containsKey('route')) {
        final route = data['route'] as String;
        developer.log('🚀 Direct route: $route');

        Future.delayed(const Duration(milliseconds: 1000), () {
          // ✅ FIXED: Use NavigationService
          NavigationService.to.toNamed(route, arguments: data);
        });
        return;
      }

      // Fallback to announcements
      developer.log(
        '⚠️ No type/route, using fallback navigation to announcements',
      );
      _navigateToAnnouncements(data);
    } catch (e, stackTrace) {
      developer.log('❌ Error handling notification tap: $e');
      developer.log('Stack: $stackTrace');
    }
  }

  /// ✅ FIXED: Navigate ke announcements menggunakan NavigationService
  void _navigateToAnnouncements(Map<String, dynamic> data) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      try {
        final user = _storageService.getUser();
        final isTeacher = user?.isTeacher ?? false;

        developer.log('👤 User is teacher: $isTeacher');

        // Determine route
        final route =
            isTeacher
                ? Routes.TEACHER_ANNOUNCEMENTS
                : Routes.STUDENT_ANNOUNCEMENTS;

        developer.log('🎯 Navigating to route: $route');
        developer.log('📦 With arguments: $data');

        // ✅ FIXED: Teacher announcements = fullscreen, Student = tab
        if (isTeacher) {
          NavigationService.to.toFullscreen(
            route,
            arguments: {'from_notification': true, ...data},
          );
        } else {
          NavigationService.to.toBottomNavTab(route);
        }

        developer.log('✅ Navigation executed');
      } catch (e) {
        developer.log('❌ Error in _navigateToAnnouncements: $e');
      }
    });
  }

  /// ✅ FIXED: Handle announcement notification
  void _handleAnnouncementNotification(Map<String, dynamic> data) {
    developer.log('📰 ===== HANDLING ANNOUNCEMENT NOTIFICATION =====');
    developer.log('📦 Data: $data');

    Future.delayed(const Duration(milliseconds: 1000), () {
      try {
        final user = _storageService.getUser();
        final isTeacher = user?.isTeacher ?? false;

        developer.log('👤 User role: ${isTeacher ? "Teacher" : "Student"}');

        // Determine route
        final route =
            isTeacher
                ? Routes.TEACHER_ANNOUNCEMENTS
                : Routes.STUDENT_ANNOUNCEMENTS;

        developer.log('🎯 Route: $route');

        // Check for identifier
        final identifier =
            data['slug'] ??
            data['id'] ??
            data['berita_id'] ??
            data['announcement_id'];

        final arguments = <String, dynamic>{'from_notification': true};

        if (identifier != null) {
          developer.log('📌 Found identifier: $identifier');
          arguments['openDetail'] = true;
          arguments['identifier'] = identifier.toString();
        }

        arguments['data'] = data;

        developer.log('🚀 Navigating to: $route');
        developer.log('📦 With arguments: $arguments');

        // ✅ FIXED: Proper navigation based on route type
        if (isTeacher) {
          // Teacher announcements = fullscreen
          NavigationService.to.toFullscreen(route, arguments: arguments);
        } else {
          // Student announcements = tab (pass arguments if needed)
          NavigationService.to.toBottomNavTab(route);
          // TODO: Handle detail navigation after tab is loaded
        }

        developer.log('✅ Navigation command executed');
      } catch (e, stackTrace) {
        developer.log('❌ Error in _handleAnnouncementNotification: $e');
        developer.log('Stack: $stackTrace');
      }
    });
  }

  /// ✅ FIXED: Handle attendance notification
  void _handleAttendanceNotification(Map<String, dynamic> data) {
    developer.log('✅ ===== NAVIGATING TO ATTENDANCE =====');

    Future.delayed(const Duration(milliseconds: 1000), () {
      final user = _storageService.getUser();

      if (user?.isTeacher == true) {
        developer.log('🎯 Route: ${Routes.TEACHER_ATTENDANCE}');
        // ✅ Teacher attendance = fullscreen
        NavigationService.to.toFullscreen(
          Routes.TEACHER_ATTENDANCE,
          arguments: data,
        );
      } else {
        developer.log('🎯 Route: ${Routes.STUDENT_ATTENDANCE}');
        // ✅ Student attendance = tab
        NavigationService.to.toBottomNavTab(Routes.STUDENT_ATTENDANCE);
      }
    });
  }

  /// ✅ FIXED: Handle schedule notification
  void _handleScheduleNotification(Map<String, dynamic> data) {
    developer.log('📅 ===== NAVIGATING TO SCHEDULE =====');

    Future.delayed(const Duration(milliseconds: 1000), () {
      final user = _storageService.getUser();

      if (user?.isTeacher == true) {
        developer.log('🎯 Route: ${Routes.TEACHER_SCHEDULE}');
        // ✅ Teacher schedule = tab
        NavigationService.to.toBottomNavTab(Routes.TEACHER_SCHEDULE);
      } else {
        developer.log('🎯 Route: ${Routes.STUDENT_SCHEDULE}');
        // ✅ Student schedule = tab
        NavigationService.to.toBottomNavTab(Routes.STUDENT_SCHEDULE);
      }
    });
  }

  /// ✅ FIXED: Handle visit notification
  void _handleVisitNotification(Map<String, dynamic> data) {
    developer.log('🚪 ===== HANDLING VISIT NOTIFICATION =====');
    developer.log('📦 Data: $data');

    Future.delayed(const Duration(milliseconds: 1000), () {
      try {
        final scheduleId =
            data['visit_schedule_id']?.toString() ??
            data['schedule_id']?.toString() ??
            data['id']?.toString();

        developer.log('🔑 Schedule ID: $scheduleId');

        // ✅ Navigate to student visit tab
        NavigationService.to.toBottomNavTab(Routes.STUDENT_VISIT);

        // If there's a schedule ID, pass it for detail view
        if (scheduleId != null && scheduleId.isNotEmpty) {
          // TODO: Handle detail navigation within the visit page
          developer.log('📌 Schedule ID to open: $scheduleId');
        }

        developer.log('✅ Navigation to visit schedule executed');
      } catch (e, stackTrace) {
        developer.log('❌ Error navigating to visit schedule: $e');
        developer.log('Stack: $stackTrace');
      }
    });
  }

  void _handleNotificationType(String type, Map<String, dynamic> data) {
    developer.log('📋 Processing notification type: $type');

    final normalizedType = type.toLowerCase().trim();

    switch (normalizedType) {
      case 'attendance':
      case 'absensi':
        _handleAttendanceNotification(data);
        break;

      case 'announcement':
      case 'berita':
      case 'pengumuman':
      case 'news':
        _handleAnnouncementNotification(data);
        break;

      case 'schedule':
      case 'jadwal':
        _handleScheduleNotification(data);
        break;

      case 'payment_success':
      case 'payment_reminder':
      case 'payment':
        _handlePaymentNotification(type, data);
        break;

      case 'visit':
      case 'kunjungan':
      case 'parent':
      case 'parent_visit':
      case 'visit_schedule':
      case 'jadwal_kunjungan':
        _handleVisitNotification(data);
        break;

      case 'reminder':
      case 'pengingat':
        _showReminderDialog(data);
        break;

      default:
        developer.log(
          '⚠️ Unknown notification type: $type, defaulting to announcements',
        );
        _navigateToAnnouncements(data);
    }
  }

  void _showReminderDialog(Map<String, dynamic> data) {
    Get.defaultDialog(
      title: data['title'] ?? 'Pengingat',
      middleText: data['message'] ?? '',
      textConfirm: 'OK',
      onConfirm: () => Get.back(),
    );
  }

  /// ✅ Handle payment notification
  void _handlePaymentNotification(String type, Map<String, dynamic> data) {
    developer.log('💰 ===== HANDLING PAYMENT NOTIFICATION =====');
    developer.log('📦 Type: $type');
    developer.log('📦 Data: $data');

    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final normalizedType = type.toLowerCase();

        if (normalizedType == 'payment_success') {
          _showPaymentSuccessDialog(data);
        } else if (normalizedType == 'payment_reminder') {
          _showPaymentReminderDialog(data);
        } else {
          _showPaymentInfoDialog(data);
        }
      } catch (e, stackTrace) {
        developer.log('❌ Error handling payment notification: $e');
        developer.log('Stack: $stackTrace');
      }
    });
  }

  void _showPaymentSuccessDialog(Map<String, dynamic> data) {
    final amount = data['amount']?.toString() ?? '0';
    final receiptNumber = data['receipt_number']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '💰 Pembayaran Berhasil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Jumlah', 'Rp ${_formatNumber(amount)}'),
            const Divider(height: 20),
            if (receiptNumber.isNotEmpty)
              _buildInfoRow('No. Kwitansi', receiptNumber),
            if (status.isNotEmpty)
              _buildInfoRow('Status', _getStatusBadge(status)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran Anda telah berhasil diproses. جزاك الله خيرا',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showPaymentReminderDialog(Map<String, dynamic> data) {
    final amount = data['amount']?.toString() ?? '0';
    final month = data['month']?.toString() ?? '';
    final year = data['year']?.toString() ?? '';
    final dueDate = data['due_date']?.toString() ?? '';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '⏰ Pengingat Tagihan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Jumlah Tagihan', 'Rp ${_formatNumber(amount)}'),
            const Divider(height: 20),
            if (month.isNotEmpty && year.isNotEmpty)
              _buildInfoRow('Periode', '$month/$year'),
            if (dueDate.isNotEmpty)
              _buildInfoRow('Jatuh Tempo', _formatDate(dueDate)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mohon segera lakukan pembayaran sebelum jatuh tempo.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Nanti')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Info',
                'Hubungi bagian keuangan untuk melakukan pembayaran',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void _showPaymentInfoDialog(Map<String, dynamic> data) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue),
            SizedBox(width: 12),
            Text('Info Pembayaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['message']?.toString() ?? 'Informasi pembayaran tersedia',
            ),
            const SizedBox(height: 16),
            if (data.isNotEmpty)
              ...data.entries
                  .map((e) => _buildInfoRow(e.key, e.value?.toString() ?? ''))
                  .toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child:
                value is Widget
                    ? value
                    : Text(
                      value?.toString() ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(String amount) {
    try {
      final num = double.parse(amount.replaceAll(',', ''));
      return num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
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
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _getStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'paid':
      case 'lunas':
        color = Colors.green;
        text = 'Lunas';
        break;
      case 'partial':
      case 'cicilan':
        color = Colors.orange;
        text = 'Cicilan';
        break;
      case 'unpaid':
      case 'belum bayar':
        color = Colors.red;
        text = 'Belum Bayar';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===== TOKEN MANAGEMENT =====

  Future<bool> sendTokenToServer(String token) async {
    try {
      developer.log('📤 Sending FCM token to server...');

      if (!_storageService.hasValidToken) {
        developer.log('⚠️ User not logged in, skipping token send');
        return false;
      }

      await _apiService.updateFCMToken(token);
      isTokenSent.value = true;
      developer.log('✅ FCM token sent to server successfully');

      return true;
    } catch (e) {
      developer.log('❌ Error sending FCM token to server: $e');
      isTokenSent.value = false;
      return false;
    }
  }

  Future<String?> getToken() async {
    if (fcmToken.value != null) {
      return fcmToken.value;
    }
    return await _firebaseMessaging.getToken();
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      fcmToken.value = null;
      isTokenSent.value = false;
      developer.log('🗑️ FCM token deleted');
    } catch (e) {
      developer.log('❌ Error deleting FCM token: $e');
    }
  }

  Future<void> refreshAndSendToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final newToken = await _firebaseMessaging.getToken();

      if (newToken != null) {
        fcmToken.value = newToken;
        await sendTokenToServer(newToken);
      }
    } catch (e) {
      developer.log('❌ Error refreshing token: $e');
    }
  }

  // ===== TOPIC SUBSCRIPTION =====

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('✅ Subscribed to topic: $topic');
    } catch (e) {
      developer.log('❌ Error subscribing to topic: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('❌ Error unsubscribing from topic: $e');
    }
  }

  Future<void> subscribeToRoleTopics(String role) async {
    try {
      developer.log('📢 Subscribing to role-based topics for: $role');

      final topics = _getTopicsForRole(role);
      developer.log('📢 Topics to subscribe: $topics');

      for (final topic in topics) {
        int retryCount = 0;
        const maxRetries = 3;

        while (retryCount < maxRetries) {
          try {
            await subscribeToTopic(topic);
            developer.log('✅ Successfully subscribed to: $topic');
            break;
          } catch (e) {
            retryCount++;
            developer.log('⚠️ Retry $retryCount/$maxRetries for topic: $topic');
            if (retryCount >= maxRetries) {
              developer.log(
                '❌ Failed to subscribe to $topic after $maxRetries attempts',
              );
            } else {
              await Future.delayed(Duration(seconds: retryCount));
            }
          }
        }
      }

      developer.log('✅ All role-based topics subscription completed');
    } catch (e) {
      developer.log('❌ Error in subscribeToRoleTopics: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromRoleTopics(String role) async {
    try {
      developer.log('📕 Unsubscribing from role-based topics for: $role');
      final topics = _getTopicsForRole(role);

      for (final topic in topics) {
        await unsubscribeFromTopic(topic);
      }

      developer.log('✅ All role-based topics unsubscription completed');
    } catch (e) {
      developer.log('❌ Error in unsubscribeFromRoleTopics: $e');
    }
  }

  List<String> _getTopicsForRole(String role) {
    developer.log('🎯 Getting topics for role: $role');

    switch (role.toLowerCase()) {
      case 'teacher':
      case 'guru':
        return ['Berita', 'Guru', 'Pengumuman-Guru'];

      case 'student':
      case 'siswa':
      case 'santri':
        return ['Berita', 'Siswa', 'Pengumuman-Siswa'];

      case 'parent':
      case 'orangtua':
      case 'wali':
        return ['Berita', 'Orangtua', 'Pengumuman-Orangtua'];

      default:
        developer.log('⚠️ Unknown role, using default topics');
        return ['Berita'];
    }
  }

  Future<void> subscribeToDefaultTopics(String role) async {
    try {
      developer.log('📢 Subscribing to default topics...');
      await subscribeToRoleTopics(role);
      developer.log('✅ Default topics subscription completed');
    } catch (e) {
      developer.log('❌ Error subscribing to default topics: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromAllTopics(String role) async {
    try {
      developer.log('📕 Unsubscribing from all topics...');
      await unsubscribeFromRoleTopics(role);
      developer.log('✅ All topics unsubscription completed');
    } catch (e) {
      developer.log('❌ Error unsubscribing from all topics: $e');
    }
  }

  Future<void> subscribeToStudentTopic(String studentId) async {
    try {
      final topic = 'student_$studentId';
      developer.log('📢 Subscribing to student topic: $topic');

      await subscribeToTopic(topic);

      developer.log('✅ Successfully subscribed to student topic: $topic');
    } catch (e) {
      developer.log('❌ Error subscribing to student topic: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromStudentTopic(String studentId) async {
    try {
      final topic = 'student_$studentId';
      developer.log('📕 Unsubscribing from student topic: $topic');

      await unsubscribeFromTopic(topic);

      developer.log('✅ Successfully unsubscribed from student topic: $topic');
    } catch (e) {
      developer.log('❌ Error unsubscribing from student topic: $e');
    }
  }

  void setupNotificationsInBackground(UserModel currentUser) {
    Future.microtask(() async {
      developer.log('');
      developer.log('╔═══════════════════════════════════════════╗');
      developer.log('║  🔔 BACKGROUND NOTIFICATION SETUP START  ║');
      developer.log('╠═══════════════════════════════════════════╣');
      developer.log('║ User: ${currentUser.name}');
      developer.log('║ Role: ${currentUser.currentRole}');

      try {
        await Future.delayed(const Duration(milliseconds: 500));

        developer.log('║ 🚀 Starting subscription...');

        // Determine role
        String role = 'student';
        if (currentUser.isTeacher) {
          role = 'teacher';
        } else if (currentUser.isStudent || currentUser.student != null) {
          role = 'student';
        } else if (currentUser.isParent) {
          role = 'parent';
        }

        developer.log('║ 🎯 Subscribing as: $role');

        // Subscribe to role topics
        await subscribeToDefaultTopics(role);

        // Subscribe to student topic for payment notification
        if (currentUser.student != null) {
          final studentId = currentUser.student!.id;
          developer.log(
            '║ 💰 Subscribing to student payment topic: student_$studentId',
          );

          try {
            await subscribeToStudentTopic(studentId);
            developer.log('║ ✅ Student payment topic subscribed');
          } catch (e) {
            developer.log('║ ⚠️ Failed to subscribe student topic: $e');
          }
        }

        // Subscribe to Parent topic for visit notification
        if (role == 'student') {
          try {
            await subscribeToTopic('Parent');
            developer.log('║ ✅ Parent topic subscribed (for visits)');
          } catch (e) {
            developer.log('║ ⚠️ Failed to subscribe Parent topic: $e');
          }
        }

        developer.log('║ ✅ Subscription completed successfully');
        developer.log('╚═══════════════════════════════════════════╝');
        developer.log('');

        Get.snackbar(
          '🔔 Notifikasi Aktif',
          'Anda akan menerima notifikasi pengumuman dan pembayaran',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e, stack) {
        developer.log('║ ❌ Background subscription failed: $e');
        developer.log('║ Stack: $stack');
        developer.log('╚═══════════════════════════════════════════╝');
        developer.log('');

        // Retry once
        developer.log('🔄 Retrying subscription in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));

        try {
          String role = currentUser.isTeacher ? 'teacher' : 'student';
          await subscribeToDefaultTopics(role);

          if (currentUser.student != null) {
            await subscribeToStudentTopic(currentUser.student!.id);
          }

          developer.log('✅ Retry successful!');
        } catch (retryError) {
          developer.log('❌ Retry failed: $retryError');
        }
      }
    });
  }

  Future<void> unsubscribeFromTopics(UserModel currentUser) async {
    try {
      developer.log('📕 Unsubscribing from notification topics...');

      String role = 'student';
      if (currentUser.isTeacher) {
        role = 'teacher';
      } else if (currentUser.isStudent || currentUser.student != null) {
        role = 'student';
      } else if (currentUser.isParent) {
        role = 'parent';
      }

      await unsubscribeFromAllTopics(role);

      // Unsubscribe from student topic
      if (currentUser.student != null) {
        try {
          await unsubscribeFromStudentTopic(currentUser.student!.id);
          developer.log('✅ Unsubscribed from student payment topic');
        } catch (e) {
          developer.log('⚠️ Failed to unsubscribe student topic: $e');
        }
      }

      // Unsubscribe from Parent topic
      if (role == 'student') {
        try {
          await unsubscribeFromTopic('Parent');
          developer.log('✅ Unsubscribed from Parent topic');
        } catch (e) {
          developer.log('⚠️ Failed to unsubscribe Parent topic: $e');
        }
      }

      developer.log('✅ Successfully unsubscribed from all topics');
    } catch (e) {
      developer.log('❌ Error unsubscribing from topics: $e');
    }
  }
}
