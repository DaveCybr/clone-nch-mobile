class TimeSlotModel {
  final String id;
  final String startTime;
  final String endTime;

  TimeSlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id']?.toString() ?? '0',
      startTime: json['start_time'] ?? json['startTime'] ?? '',
      endTime: json['end_time'] ?? json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'start_time': startTime, 'end_time': endTime};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimeSlotModel &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => id.hashCode ^ startTime.hashCode ^ endTime.hashCode;

  @override
  String toString() {
    return '$startTime - $endTime';
  }
}
