// lib/v2/app/modules/student/announcements/controllers/student_announcements_controller.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';
import '../../../../data/services/notification_service.dart';

class StudentAnnouncementsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final announcements = <AnnouncementModel>[].obs;
  final selectedCategory = 'all'.obs;
  final searchQuery = ''.obs;

  // Pagination
  int currentPage = 1;
  bool hasMoreData = true;

  // ✅ Flag to prevent double checking
  bool _hasCheckedNotification = false;

  // Categories
  final categories = <String, String>{
    'all': 'Semua',
    'umum': 'Umum',
    'akademik': 'Akademik',
    'kegiatan': 'Kegiatan',
    'penting': 'Penting',
  };

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    developer.log('🎬 ===== StudentAnnouncementsController onInit =====');

    loadAnnouncements();
  }

  @override
  void onReady() {
    super.onReady();
    developer.log('✅ StudentAnnouncementsController onReady');

    // ✅ Only check once
    if (!_hasCheckedNotification) {
      _hasCheckedNotification = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        _checkNotificationTrigger();
      });
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// ✅ Check notification trigger - ONLY ONCE
  void _checkNotificationTrigger() {
    try {
      developer.log('🔍 ===== CHECKING NOTIFICATION TRIGGER =====');

      String? identifier;
      bool shouldOpenDetail = false;

      // ✅ Check NotificationService Rx observable
      if (Get.isRegistered<NotificationService>()) {
        final notifService = Get.find<NotificationService>();
        final pendingData = notifService.pendingNotification.value;

        developer.log('📦 Pending notification: $pendingData');

        if (pendingData != null && !pendingData.isExpired) {
          identifier = pendingData.identifier;
          shouldOpenDetail = pendingData.shouldOpenDetail;

          developer.log('💾 From NotificationService Rx:');
          developer.log('   - identifier: $identifier');
          developer.log('   - shouldOpenDetail: $shouldOpenDetail');

          // ✅ DON'T clear here - will clear after successfully opening
          developer.log('📌 Keeping data until opened');
        } else if (pendingData != null && pendingData.isExpired) {
          developer.log('⏰ Pending notification expired');
          notifService.pendingNotification.value = null;
        } else {
          developer.log('ℹ️ No pending notification');
        }
      } else {
        developer.log('⚠️ NotificationService not registered');
      }

      // ✅ FALLBACK: Check Get.arguments
      if (identifier == null) {
        final args = Get.arguments;
        developer.log('📦 Get.arguments: $args');

        if (args != null && args is Map) {
          final data = Map<String, dynamic>.from(args);
          identifier = data['identifier']?.toString() ?? data['id']?.toString();
          shouldOpenDetail =
              data['openDetail'] == true || data['openDetail'] == 'true';

          developer.log(
            '📋 From arguments - identifier: $identifier, openDetail: $shouldOpenDetail',
          );
        }
      }

      // ✅ FALLBACK 2: Check Get.parameters
      if (identifier == null) {
        final params = Get.parameters;
        developer.log('📦 Get.parameters: $params');

        if (params.isNotEmpty) {
          identifier = params['identifier'] ?? params['id'];
          shouldOpenDetail = params['openDetail'] == 'true';

          developer.log(
            '📋 From parameters - identifier: $identifier, openDetail: $shouldOpenDetail',
          );
        }
      }

      // Open detail if found
      if (identifier != null && identifier.isNotEmpty && shouldOpenDetail) {
        developer.log('🎯 Will open detail for: $identifier');
        _waitAndOpenDetail(identifier);
      } else {
        developer.log('ℹ️ No notification trigger found');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error checking notification trigger: $e');
      developer.log('Stack: $stackTrace');
    }
  }

  /// ✅ Wait for data then open detail
  void _waitAndOpenDetail(String identifier, {int retryCount = 0}) {
  developer.log('⏳ Waiting for announcements... (attempt ${retryCount + 1})');
  developer.log('🔍 Looking for: $identifier');
  
  // Check if already ready
  if (announcements.isNotEmpty && !isLoading.value) {
    developer.log('✅ Data ALREADY ready (${announcements.length} items)');
    Future.delayed(const Duration(milliseconds: 300), () {
      _findAndOpenAnnouncement(identifier);
    });
    return;
  }
  
  developer.log('⏰ Data not ready yet, setting up worker...');
  developer.log('   - announcements.length: ${announcements.length}');
  developer.log('   - isLoading: ${isLoading.value}');
  
  // Setup worker
  Worker? worker;
  bool workerTriggered = false;
  
  worker = ever(announcements, (value) {
    developer.log('🔔 Worker triggered! length: ${value.length}, isLoading: ${isLoading.value}');
    
    if (value.isNotEmpty && !isLoading.value && !workerTriggered) {
      workerTriggered = true;
      developer.log('✅ Data loaded via worker (${value.length} items)');
      worker?.dispose();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        _findAndOpenAnnouncement(identifier);
      });
    }
  });
  
  // ✅ BACKUP: Polling every 500ms
  void pollForData(int pollCount) {
    if (pollCount > 6 || workerTriggered) return; // Max 3 seconds
    
    Future.delayed(const Duration(milliseconds: 500), () {
      developer.log('🔄 Polling check $pollCount: length=${announcements.length}, loading=${isLoading.value}');
      
      if (announcements.isNotEmpty && !isLoading.value && !workerTriggered) {
        workerTriggered = true;
        worker?.dispose();
        developer.log('✅ Data loaded via polling! (${announcements.length} items)');
        
        Future.delayed(const Duration(milliseconds: 300), () {
          _findAndOpenAnnouncement(identifier);
        });
      } else {
        pollForData(pollCount + 1);
      }
    });
  }
  
  // Start polling as backup
  pollForData(1);
  
  // Final timeout
  Future.delayed(const Duration(seconds: 4), () {
    if (!workerTriggered) {
      developer.log('❌ Complete timeout, trying API');
      worker?.dispose();
      _fetchAndOpenDetail(identifier);
    }
  });
}

  /// ✅ Find and open announcement
  void _findAndOpenAnnouncement(String identifier) {
    try {
      developer.log('🔍 ===== SEARCHING FOR ANNOUNCEMENT =====');
      developer.log('🔍 Identifier: $identifier');
      developer.log('📋 Total: ${announcements.length}');

      // Log first few
      for (var i = 0; i < announcements.length && i < 3; i++) {
        final a = announcements[i];
        developer.log('  [$i] id: ${a.id} | slug: ${a.slug}');
      }

      // Search
      final announcement = announcements.firstWhereOrNull((a) {
        final matchId =
            a.id.toString().toLowerCase() == identifier.toLowerCase();
        final matchSlug =
            (a.slug?.toString().toLowerCase() ?? '') ==
            identifier.toLowerCase();

        if (matchId || matchSlug) {
          developer.log('✅ MATCH FOUND!');
          developer.log('   - By ID: $matchId');
          developer.log('   - By slug: $matchSlug');
          return true;
        }
        return false;
      });

      if (announcement != null) {
        developer.log('✅ Found: "${announcement.title}"');

        // ✅ Clear notification data AFTER found
        if (Get.isRegistered<NotificationService>()) {
          final notifService = Get.find<NotificationService>();
          notifService.pendingNotification.value = null;
          developer.log('🗑️ Cleared notification after found');
        }

        Future.delayed(const Duration(milliseconds: 800), () {
          developer.log('📖 Opening detail dialog');
          viewAnnouncementDetail(announcement);
        });
      } else {
        developer.log('⚠️ NOT FOUND in local data');
        developer.log('🌐 Trying API fetch...');
        _fetchAndOpenDetail(identifier);
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error finding announcement: $e');
      developer.log('Stack: $stackTrace');

      Get.snackbar(
        'Error',
        'Gagal membuka pengumuman',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// ✅ Fetch from API
  Future<void> _fetchAndOpenDetail(String identifier) async {
    try {
      developer.log('🌐 Fetching from API: $identifier');

      final response = await _apiService.getBeritaDetail(identifier);

      if (response != null && response['data'] != null) {
        developer.log('✅ Fetched successfully');

        final announcement = AnnouncementModel.fromJson(response['data']);

        if (!announcements.any((a) => a.id == announcement.id)) {
          announcements.insert(0, announcement);
          developer.log('➕ Added to list');
        }

        // ✅ Clear notification data after fetched
        if (Get.isRegistered<NotificationService>()) {
          final notifService = Get.find<NotificationService>();
          notifService.pendingNotification.value = null;
          developer.log('🗑️ Cleared notification after API fetch');
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          developer.log('📖 Opening fetched announcement');
          viewAnnouncementDetail(announcement);
        });
      } else {
        developer.log('❌ API returned no data');

        Get.snackbar(
          'Info',
          'Pengumuman tidak ditemukan',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error fetching from API: $e');
      developer.log('Stack: $stackTrace');

      Get.snackbar(
        'Error',
        'Pengumuman tidak ditemukan',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

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

      developer.log('📡 Loading announcements page $currentPage...');

      final response = await _apiService.getStudentBerita(page: currentPage);

      final newAnnouncements =
          response.map((json) => AnnouncementModel.fromJson(json)).toList();

      if (newAnnouncements.isEmpty) {
        hasMoreData = false;
      } else {
        announcements.addAll(newAnnouncements);
        currentPage++;
      }

      developer.log(
        '✅ Loaded ${newAnnouncements.length} announcements, total: ${announcements.length}',
      );
    } catch (e, stackTrace) {
      developer.log('❌ Error loading: $e');
      developer.log('Stack: $stackTrace');
      _showErrorSnackbar('Error', 'Gagal memuat pengumuman: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshAnnouncements() async {
    await loadAnnouncements(refresh: true);
  }

  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMoreData) {
      await loadAnnouncements();
    }
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    refreshAnnouncements();
  }

  void searchAnnouncements(String query) {
    searchQuery.value = query;
    refreshAnnouncements();
  }

  List<AnnouncementModel> get filteredAnnouncements {
    final selectedCat = selectedCategory.value;
    final query = searchQuery.value;
    final allAnnouncements = announcements.value;

    var filtered =
        allAnnouncements.where((announcement) {
          if (selectedCat != 'all' && announcement.category != selectedCat) {
            return false;
          }

          if (query.isNotEmpty) {
            return announcement.title.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                announcement.content.toLowerCase().contains(
                  query.toLowerCase(),
                );
          }

          return true;
        }).toList();

    filtered.sort((a, b) {
      if (a.isPriority && !b.isPriority) return -1;
      if (!a.isPriority && b.isPriority) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    return filtered;
  }

  void viewAnnouncementDetail(AnnouncementModel announcement) {
    developer.log('📖 ===== OPENING DETAIL DIALOG =====');
    developer.log('📖 Title: ${announcement.title}');
    developer.log('📖 ID: ${announcement.id}');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (announcement.isPriority)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PENTING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    announcement.timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      announcement.category.toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (announcement.image != null && announcement.image!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(announcement.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Html(
                    data: announcement.content,
                    style: {
                      "body": Style(
                        fontSize: FontSize(14),
                        lineHeight: LineHeight(1.5),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "p": Style(margin: Margins.only(bottom: 8)),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    developer.log('✅ Dialog displayed');
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
