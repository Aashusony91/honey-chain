enum HiveStatus {
  stable,
  attention,
  critical;

  String get label => switch (this) {
        HiveStatus.stable => 'Stable',
        HiveStatus.attention => 'Attention',
        HiveStatus.critical => 'Critical',
      };
}

enum WeightTrend {
  stable,
  increasing,
  decreasing,
  fluctuating;

  String get label => switch (this) {
        WeightTrend.stable => 'Stable',
        WeightTrend.increasing => 'Increasing',
        WeightTrend.decreasing => 'Decreasing',
        WeightTrend.fluctuating => 'Fluctuating',
      };
}

enum AssessmentState {
  stable,
  attention,
  approachingHarvest,
  inspectionRecommended;

  String get label => switch (this) {
        AssessmentState.stable => 'Stable',
        AssessmentState.attention => 'Attention',
        AssessmentState.approachingHarvest => 'Approaching Harvest Assessment',
        AssessmentState.inspectionRecommended => 'Inspection Recommended',
      };
}

class HiveModel {
  const HiveModel({
    required this.id,
    required this.name,
    required this.apiaryId,
    required this.deviceId,
    required this.status,
    required this.currentWeightKg,
    required this.temperatureC,
    required this.humidityPercent,
    required this.weightTrend,
    required this.assessmentState,
    required this.insight,
    required this.recommendedAction,
    this.lastReadingAt,
  });

  final String id;
  final String name;
  final String apiaryId;
  final String deviceId;
  final HiveStatus status;
  final double currentWeightKg;
  final double temperatureC;
  final double humidityPercent;
  final WeightTrend weightTrend;
  final AssessmentState assessmentState;
  final String insight;
  final String recommendedAction;
  final DateTime? lastReadingAt;

  HiveModel copyWith({
    String? id,
    String? name,
    String? apiaryId,
    String? deviceId,
    HiveStatus? status,
    double? currentWeightKg,
    double? temperatureC,
    double? humidityPercent,
    WeightTrend? weightTrend,
    AssessmentState? assessmentState,
    String? insight,
    String? recommendedAction,
    DateTime? lastReadingAt,
  }) {
    return HiveModel(
      id: id ?? this.id,
      name: name ?? this.name,
      apiaryId: apiaryId ?? this.apiaryId,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      temperatureC: temperatureC ?? this.temperatureC,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      weightTrend: weightTrend ?? this.weightTrend,
      assessmentState: assessmentState ?? this.assessmentState,
      insight: insight ?? this.insight,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
    );
  }

  factory HiveModel.fromJson(Map<String, dynamic> json) {
    return HiveModel(
      id: json['id'] as String,
      name: json['name'] as String,
      apiaryId: json['apiary_id'] as String,
      deviceId: json['device_id'] as String,
      status: HiveStatus.values.byName(json['status'] as String),
      currentWeightKg: (json['current_weight_kg'] as num).toDouble(),
      temperatureC: (json['temperature_c'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      weightTrend: WeightTrend.values.byName(json['weight_trend'] as String),
      assessmentState:
          AssessmentState.values.byName(json['assessment_state'] as String),
      insight: json['insight'] as String,
      recommendedAction: json['recommended_action'] as String,
      lastReadingAt: json['last_reading_at'] != null
          ? DateTime.parse(json['last_reading_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'apiary_id': apiaryId,
        'device_id': deviceId,
        'status': status.name,
        'current_weight_kg': currentWeightKg,
        'temperature_c': temperatureC,
        'humidity_percent': humidityPercent,
        'weight_trend': weightTrend.name,
        'assessment_state': assessmentState.name,
        'insight': insight,
        'recommended_action': recommendedAction,
        'last_reading_at': lastReadingAt?.toIso8601String(),
      };
}
