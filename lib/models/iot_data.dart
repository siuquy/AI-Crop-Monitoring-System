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
  });

  factory IotData.fromJson(Map<String, dynamic> json) {
    return IotData(
      sensorDataId: json['sensorDataId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      seasonId: json['seasonId'],
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'])
          : null,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      soilMoisture: (json['soilMoisture'] as num?)?.toDouble() ?? 0.0,
      light: (json['light'] as num?)?.toDouble() ?? 0.0,
      isRaining: json['isRaining'] ?? false,
      isAlert: json['isAlert'] ?? false,
    );
  }
}
