class IotDevice {
  final String deviceId;
  final String? bedId;
  final String deviceCode;
  final String name;
  final String type;
  final String status;
  final DateTime? lastActiveAt;

  IotDevice({
    required this.deviceId,
    this.bedId,
    required this.deviceCode,
    required this.name,
    required this.type,
    required this.status,
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
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'])
          : null,
    );
  }
}
