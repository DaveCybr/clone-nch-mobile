class AttendanceModel {
  final String? id;
  final String scheduleId;
  final String studentId;
  final String status;
  final String? notes;
  final DateTime attendanceTime;

  AttendanceModel({
    this.id,
    required this.scheduleId,
    required this.studentId,
    required this.status,
    this.notes,
    required this.attendanceTime,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    print('Debug: AttendanceModel.fromJson called with: $json');
    try {
      // Handle both attendance_time and attendance_date field names
      String? timeField = json['attendance_time'] ?? json['attendance_date'];

      // Safely parse datetime
      DateTime parsedDateTime;
      if (timeField != null) {
        try {
          parsedDateTime = DateTime.parse(timeField);
        } catch (e) {
          print(
            'Debug: Failed to parse datetime: $timeField, using current time',
          );
          parsedDateTime = DateTime.now();
        }
      } else {
        parsedDateTime = DateTime.now();
      }

      // Parse required fields with strict validation
      final String scheduleId = (json['schedule_id'] ?? '0').toString();
      final String studentId = (json['student_id'] ?? '0').toString();
      final String status = _parseToString(json['status']);

      if (scheduleId == '0' || scheduleId.isEmpty) {
        throw Exception('Invalid schedule_id: ${json['schedule_id']}');
      }
      if (studentId == '0' || studentId.isEmpty) {
        throw Exception('Invalid student_id: ${json['student_id']}');
      }
      if (status.isEmpty) {
        throw Exception('Invalid status: ${json['status']}');
      }

      return AttendanceModel(
        id: (json['id'] ?? '0').toString(),
        scheduleId: scheduleId,
        studentId: studentId,
        status: status,
        notes: json['notes']?.toString(),
        attendanceTime: parsedDateTime,
      );
    } catch (e, stackTrace) {
      print('Debug: Error in AttendanceModel.fromJson: $e');
      print('Debug: JSON data: $json');
      print('Debug: JSON data type: ${json.runtimeType}');
      print('Debug: Error stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper method to safely parse string values
  static String _parseToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'student_id': studentId,
      'status': status,
      'notes': notes,
      'attendance_time': attendanceTime.toIso8601String(),
    };
  }
}
