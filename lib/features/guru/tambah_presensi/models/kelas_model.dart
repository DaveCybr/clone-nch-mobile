class KelasModel {
  final String id; // Changed from int to String to support UUID
  final String code;
  final String name;

  KelasModel({required this.id, required this.code, required this.name});

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      id: json['id']?.toString() ?? '0', // Convert to String to support UUID
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'code': code, 'name': name};
  }
}
