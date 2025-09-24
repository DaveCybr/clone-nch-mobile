class JadwalModel {
  final String id;
  final String subjectTeacherId;
  final String day;
  final String timeSlotId;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String subjectCode;
  final String kelasCode;

  JadwalModel({
    required this.id,
    required this.subjectTeacherId,
    required this.day,
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.subjectCode,
    required this.kelasCode,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    // Ambil data dari nested relasi
    final subjectTeacher = json['subject_teacher'] ?? {};
    final subjectSemester = subjectTeacher['subject_semester'] ?? {};
    final subject = subjectSemester['subject'] ?? {};
    final timeSlot = json['time_slot'] ?? {};

    return JadwalModel(
      id: json['id']?.toString() ?? '0',
      subjectTeacherId: json['subject_teacher_id']?.toString() ?? '0',
      day: json['day'] ?? '',
      timeSlotId: json['time_slot_id']?.toString() ?? '0',
      startTime: timeSlot['start_time'] ?? '',
      endTime: timeSlot['end_time'] ?? '',
      subjectName: subject['name'] ?? '',
      subjectCode: subject['code'] ?? '',
      kelasCode: subject['kelas_code'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_teacher_id': subjectTeacherId,
      'day': day,
      'time_slot_id': timeSlotId,
      'start_time': startTime,
      'end_time': endTime,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'kelas_code': kelasCode,
    };
  }
} 