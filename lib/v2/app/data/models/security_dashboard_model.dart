// lib/v2/app/data/models/security_dashboard_model.dart

class SecurityDashboardData {
  final DashboardStats stats;
  final List<CurrentVisitor> currentVisitors;
  final List<TodaySchedule> todaySchedules;

  SecurityDashboardData({
    required this.stats,
    required this.currentVisitors,
    required this.todaySchedules,
  });

  factory SecurityDashboardData.fromJson(Map<String, dynamic> json) {
    return SecurityDashboardData(
      stats: DashboardStats.fromJson(json['stats']),
      currentVisitors:
          (json['current_visitors'] as List)
              .map((e) => CurrentVisitor.fromJson(e))
              .toList(),
      todaySchedules:
          (json['today_schedules'] as List)
              .map((e) => TodaySchedule.fromJson(e))
              .toList(),
    );
  }
}

class DashboardStats {
  final int totalVisitors;
  final int currentlyVisiting;
  final int checkedOut;
  final int overstay;
  final int pending;

  DashboardStats({
    required this.totalVisitors,
    required this.currentlyVisiting,
    required this.checkedOut,
    required this.overstay,
    required this.pending,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVisitors: json['total_visitors'] ?? 0,
      currentlyVisiting: json['currently_visiting'] ?? 0,
      checkedOut: json['checked_out'] ?? 0,
      overstay: json['overstay'] ?? 0,
      pending: json['pending'] ?? 0,
    );
  }
}

class CurrentVisitor {
  final String id;
  final String barcode;
  final String parentName;
  final String? parentPhone;
  final String studentName;
  final String studentClass;
  final String visitPurpose;
  final DateTime checkInTime;
  final int durationMinutes;
  final int maxDurationMinutes;
  final bool isOverstay;
  final String status;

  CurrentVisitor({
    required this.id,
    required this.barcode,
    required this.parentName,
    this.parentPhone,
    required this.studentName,
    required this.studentClass,
    required this.visitPurpose,
    required this.checkInTime,
    required this.durationMinutes,
    required this.maxDurationMinutes,
    required this.isOverstay,
    required this.status,
  });

  factory CurrentVisitor.fromJson(Map<String, dynamic> json) {
    return CurrentVisitor(
      id: json['id'],
      barcode: json['barcode'],
      parentName: json['parent_name'],
      parentPhone: json['parent_phone'],
      studentName: json['student_name'],
      studentClass: json['student_class'] ?? '-',
      visitPurpose: json['visit_purpose'] ?? '',
      checkInTime: DateTime.parse(json['check_in_time']),
      durationMinutes: json['duration_minutes'] ?? 0,
      maxDurationMinutes: json['max_duration_minutes'] ?? 60,
      isOverstay: json['is_overstay'] ?? false,
      status: json['status'],
    );
  }

  String get durationText {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0) {
      return '$hours jam $mins menit';
    }
    return '$mins menit';
  }

  String get remainingText {
    final remaining = maxDurationMinutes - durationMinutes;
    if (remaining < 0) {
      return 'Melebihi ${-remaining} menit';
    }
    return 'Sisa $remaining menit';
  }
}

class TodaySchedule {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final bool isOngoing;
  final int totalVisitors;
  final int currentVisitors;

  TodaySchedule({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.location,
    required this.isOngoing,
    required this.totalVisitors,
    required this.currentVisitors,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) {
    return TodaySchedule(
      id: json['id'],
      title: json['title'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      location: json['location'],
      isOngoing: json['is_ongoing'] ?? false,
      totalVisitors: json['total_visitors'] ?? 0,
      currentVisitors: json['current_visitors'] ?? 0,
    );
  }
}
