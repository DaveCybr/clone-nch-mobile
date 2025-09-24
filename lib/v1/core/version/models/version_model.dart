class VersionData {
  final String version;
  final bool isActive;
  final String id;

  VersionData({
    required this.version,
    required this.isActive,
    required this.id,
  });

  factory VersionData.fromJson(Map<String, dynamic> json) {
    return VersionData(
      version: json['version'] ?? '',
      isActive: json['is_active'] == 1,
      id: json['id'] ?? '',
    );
  }
}
