// lib/v2/app/data/models/visit_log_model.dart

import 'package:flutter/material.dart';

class VisitLog {
  final String id;
  final String barcode;
  final String visitScheduleId;
  final String studentId;
  final String parentUserId;
  final String visitPurpose;
  final VisitStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final CheckedByUser? checkedInBy;
  final CheckedByUser? checkedOutBy;
  final int? durationMinutes;
  final String? notes;

  // Relations
  final ParentUser? parent;
  final StudentVisit? student;
  final VisitSchedule? visitSchedule;

  VisitLog({
    required this.id,
    required this.barcode,
    required this.visitScheduleId,
    required this.studentId,
    required this.parentUserId,
    required this.visitPurpose,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.checkedInBy,
    this.checkedOutBy,
    this.durationMinutes,
    this.notes,
    this.parent,
    this.student,
    this.visitSchedule,
  });

  factory VisitLog.fromJson(Map<String, dynamic> json) {
    return VisitLog(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      visitScheduleId: json['visit_schedule_id'] ?? '',
      studentId: json['student_id'] ?? '',
      parentUserId: json['parent_user_id'] ?? '',
      visitPurpose: json['visit_purpose'] ?? '',
      status: VisitStatusExtension.fromString(json['status'] ?? 'PENDING'),
      checkInTime:
          json['check_in_time'] != null
              ? DateTime.parse(json['check_in_time'])
              : null,
      checkOutTime:
          json['check_out_time'] != null
              ? DateTime.parse(json['check_out_time'])
              : null,
      checkedInBy:
          json['checked_in_by'] != null && json['checked_in_by'] is Map
              ? CheckedByUser.fromJson(json['checked_in_by'])
              : null,
      checkedOutBy:
          json['checked_out_by'] != null && json['checked_out_by'] is Map
              ? CheckedByUser.fromJson(json['checked_out_by'])
              : null,
      durationMinutes: json['duration_minutes'],
      notes: json['notes'],
      parent:
          json['parent'] != null && json['parent'] is Map
              ? ParentUser.fromJson(json['parent'])
              : null,
      student:
          json['student'] != null && json['student'] is Map
              ? StudentVisit.fromJson(json['student'])
              : null,
      visitSchedule:
          json['visit_schedule'] != null && json['visit_schedule'] is Map
              ? VisitSchedule.fromJson(json['visit_schedule'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'visit_schedule_id': visitScheduleId,
      'student_id': studentId,
      'parent_user_id': parentUserId,
      'visit_purpose': visitPurpose,
      'status': status.value,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'checked_in_by': checkedInBy?.toJson(),
      'checked_out_by': checkedOutBy?.toJson(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    };
  }

  bool get isOverstay => status == VisitStatus.overstay;
  bool get canCheckIn => status == VisitStatus.pending;
  bool get canCheckOut =>
      status == VisitStatus.checkedIn || status == VisitStatus.overstay;
}

enum VisitStatus { pending, checkedIn, checkedOut, overstay, cancelled }

extension VisitStatusExtension on VisitStatus {
  String get value {
    switch (this) {
      case VisitStatus.pending:
        return 'PENDING';
      case VisitStatus.checkedIn:
        return 'CHECKED_IN';
      case VisitStatus.checkedOut:
        return 'CHECKED_OUT';
      case VisitStatus.overstay:
        return 'OVERSTAY';
      case VisitStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case VisitStatus.pending:
        return 'Menunggu';
      case VisitStatus.checkedIn:
        return 'Sedang Berkunjung';
      case VisitStatus.checkedOut:
        return 'Selesai';
      case VisitStatus.overstay:
        return 'Melebihi Waktu';
      case VisitStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case VisitStatus.pending:
        return Colors.orange;
      case VisitStatus.checkedIn:
        return Colors.green;
      case VisitStatus.checkedOut:
        return Colors.blue;
      case VisitStatus.overstay:
        return Colors.red;
      case VisitStatus.cancelled:
        return Colors.grey;
    }
  }

  static VisitStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return VisitStatus.pending;
      case 'CHECKED_IN':
        return VisitStatus.checkedIn;
      case 'CHECKED_OUT':
        return VisitStatus.checkedOut;
      case 'OVERSTAY':
        return VisitStatus.overstay;
      case 'CANCELLED':
        return VisitStatus.cancelled;
      default:
        return VisitStatus.pending;
    }
  }
}

// Supporting Models
class ParentUser {
  final String id;
  final String name;
  final String? phoneNumber;

  ParentUser({required this.id, required this.name, this.phoneNumber});

  factory ParentUser.fromJson(Map<String, dynamic> json) {
    return ParentUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone_number': phoneNumber};
  }
}

class StudentVisit {
  final String id;
  final UserInfo user;
  final Kelas? kelas;

  StudentVisit({required this.id, required this.user, this.kelas});

  factory StudentVisit.fromJson(Map<String, dynamic> json) {
    return StudentVisit(
      id: json['id'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
      kelas:
          json['kelas'] != null && json['kelas'] is Map
              ? Kelas.fromJson(json['kelas'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'user': user.toJson(), 'kelas': kelas?.toJson()};
  }
}

class UserInfo {
  final String id;
  final String name;

  UserInfo({required this.id, required this.name});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(id: json['id'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class Kelas {
  final String id;
  final String name;

  Kelas({required this.id, required this.name});

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(id: json['id'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class CheckedByUser {
  final String id;
  final String name;

  CheckedByUser({required this.id, required this.name});

  factory CheckedByUser.fromJson(Map<String, dynamic> json) {
    return CheckedByUser(id: json['id'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class VisitSchedule {
  final String id;
  final String title;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? location;
  final int? maxDurationMinutes;
  final int? totalVisitors;
  final int? currentVisitors;
  final bool? isOngoing;

  VisitSchedule({
    required this.id,
    required this.title,
    this.startAt,
    this.endAt,
    this.location,
    this.maxDurationMinutes,
    this.totalVisitors,
    this.currentVisitors,
    this.isOngoing,
  });

  factory VisitSchedule.fromJson(Map<String, dynamic> json) {
    return VisitSchedule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startAt:
          json['start_at'] != null ? DateTime.parse(json['start_at']) : null,
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
      location: json['location'],
      maxDurationMinutes: json['max_duration_minutes'],
      totalVisitors: json['total_visitors'],
      currentVisitors: json['current_visitors'],
      isOngoing: json['is_ongoing'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'location': location,
      'max_duration_minutes': maxDurationMinutes,
      'total_visitors': totalVisitors,
      'current_visitors': currentVisitors,
      'is_ongoing': isOngoing,
    };
  }
}
