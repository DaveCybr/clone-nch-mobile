// lib/v2/app/data/models/student_dashboard_model.dart

import 'package:nch_mobile/v2/app/data/models/attendance_model.dart';
import 'package:nch_mobile/v2/app/data/models/user_model.dart';

class StudentDashboardModel {
  final UserModel user;
  final ClassModel classInfo;
  final List<ScheduleModel> schedulesToday;
  final List<StudentAttendanceModel> attendanceToday;

  StudentDashboardModel({
    required this.user,
    required this.classInfo,
    required this.schedulesToday,
    required this.attendanceToday,
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    return StudentDashboardModel(
      user: UserModel.fromJson(json['user']),
      classInfo: ClassModel.fromJson(json['class']),
      schedulesToday:
          (json['schedules_today'] as List)
              .map((e) => ScheduleModel.fromJson(e))
              .toList(),
      attendanceToday:
          (json['attendance_today'] as List)
              .map((e) => StudentAttendanceModel.fromJson(e))
              .toList(),
    );
  }
}

class ClassModel {
  final String id;
  final String name;
  final String code;
  final String level;

  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.level,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      level: json['level'] ?? '',
    );
  }
}

class ScheduleModel {
  final String id;
  final String subjectName;
  final String startTime;
  final String endTime;
  final String day;
  final String? teacherName;

  ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.day,
    this.teacherName,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      subjectName: json['subject_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      day: json['day'] ?? '',
      teacherName: json['teacher_name'],
    );
  }

  String get timeRange => '$startTime - $endTime';
}
