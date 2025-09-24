import 'package:flutter/material.dart';
import '../models/user_model.dart';

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
    return TodayScheduleModel(
      id: json['id']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      // ✅ Fix: Safe boolean conversion
      isDone: _safeBoolConversion(json['is_done']),
      totalStudents: json['total_students'] ?? 0,
    );
  }

  // ✅ Helper method for safe boolean conversion
  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
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
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      // Return current time as fallback
    }
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
      // ✅ Fix: Safe boolean conversion
      isPassed: _safeBoolConversion(json['is_passed']),
    );
  }

  // ✅ Helper method for safe boolean conversion
  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static List<PrayerTimeModel> getDefaultTimes() {
    return [
      PrayerTimeModel(name: 'Subuh', time: '04:30', arabicName: 'الفجر'),
      PrayerTimeModel(name: 'Dzuhur', time: '12:00', arabicName: 'الظهر'),
      PrayerTimeModel(name: 'Ashar', time: '15:30', arabicName: 'العصر'),
      PrayerTimeModel(name: 'Maghrib', time: '18:15', arabicName: 'المغرب'),
      PrayerTimeModel(name: 'Isya', time: '19:30', arabicName: 'العشاء'),
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

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.publishedAt,
    this.category = 'umum',
    this.isPriority = false,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      title: json['judul']?.toString() ?? json['title']?.toString() ?? '',
      content: json['isi']?.toString() ?? json['content']?.toString() ?? '',
      image: json['gambar']?.toString() ?? json['image']?.toString(),
      publishedAt: _parseDateTime(json['published_at'] ?? json['created_at']),
      category: json['kategori']?.toString() ?? json['category']?.toString() ?? 'umum',
      // ✅ Fix: Safe boolean conversion
      isPriority: _safeBoolConversion(json['is_priority']),
    );
  }

  // ✅ Helper method for safe boolean conversion
  static bool _safeBoolConversion(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // ✅ Helper method for safe DateTime parsing
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
}