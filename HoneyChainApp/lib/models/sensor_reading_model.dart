class SensorReadingModel {
  const SensorReadingModel({
    required this.id,
    required this.hiveId,
    required this.deviceId,
    required this.weightKg,
    required this.temperatureC,
    required this.humidityPercent,
    required this.recordedAt,
  });

  final String id;
  final String hiveId;
  final String deviceId;
  final double weightKg;
  final double temperatureC;
  final double humidityPercent;
  final DateTime recordedAt;

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      id: json['id'] as String,
      hiveId: json['hive_id'] as String,
      deviceId: json['device_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      temperatureC: (json['temperature_c'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hive_id': hiveId,
        'device_id': deviceId,
        'weight_kg': weightKg,
        'temperature_c': temperatureC,
        'humidity_percent': humidityPercent,
        'recorded_at': recordedAt.toIso8601String(),
      };
}
