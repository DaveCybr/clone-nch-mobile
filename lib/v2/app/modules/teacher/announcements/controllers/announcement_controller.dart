// lib/v2/app/modules/teacher/announcements/controllers/announcements_controller.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../data/services/api_service.dart';

class AnnouncementsController extends GetxController {
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
    loadAnnouncements();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load announcements
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

      if (newAnnouncements.isEmpty) {
        hasMoreData = false;
      } else {
        announcements.addAll(newAnnouncements);
        currentPage++;
      }

      developer.log(
        'Loaded ${newAnnouncements.length} announcements, total: ${announcements.length}',
      );
    } catch (e) {
      developer.log('Error loading announcements: $e');
      _showErrorSnackbar('Error', 'Gagal memuat pengumuman: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Refresh announcements
  Future<void> refreshAnnouncements() async {
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
    // In a real app, you'd filter server-side
    refreshAnnouncements();
  }

  /// Search announcements
  void searchAnnouncements(String query) {
    searchQuery.value = query;
    // Implement search logic or refresh with search parameter
    refreshAnnouncements();
  }

  // Ganti getter filteredAnnouncements di announcements_controller.dart

  /// Get filtered announcements
  List<AnnouncementModel> get filteredAnnouncements {
    // ✅ PENTING: Akses .value agar Obx bisa detect perubahan
    final selectedCat = selectedCategory.value;
    final query = searchQuery.value;
    final allAnnouncements = announcements.value; // ✅ Tambahkan .value

    var filtered =
        allAnnouncements.where((announcement) {
          // Category filter
          if (selectedCat != 'all' && announcement.category != selectedCat) {
            return false;
          }

          // Search filter
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

    // Sort by priority and date
    filtered.sort((a, b) {
      if (a.isPriority && !b.isPriority) return -1;
      if (!a.isPriority && b.isPriority) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    return filtered;
  }

  /// View announcement detail
  void viewAnnouncementDetail(AnnouncementModel announcement) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: Get.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  if (announcement.isPriority)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

              // Date and category
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

              // Image if available
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    announcement.content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
