class IotDevice {
  final String deviceId;
  final String? bedId;
  final String deviceCode;
  final String name;
  final String type;
  final String status;
  final DateTime? installationDate;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  IotDevice({
    required this.deviceId,
    this.bedId,
    required this.deviceCode,
    required this.name,
    required this.type,
    required this.status,
    this.installationDate,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.lastActiveAt,
  });

  factory IotDevice.fromJson(Map<String, dynamic> json) {
    return IotDevice(
      deviceId: json['deviceId'] ?? '',
      bedId: json['bedId'],
      deviceCode: json['deviceCode'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      installationDate: json['installationDate'] != null
          ? DateTime.parse(json['installationDate'])
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
    );
  }
}
