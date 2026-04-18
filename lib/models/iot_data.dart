class IotData {
  final String sensorDataId;
  final String deviceId;
  final String? seasonId;
  final DateTime? recordedAt;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double light;
  final bool isRaining;
  final bool isAlert;
  final DateTime? createdAt;

  IotData({
    required this.sensorDataId,
    required this.deviceId,
    this.seasonId,
    this.recordedAt,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.light,
    required this.isRaining,
    required this.isAlert,
    this.createdAt,
  });

  factory IotData.fromJson(Map<String, dynamic> json) {
    return IotData(
      sensorDataId: json['sensorDataId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      seasonId: json['seasonId'],
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'])
          : null,
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      soilMoisture: (json['soilMoisture'] ?? 0).toDouble(),
      light: (json['light'] ?? 0).toDouble(),
      isRaining: json['isRaining'] ?? false,
      isAlert: json['isAlert'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
