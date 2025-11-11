// lib/v2/app/data/models/visit_schedule_model.dart

class VisitScheduleModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final int maxDurationMinutes;
  final bool isActive;
  final String? creatorName;

  VisitScheduleModel({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.maxDurationMinutes,
    required this.isActive,
    this.creatorName,
  });

  factory VisitScheduleModel.fromJson(Map<String, dynamic> json) {
    return VisitScheduleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      location: json['location'] ?? '',
      maxDurationMinutes: json['max_duration_minutes'] ?? 60,
      isActive: json['is_active'] ?? false,
      creatorName: json['creator']?['name'],
    );
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startAt) && now.isBefore(endAt);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(startAt);
  }

  String get dateRange {
    final start = _formatDate(startAt);
    final end = _formatDate(endAt);
    if (start == end) {
      return '$start ${_formatTime(startAt)} - ${_formatTime(endAt)}';
    }
    return '$start - $end';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class VisitLogModel {
  final String id;
  final String visitScheduleId;
  final String studentId;
  final String parentId;
  final String barcode;
  final String status;
  final String visitPurpose;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int? durationMinutes;
  final String? notes;
  final VisitScheduleModel? visitSchedule;
  final StudentVisitInfo? student;
  final ParentVisitInfo? parent;

  VisitLogModel({
    required this.id,
    required this.visitScheduleId,
    required this.studentId,
    required this.parentId,
    required this.barcode,
    required this.status,
    required this.visitPurpose,
    this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    this.notes,
    this.visitSchedule,
    this.student,
    this.parent,
  });

  factory VisitLogModel.fromJson(Map<String, dynamic> json) {
    return VisitLogModel(
      id: json['id'] ?? '',
      visitScheduleId: json['visit_schedule_id'] ?? '',
      studentId: json['student_id'] ?? '',
      parentId: json['parent_id'] ?? '',
      barcode: json['barcode'] ?? '',
      status: json['status'] ?? 'PENDING',
      visitPurpose: json['visit_purpose'] ?? '',
      checkInTime:
          json['check_in_time'] != null
              ? DateTime.parse(json['check_in_time'])
              : null,
      checkOutTime:
          json['check_out_time'] != null
              ? DateTime.parse(json['check_out_time'])
              : null,
      durationMinutes: json['duration_minutes'],
      notes: json['notes'],
      visitSchedule:
          json['visit_schedule'] != null
              ? VisitScheduleModel.fromJson(json['visit_schedule'])
              : null,
      student:
          json['student'] != null
              ? StudentVisitInfo.fromJson(json['student'])
              : null,
      parent:
          json['parent'] != null
              ? ParentVisitInfo.fromJson(json['parent'])
              : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Menunggu';
      case 'CHECKED_IN':
        return 'Sedang Berkunjung';
      case 'CHECKED_OUT':
        return 'Selesai';
      case 'OVERSTAY':
        return 'Melebihi Batas';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

class StudentVisitInfo {
  final String id;
  final String name;
  final String? className;

  StudentVisitInfo({required this.id, required this.name, this.className});

  factory StudentVisitInfo.fromJson(Map<String, dynamic> json) {
    return StudentVisitInfo(
      id: json['id'] ?? '',
      name: json['user']?['name'] ?? json['name'] ?? '',
      className: json['kelas']?['name'],
    );
  }
}

class ParentVisitInfo {
  final String id;
  final String name;
  final String? phoneNumber;

  ParentVisitInfo({required this.id, required this.name, this.phoneNumber});

  factory ParentVisitInfo.fromJson(Map<String, dynamic> json) {
    return ParentVisitInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'],
    );
  }
}
