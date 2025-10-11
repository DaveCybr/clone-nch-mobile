// lib/v2/app/data/models/student_dashboard_model.dart

import 'package:nch_mobile/v2/app/data/models/attendance_model.dart';
import 'package:nch_mobile/v2/app/data/models/user_model.dart';

/// Student Dashboard Response Model
class StudentDashboardModel {
  final UserModel user;
  final ClassModel classInfo;
  final List<StudentScheduleModel> schedulesToday;
  final List<StudentAttendanceItemModel> attendanceToday;
  final AttendanceSummaryStats? stats;

  StudentDashboardModel({
    required this.user,
    required this.classInfo,
    required this.schedulesToday,
    required this.attendanceToday,
    this.stats,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    return StudentDashboardModel(
      user: UserModel.fromJson(json['user'] ?? {}),
      classInfo: ClassModel.fromJson(json['class'] ?? {}),
      schedulesToday:
          (json['schedules_today'] as List?)
              ?.map((e) => StudentScheduleModel.fromJson(e))
              .toList() ??
          [],
      attendanceToday:
          (json['attendance_today'] as List?)
              ?.map((e) => StudentAttendanceItemModel.fromJson(e))
              .toList() ??
          [],
      stats:
          json['stats'] != null
              ? AttendanceSummaryStats.fromJson(json['stats'])
              : null,
    );
  }
}

/// Class Information Model
class ClassModel {
  final String id;
  final String name;
  final String code;
  final String level;
  final String? waliKelas;
  final int? totalStudents;

  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.level,
    this.waliKelas,
    this.totalStudents,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['class_name'] ?? '',
      code: json['code'] ?? json['class_code'] ?? '',
      level: json['level'] ?? '',
      waliKelas: json['wali_kelas'] ?? json['homeroom_teacher'],
      totalStudents: json['total_students'],
    );
  }
}

/// Student Schedule Model
class StudentScheduleModel {
  final String id;
  final String subjectName;
  final String subjectCode;
  final String startTime;
  final String endTime;
  final String day;
  final String? teacherName;
  final String? room;
  final String? notes;

  StudentScheduleModel({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.startTime,
    required this.endTime,
    required this.day,
    this.teacherName,
    this.room,
    this.notes,
  });

  factory StudentScheduleModel.fromJson(Map<String, dynamic> json) {
    return StudentScheduleModel(
      id: json['id']?.toString() ?? '',
      subjectName: json['subject_name'] ?? json['subject'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      day: json['day'] ?? '',
      teacherName: json['teacher_name'] ?? json['teacher'],
      room: json['room'] ?? json['room_name'],
      notes: json['notes'],
    );
  }

  String get timeRange => '$startTime - $endTime';

  bool get isOngoing {
    try {
      final now = DateTime.now();
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

/// Student Attendance Item Model (untuk list attendance)
class StudentAttendanceItemModel {
  final String id;
  final String scheduleId;
  final String subjectName;
  final DateTime date;
  final String status;
  final String? notes;
  final String? teacherName;
  final String? timeRange;

  StudentAttendanceItemModel({
    required this.id,
    required this.scheduleId,
    required this.subjectName,
    required this.date,
    required this.status,
    this.notes,
    this.teacherName,
    this.timeRange,
  });

  factory StudentAttendanceItemModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceItemModel(
      id: json['id']?.toString() ?? '',
      scheduleId: json['schedule_id']?.toString() ?? '',
      subjectName: json['subject_name'] ?? json['subject'] ?? '',
      date: _parseDate(json['date'] ?? json['attendance_date']),
      status: json['status'] ?? json['attendance_status'] ?? 'HADIR',
      notes: json['notes'] ?? json['keterangan'],
      teacherName: json['teacher_name'] ?? json['teacher'],
      timeRange: json['time_range'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
    } catch (e) {
      print('Error parsing date: $value');
    }
    return DateTime.now();
  }

  AttendanceStatus get attendanceStatus => AttendanceStatus.fromString(status);

  String get statusDisplay => attendanceStatus.displayName;
}

/// Attendance Summary Stats (opsional)
class AttendanceSummaryStats {
  final int totalSchedules;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;

  AttendanceSummaryStats({
    required this.totalSchedules,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
  });

  factory AttendanceSummaryStats.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryStats(
      totalSchedules: json['total_schedules'] ?? 0,
      hadir: json['hadir'] ?? 0,
      sakit: json['sakit'] ?? 0,
      izin: json['izin'] ?? 0,
      alpha: json['alpha'] ?? 0,
    );
  }

  double get attendancePercentage {
    if (totalSchedules == 0) return 0.0;
    return (hadir / totalSchedules) * 100;
  }
}

/// Paginated Attendance Response
class PaginatedAttendanceModel {
  final List<StudentAttendanceItemModel> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  PaginatedAttendanceModel({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  factory PaginatedAttendanceModel.fromJson(Map<String, dynamic> json) {
    // Handle Laravel pagination structure
    final paginationData = json['data'] ?? json;

    return PaginatedAttendanceModel(
      data:
          (paginationData['data'] as List?)
              ?.map((e) => StudentAttendanceItemModel.fromJson(e))
              .toList() ??
          [],
      currentPage: paginationData['current_page'] ?? 1,
      lastPage: paginationData['last_page'] ?? 1,
      total: paginationData['total'] ?? 0,
      perPage: paginationData['per_page'] ?? 10,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

/// Schedule List Response (dengan filter tanggal)
class StudentScheduleListModel {
  final List<StudentScheduleModel> schedules;
  final DateTime date;
  final String dayName;

  StudentScheduleListModel({
    required this.schedules,
    required this.date,
    required this.dayName,
  });

  factory StudentScheduleListModel.fromJson(Map<String, dynamic> json) {
    return StudentScheduleListModel(
      schedules:
          (json['schedules'] as List?)
              ?.map((e) => StudentScheduleModel.fromJson(e))
              .toList() ??
          [],
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      dayName: json['day_name'] ?? '',
    );
  }
}
