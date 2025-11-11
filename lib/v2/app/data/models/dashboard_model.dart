// lib/v2/app/data/models/dashboard_model.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../services/storage_service.dart';

class TeacherDashboardModel {
  final DashboardStats stats;
  final List<TodayScheduleModel> todaySchedules;
  final List<PrayerTimeModel> prayerTimes;
  final List<AnnouncementModel> announcements;
  final UserModel teacher;

  const TeacherDashboardModel({
    required this.stats,
    required this.todaySchedules,
    required this.prayerTimes,
    required this.announcements,
    required this.teacher,
  });

  factory TeacherDashboardModel.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardModel(
      stats: DashboardStats.fromJson(json['stats']),
      todaySchedules:
          (json['today_schedules'] as List?)
              ?.map((e) => TodayScheduleModel.fromJson(e))
              .toList() ??
          [],
      prayerTimes:
          (json['prayer_times'] as List?)
              ?.map((e) => PrayerTimeModel.fromJson(e))
              .toList() ??
          [],
      announcements:
          (json['announcements'] as List?)
              ?.map((e) => AnnouncementModel.fromJson(e))
              .toList() ??
          [],
      teacher: UserModel.fromJson(json['teacher']),
    );
  }

  // ✅ NEW: copyWith method
  TeacherDashboardModel copyWith({
    DashboardStats? stats,
    List<TodayScheduleModel>? todaySchedules,
    List<PrayerTimeModel>? prayerTimes,
    List<AnnouncementModel>? announcements,
    UserModel? teacher,
  }) {
    return TeacherDashboardModel(
      stats: stats ?? this.stats,
      todaySchedules: todaySchedules ?? this.todaySchedules,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      announcements: announcements ?? this.announcements,
      teacher: teacher ?? this.teacher,
    );
  }
}

class DashboardStats {
  final int totalStudents;
  final int totalClasses;
  final int todayTasks;
  final int totalAnnouncements;

  const DashboardStats({
    required this.totalStudents,
    required this.totalClasses,
    required this.todayTasks,
    required this.totalAnnouncements,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json['total_students'] ?? 0,
      totalClasses: json['total_classes'] ?? 0,
      todayTasks: json['today_tasks'] ?? 0,
      totalAnnouncements: json['total_announcements'] ?? 0,
    );
  }
}

class TodayScheduleModel {
  final String id;
  final String subjectName;
  final String className;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final String day;
  final bool isDone;
  final int totalStudents;

  const TodayScheduleModel({
    required this.id,
    required this.subjectName,
    required this.className,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.day,
    this.isDone = false,
    required this.totalStudents,
  });

  factory TodayScheduleModel.fromJson(Map<String, dynamic> json) {
    final scheduleId = json['id']?.toString() ?? '';

    // ✅ Check isDone dari JSON dulu
    bool isDone = _safeBoolConversion(json['is_done']);

    // ✅ Jika belum done, cek dari storage
    if (!isDone && scheduleId.isNotEmpty) {
      try {
        if (Get.isRegistered<StorageService>()) {
          final storageService = Get.find<StorageService>();
          final today = DateTime.now().toIso8601String().split('T')[0];
          isDone = storageService.isScheduleDone(scheduleId, today);

          if (isDone) {
            developer.log('✅ Schedule $scheduleId marked as done from storage');
          }
        }
      } catch (e) {
        developer.log('⚠️ Error checking storage for isDone: $e');
      }
    }

    return TodayScheduleModel(
      id: scheduleId,
      subjectName: json['subject_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      isDone: isDone, // ✅ Gunakan isDone yang sudah dicek
      totalStudents: json['total_students'] ?? 0,
    );
  }

  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // ✅ TAMBAH: CopyWith method
  TodayScheduleModel copyWith({
    String? id,
    String? subjectName,
    String? className,
    String? timeSlot,
    String? startTime,
    String? endTime,
    String? day,
    bool? isDone,
    int? totalStudents,
  }) {
    return TodayScheduleModel(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      className: className ?? this.className,
      timeSlot: timeSlot ?? this.timeSlot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      day: day ?? this.day,
      isDone: isDone ?? this.isDone,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }

  String get timeRange => '$startTime - $endTime';

  bool get isOngoing {
    try {
      final now = TimeOfDay.now();
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      return _isTimeBetween(now, start, end);
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {}
    return TimeOfDay.now();
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}

class PrayerTimeModel {
  final String name;
  final String time;
  final String arabicName;
  final bool isPassed;

  const PrayerTimeModel({
    required this.name,
    required this.time,
    required this.arabicName,
    this.isPassed = false,
  });

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    return PrayerTimeModel(
      name: json['name']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      arabicName: json['arabic_name']?.toString() ?? '',
      isPassed: _safeBoolConversion(json['is_passed']),
    );
  }

  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static List<PrayerTimeModel> getDefaultTimes() {
    return [
      const PrayerTimeModel(name: 'Subuh', time: '04:30', arabicName: 'الفجر'),
      const PrayerTimeModel(name: 'Dzuhur', time: '12:00', arabicName: 'الظهر'),
      const PrayerTimeModel(name: 'Ashar', time: '15:30', arabicName: 'العصر'),
      const PrayerTimeModel(
        name: 'Maghrib',
        time: '18:15',
        arabicName: 'المغرب',
      ),
      const PrayerTimeModel(name: 'Isya', time: '19:30', arabicName: 'العشاء'),
    ];
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String? image;
  final DateTime publishedAt;
  final String category;
  final bool isPriority;
  final String? slug;
  bool isRead; // ✅ Mutable untuk bisa diubah

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.publishedAt,
    this.category = 'umum',
    this.isPriority = false,
    this.slug,
    this.isRead = false,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final announcementId = json['id']?.toString() ?? '';

    // ✅ Check dari JSON dulu
    bool isRead = _safeBoolConversion(json['is_read']);

    // ✅ Override dengan data dari local storage (PRIORITAS TINGGI)
    if (!isRead && announcementId.isNotEmpty) {
      try {
        if (Get.isRegistered<StorageService>()) {
          final storageService = Get.find<StorageService>();
          isRead = storageService.isAnnouncementRead(announcementId);

          if (isRead) {
            developer.log(
              '✅ AnnouncementModel: $announcementId marked as read from storage',
            );
          }
        }
      } catch (e) {
        developer.log(
          '⚠️ AnnouncementModel: Error checking storage for isRead: $e',
        );
      }
    }

    return AnnouncementModel(
      id: announcementId,
      title: json['judul']?.toString() ?? json['title']?.toString() ?? '',
      content: json['isi']?.toString() ?? json['content']?.toString() ?? '',
      image: json['gambar']?.toString() ?? json['image']?.toString(),
      publishedAt: _parseDateTime(json['published_at'] ?? json['created_at']),
      category:
          json['kategori']?.toString() ??
          json['category']?.toString() ??
          'umum',
      isPriority: _safeBoolConversion(json['is_priority']),
      slug: json['slug']?.toString(),
      isRead: isRead,
    );
  }

  // ✅ copyWith untuk immutable pattern
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    String? image,
    DateTime? publishedAt,
    String? category,
    bool? isPriority,
    String? slug,
    bool? isRead,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      isPriority: isPriority ?? this.isPriority,
      slug: slug ?? this.slug,
      isRead: isRead ?? this.isRead,
    );
  }

  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'judul': title,
      'content': content,
      'isi': content,
      'image': image,
      'gambar': image,
      'published_at': publishedAt.toIso8601String(),
      'category': category,
      'kategori': category,
      'is_priority': isPriority,
      'slug': slug,
      'is_read': isRead,
    };
  }
}
