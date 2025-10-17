// lib/v2/app/data/models/attendance_model.dart

class ScheduleDetailModel {
  final String scheduleId;
  final String subjectName;
  final String className;
  final String day;
  final String startTime;
  final String endTime;
  final DateTime attendanceDate;
  final int totalStudents;
  final List<StudentAttendanceModel> students;

  const ScheduleDetailModel({
    required this.scheduleId,
    required this.subjectName,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.attendanceDate,
    required this.totalStudents,
    required this.students,
  });

  factory ScheduleDetailModel.fromJson(Map<String, dynamic> json) {
    return ScheduleDetailModel(
      scheduleId: json['schedule_id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      className: json['class_name'] ?? '',
      day: json['day'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      attendanceDate: _parseDate(json['attendance_date']),
      totalStudents: json['total_students'] ?? 0,
      students:
          (json['students'] as List?)
              ?.map((e) => StudentAttendanceModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String get timeRange => '$startTime - $endTime';
}

class StudentAttendanceModel {
  final String studentId;
  final String name;
  final String nisn;
  final AttendanceStatus currentStatus;
  final String? attendanceId;
  final String? notes;

  const StudentAttendanceModel({
    required this.studentId,
    required this.name,
    required this.nisn,
    required this.currentStatus,
    this.attendanceId,
    this.notes,
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      studentId: json['student_id'] ?? '',
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      currentStatus: AttendanceStatus.fromString(json['current_status']),
      attendanceId: json['attendance_id'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'nisn': nisn,
      'current_status': currentStatus.value,
      'attendance_id': attendanceId,
      'notes': notes,
    };
  }

  StudentAttendanceModel copyWith({
    AttendanceStatus? currentStatus,
    String? notes,
  }) {
    return StudentAttendanceModel(
      studentId: studentId,
      name: name,
      nisn: nisn,
      currentStatus: currentStatus ?? this.currentStatus,
      attendanceId: attendanceId,
      notes: notes ?? this.notes,
    );
  }
}

enum AttendanceStatus {
  hadir('HADIR', 'Hadir'),
  sakit('SAKIT', 'Sakit'),
  izin('IZIN', 'Izin'),
  alpha('ALPHA', 'Alpha');

  const AttendanceStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static AttendanceStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'HADIR':
        return AttendanceStatus.hadir;
      case 'SAKIT':
        return AttendanceStatus.sakit;
      case 'IZIN':
        return AttendanceStatus.izin;
      case 'ALPHA':
        return AttendanceStatus.alpha;
      default:
        return AttendanceStatus.hadir;
    }
  }
}

class AttendanceSubmissionModel {
  final String scheduleId;
  final DateTime attendanceDate;
  final List<AttendanceRecordModel> attendances;

  const AttendanceSubmissionModel({
    required this.scheduleId,
    required this.attendanceDate,
    required this.attendances,
  });

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      'attendances': attendances.map((e) => e.toJson()).toList(),
    };
  }
}

class AttendanceRecordModel {
  final String studentId;
  final AttendanceStatus status;
  final String? notes;
  final String? attendanceId;

  const AttendanceRecordModel({
    required this.studentId,
    required this.status,
    this.notes,
    this.attendanceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'status': status.value,
      'notes': notes,
      'attendance_id': attendanceId,
    };
  }
}

class StudentHistoryModel {
  final String studentId;
  final String name;
  final String nisn;
  final String className;
  final AttendanceSummaryModel summary;
  final List<AttendanceHistoryRecordModel> history;

  const StudentHistoryModel({
    required this.studentId,
    required this.name,
    required this.nisn,
    required this.className,
    required this.summary,
    required this.history,
  });

  factory StudentHistoryModel.fromJson(Map<String, dynamic> json) {
    if (json['student'] != null && json['student'] is Map) {
      final studentData = json['student'] as Map<String, dynamic>;
      return StudentHistoryModel(
        studentId: studentData['student_id'] ?? studentData['id'] ?? '',
        name: studentData['name'] ?? '',
        nisn: studentData['nisn'] ?? '',
        className: studentData['class'] ?? studentData['class_name'] ?? '',
        summary: AttendanceSummaryModel.fromJson(json['summary'] ?? {}),
        history: _parseHistory(json['history']),
      );
    }

    return StudentHistoryModel(
      studentId: json['student_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['student_name'] ?? '',
      nisn: json['nisn'] ?? '',
      className: json['class_name'] ?? json['class'] ?? '',
      summary: AttendanceSummaryModel.fromJson(json['summary'] ?? {}),
      history: _parseHistory(json['history']),
    );
  }

  static List<AttendanceHistoryRecordModel> _parseHistory(dynamic historyData) {
    if (historyData == null) return [];
    if (historyData is! List) return [];

    return historyData
        .map((e) {
          try {
            return AttendanceHistoryRecordModel.fromJson(
              e as Map<String, dynamic>,
            );
          } catch (ex) {
            print('⚠️ Error parsing history record: $ex');
            return null;
          }
        })
        .whereType<AttendanceHistoryRecordModel>()
        .toList();
  }
}

class AttendanceSummaryModel {
  final int totalSessions;
  final int hadir;
  final int sakit;
  final int izin;
  final int alpha;

  const AttendanceSummaryModel({
    required this.totalSessions,
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.alpha,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      totalSessions: _parseInt(json['total_sessions']),
      hadir: _parseInt(json['hadir']),
      sakit: _parseInt(json['sakit']),
      izin: _parseInt(json['izin']),
      alpha: _parseInt(json['alpha']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  double get attendancePercentage {
    if (totalSessions == 0) return 0.0;
    return (hadir / totalSessions) * 100;
  }

  @override
  String toString() {
    return 'AttendanceSummary(total: $totalSessions, hadir: $hadir, sakit: $sakit, izin: $izin, alpha: $alpha, percentage: ${attendancePercentage.toStringAsFixed(1)}%)';
  }
}

class AttendanceHistoryRecordModel {
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  const AttendanceHistoryRecordModel({
    required this.date,
    required this.status,
    this.notes,
  });

  factory AttendanceHistoryRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryRecordModel(
      date: _parseDate(json['date'] ?? json['attendance_date']),
      status: AttendanceStatus.fromString(
        json['status'] ?? json['attendance_status'],
      ),
      notes: json['notes'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is DateTime) {
        return value;
      }
    } catch (e) {
      print('⚠️ Error parsing date: $value - $e');
    }

    return DateTime.now();
  }
}

// ✅ UPDATED: Model untuk data kelas dari today_schedules
class TeacherClassModel {
  final String scheduleId;
  final String subjectName;
  final String className;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final String day;
  final bool isDone;
  final int studentCount;
  final List<StudentSummaryModel> students;

  const TeacherClassModel({
    required this.scheduleId,
    required this.subjectName,
    required this.className,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.isDone,
    required this.studentCount,
    this.students = const [],
  });

  // ✅ Factory untuk parsing dari API response today_schedules
  factory TeacherClassModel.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Tambahkan 'subject_id' sebagai opsi pertama!
    final scheduleId =
        json['subject_id']?.toString() ?? // ⭐ TAMBAH INI!
        json['schedule_id']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['scheduleId']?.toString() ??
        '';

    // ✅ Log warning jika ID tidak ditemukan
    if (scheduleId.isEmpty) {
      print('⚠️ WARNING: No valid schedule ID found in JSON: $json');
    }

    return TeacherClassModel(
      scheduleId: scheduleId,
      subjectName: json['subject_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      timeSlot: json['time_slot']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      isDone: json['is_done'] == true || json['is_done'] == 1,
      studentCount:
          int.tryParse(json['student_count']?.toString() ?? '0') ??
          0, // ✅ Fix: gunakan 'student_count'
      students:
          (json['students'] as List?)
              ?.map((e) => StudentSummaryModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  // ✅ Getter untuk compatibility dengan kode yang sudah ada
  String get subjectId => scheduleId;

  // ✅ CopyWith untuk update students setelah fetch dari API terpisah
  TeacherClassModel copyWith({List<StudentSummaryModel>? students}) {
    return TeacherClassModel(
      scheduleId: scheduleId,
      subjectName: subjectName,
      className: className,
      timeSlot: timeSlot,
      startTime: startTime,
      endTime: endTime,
      day: day,
      isDone: isDone,
      studentCount: studentCount,
      students: students ?? this.students,
    );
  }
}

class StudentSummaryModel {
  final String studentId;
  final String name;
  final String nisn;
  final double attendancePercentage;

  const StudentSummaryModel({
    required this.studentId,
    required this.name,
    required this.nisn,
    required this.attendancePercentage,
  });

  factory StudentSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentSummaryModel(
      studentId: json['student_id'] ?? '',
      name: json['name'] ?? '',
      nisn: json['nisn'] ?? '',
      attendancePercentage: _parseDouble(json['attendance_percentage']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
