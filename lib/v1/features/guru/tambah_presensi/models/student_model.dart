class StudentModel {
  final String id;
  final String name;
  final String nim;
  final String kelasCode;
  final String kelasId;

  StudentModel({
    required this.id,
    required this.name,
    required this.nim,
    required this.kelasCode,
    required this.kelasId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    print('Debug: StudentModel.fromJson called with: $json');

    // Ambil nama dari relasi user jika ada, atau dari field name langsung
    String studentName = '';
    if (json['user'] != null && json['user']['name'] != null) {
      studentName = json['user']['name'].toString();
      print('Debug: Found name in user relation: "$studentName"');
    } else if (json['name'] != null) {
      studentName = json['name'].toString();
      print('Debug: Found name in direct field: "$studentName"');
    } else {
      print('Debug: No name found in JSON');
    }

    return StudentModel(
      id: json['id']?.toString() ?? '0',
      name: studentName,
      nim: json['nim']?.toString() ?? '',
      kelasCode: json['kelas_code']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'kelas_code': kelasCode,
      'kelas_id': kelasId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
