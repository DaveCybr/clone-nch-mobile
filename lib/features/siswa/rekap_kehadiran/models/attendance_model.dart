class AttendanceModel {
  final String id;
  final String date;
  final String status;
  final String? note;
  final String? subject;
  final String? teacherName;
  final String? scheduleTime;

  AttendanceModel({
    required this.id,
    required this.date,
    required this.status,
    this.note,
    this.subject,
    this.teacherName,
    this.scheduleTime,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      date:
          json['attendance_date']?.toString() ?? json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      subject:
          json['subject']?['name']?.toString() ??
          json['schedule']?['subject_teacher']?['subject_semester']?['subject']?['name']
              ?.toString(),
      teacherName:
          json['teacher']?['name']?.toString() ??
          json['teacher_name']?.toString() ??
          json['schedule']?['subject_teacher']?['employee']?['user']?['name']
              ?.toString(),
      scheduleTime:
          json['schedule_time']?.toString() ??
          json['schedule']?['time_slot']?['start_time']?.toString(),
    );
  }

  // Helper methods for display
  String get statusDisplay {
    switch (status) {
      case 'HADIR':
        return 'Hadir';
      case 'SAKIT':
        return 'Sakit';
      case 'IZIN':
        return 'Izin';
      case 'ALPHA':
        return 'Alpha';
      default:
        return status;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'HADIR':
        return '✅';
      case 'SAKIT':
        return '🤒';
      case 'IZIN':
        return '📝';
      case 'ALPHA':
        return '❌';
      default:
        return '❓';
    }
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'note': note,
      'subject': subject,
      'teacherName': teacherName,
      'scheduleTime': scheduleTime,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? date,
    String? status,
    String? note,
    String? subject,
    String? teacherName,
    String? scheduleTime,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      scheduleTime: scheduleTime ?? this.scheduleTime,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, date: $date, status: $status, note: $note, subject: $subject, teacherName: $teacherName, scheduleTime: $scheduleTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.id == id &&
        other.date == date &&
        other.status == status &&
        other.note == note &&
        other.subject == subject &&
        other.teacherName == teacherName &&
        other.scheduleTime == scheduleTime;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        status.hashCode ^
        note.hashCode ^
        subject.hashCode ^
        teacherName.hashCode ^
        scheduleTime.hashCode;
  }
}
