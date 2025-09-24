class MataPelajaranModel {
  final String id; // Changed from int to String to support UUID
  final String name;
  final String code;
  final String kelasId; // Changed from int to String to support UUID
  final String kelasCode;

  MataPelajaranModel({
    required this.id,
    required this.name,
    required this.code,
    required this.kelasId,
    required this.kelasCode,
  });

  factory MataPelajaranModel.fromJson(Map<String, dynamic> json) {
    return MataPelajaranModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      kelasId: json['kelas_id']?.toString() ?? '0', // Convert to String to support UUID
      kelasCode: json['kelas']?['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code, 'kelas_id': kelasId};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MataPelajaranModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
