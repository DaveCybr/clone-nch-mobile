// lib/v2/app/modules/teacher/announcements/controllers/announcements_controller.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/storage_service.dart';
import '../views/announcement_detail_view.dart';

class AnnouncementsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final announcements = <AnnouncementModel>[].obs; // ✅ Observable list
  final selectedCategory = 'all'.obs;
  final searchQuery = ''.obs;

  // Pagination
  int currentPage = 1;
  bool hasMoreData = true;

  // Categories
  final categories = <String, String>{
    'all': 'Semua',
    'umum': 'Umum',
    'akademik': 'Akademik',
    'kegiatan': 'Kegiatan',
    'penting': 'Penting',
  };

  // Controllers
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    developer.log('🔄 Initializing AnnouncementsController...');

    // Load announcements
    await loadAnnouncements();

    // Check notification arguments
    _checkNotificationArguments();
  }

  /// Check if page opened from notification
  void _checkNotificationArguments() {
    try {
      final args = Get.arguments;

      developer.log('📦 Announcements page arguments: $args');

      if (args != null && args is Map<String, dynamic>) {
        if (args['openDetail'] == true) {
          final identifier = args['identifier'];

          developer.log('🎯 Should open detail with identifier: $identifier');

          if (identifier != null) {
            _openAnnouncementByIdentifier(identifier.toString());
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error checking notification arguments: $e');
    }
  }

  void _openAnnouncementByIdentifier(String identifier) {
    try {
      developer.log('🔍 Looking for announcement with identifier: $identifier');

      // Wait for announcements to load
      Future.delayed(const Duration(milliseconds: 1000), () {
        final announcement = announcements.firstWhereOrNull(
          (a) => a.id.toString() == identifier,
        );

        if (announcement != null) {
          developer.log('✅ Found announcement, opening detail');
          viewAnnouncementDetail(announcement);
        } else {
          developer.log(
            '⚠️ Announcement not found with identifier: $identifier',
          );
          Get.snackbar(
            'Info',
            'Pengumuman tidak ditemukan',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      });
    } catch (e) {
      developer.log('❌ Error opening announcement by identifier: $e');
    }
  }

  /// Load announcements from API
  Future<void> loadAnnouncements({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage = 1;
        hasMoreData = true;
        announcements.clear();
      }

      if (!hasMoreData) return;

      isLoading.value = refresh || announcements.isEmpty;
      isLoadingMore.value = !refresh && announcements.isNotEmpty;

      final response = await _apiService.getAnnouncements(
        page: currentPage,
        limit: 10,
      );

      final newAnnouncements =
          response.map((json) => AnnouncementModel.fromJson(json)).toList();

      // ✅ isRead status sudah di-set dari fromJson (otomatis cek storage)
      developer.log('✅ Loaded ${newAnnouncements.length} announcements');

      if (newAnnouncements.isEmpty) {
        hasMoreData = false;
      } else {
        announcements.addAll(newAnnouncements);
        currentPage++;
      }
    } catch (e) {
      developer.log('❌ Error loading announcements: $e');
      _showErrorSnackbar('Error', 'Gagal memuat pengumuman: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Refresh announcements
  Future<void> refreshAnnouncements() async {
    developer.log('🔄 Refreshing announcements...');
    await loadAnnouncements(refresh: true);
  }

  /// Load more announcements
  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMoreData) {
      await loadAnnouncements();
    }
  }

  /// Filter announcements by category
  void filterByCategory(String category) {
    selectedCategory.value = category;
  }

  /// Search announcements
  void searchAnnouncements(String query) {
    searchQuery.value = query;
  }

  /// Get filtered announcements
  List<AnnouncementModel> get filteredAnnouncements {
    final selectedCat = selectedCategory.value;
    final query = searchQuery.value;
    var filtered = List<AnnouncementModel>.from(announcements);

    // Filter by category
    if (selectedCat != 'all') {
      filtered = filtered.where((a) => a.category == selectedCat).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered =
          filtered.where((a) {
            return a.title.toLowerCase().contains(lowerQuery) ||
                a.content.toLowerCase().contains(lowerQuery);
          }).toList();
    }

    // Sort: priority first, then by date
    filtered.sort((a, b) {
      if (a.isPriority && !b.isPriority) return -1;
      if (!a.isPriority && b.isPriority) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    return filtered;
  }

  /// ✅ View announcement detail - AUTO MARK AS READ
  void viewAnnouncementDetail(AnnouncementModel announcement) {
    developer.log('👀 Opening announcement detail: ${announcement.id}');

    // ✅ Mark as read SEBELUM navigate
    if (!announcement.isRead) {
      markAsRead(announcement.id);
    }

    // Navigate to detail
    Get.to(
      () => AnnouncementDetailView(announcement: announcement),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// ✅ Mark announcement as read - SYNC + TRIGGER REBUILD
  void markAsRead(String announcementId) {
    try {
      developer.log('📖 Marking announcement as read: $announcementId');

      // Find announcement in list
      final index = announcements.indexWhere((a) => a.id == announcementId);

      if (index != -1) {
        // Check if already read
        if (announcements[index].isRead) {
          developer.log('ℹ️ Announcement already marked as read');
          return;
        }

        // Update local state
        announcements[index].isRead = true;

        // Save to storage (async tapi tidak perlu await)
        _storageService.markAnnouncementAsRead(announcementId);

        // ✅ CRITICAL: Force UI update by triggering list change
        announcements.refresh();

        developer.log('✅ Marked announcement $announcementId as read');
        developer.log('📊 Unread count: $unreadCount');
      } else {
        developer.log('⚠️ Announcement not found in list: $announcementId');
      }
    } catch (e) {
      developer.log('❌ Error marking as read: $e');
    }
  }

  /// ✅ Get unread count - REACTIVE
  int get unreadCount {
    final count = announcements.where((a) => !a.isRead).length;
    return count;
  }

  /// ✅ Mark all as read
  Future<void> markAllAsRead() async {
    try {
      developer.log('📚 Marking all announcements as read...');

      final unreadIds =
          announcements.where((a) => !a.isRead).map((a) => a.id).toList();

      if (unreadIds.isEmpty) {
        developer.log('ℹ️ No unread announcements to mark');
        return;
      }

      // Update all to read
      for (var announcement in announcements) {
        if (!announcement.isRead) {
          announcement.isRead = true;
        }
      }

      // Save to storage in batch
      await _storageService.markMultipleAnnouncementsAsRead(unreadIds);

      // ✅ CRITICAL: Force UI update
      announcements.refresh();

      developer.log('✅ Marked ${unreadIds.length} announcements as read');

      Get.snackbar(
        'Berhasil',
        'Semua pengumuman ditandai sudah dibaca',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      developer.log('❌ Error marking all as read: $e');
      _showErrorSnackbar('Error', 'Gagal menandai semua sebagai dibaca');
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
