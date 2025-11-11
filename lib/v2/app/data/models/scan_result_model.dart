// lib/v2/app/data/models/scan_result_model.dart

class ScanResult {
  final String visitId;
  final String status;
  final String parentName;
  final String studentName;
  final String studentClass;
  final String visitPurpose;
  final String scheduleTitle;
  final String? location;
  final int maxDuration;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool canCheckIn;
  final bool canCheckOut;

  ScanResult({
    required this.visitId,
    required this.status,
    required this.parentName,
    required this.studentName,
    required this.studentClass,
    required this.visitPurpose,
    required this.scheduleTitle,
    this.location,
    required this.maxDuration,
    this.checkInTime,
    this.checkOutTime,
    required this.canCheckIn,
    required this.canCheckOut,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      visitId: json['visit_id'],
      status: json['status'],
      parentName: json['parent_name'],
      studentName: json['student_name'],
      studentClass: json['student_class'] ?? '-',
      visitPurpose: json['visit_purpose'] ?? '',
      scheduleTitle: json['schedule_title'],
      location: json['location'],
      maxDuration: json['max_duration'] ?? 60,
      checkInTime:
          json['check_in_time'] != null
              ? DateTime.parse(json['check_in_time'])
              : null,
      checkOutTime:
          json['check_out_time'] != null
              ? DateTime.parse(json['check_out_time'])
              : null,
      canCheckIn: json['can_check_in'] ?? false,
      canCheckOut: json['can_check_out'] ?? false,
    );
  }
}
