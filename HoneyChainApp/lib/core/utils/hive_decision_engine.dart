import '../../models/hive_model.dart';
import '../../models/sensor_reading_model.dart';

/// Transparent, rule-based decision support engine for HoneyChain Smart Hive Node telemetry.
///
/// CRITICAL DOMAIN RULE:
/// These decision-support rules ONLY assist beekeeper management and harvest planning.
/// Telemetry metrics DO NOT automatically prove honey maturity, purity, adulteration, or disease.
/// Physical hive inspection and laboratory verification are required for official quality claims.
class HiveDecisionEngine {
  HiveDecisionEngine._();

  /// Evaluates telemetry metrics using deterministic rules:
  ///
  /// RULE 1: APPROACHING HARVEST ASSESSMENT
  /// - Weight >= 44.0 kg AND weight trend is increasing over recent readings.
  /// - Assessment: Approaching Harvest Assessment.
  /// - Action: Physical inspection recommended to verify frame capping & honey maturity.
  ///
  /// RULE 2: CRITICAL ANOMALY / INSPECTION RECOMMENDED
  /// - Temperature > 36.0°C OR Humidity > 65% OR Weight dropping rapidly (< 32.0 kg).
  /// - Assessment: Inspection Recommended / Critical.
  /// - Action: Immediate physical check for hive disturbance, swarming, or thermal stress.
  ///
  /// RULE 3: ATTENTION REQUIRED
  /// - Weight trend is fluctuating OR Temperature between 35.0°C - 36.0°C.
  /// - Assessment: Attention Required.
  /// - Action: Inspect hive during next apiary visit.
  ///
  /// RULE 4: STABLE
  /// - Weight stable (38-43 kg), Temperature 32-35°C, Humidity 50-60%.
  /// - Assessment: Stable.
  /// - Action: Maintain routine monitoring.
  static HiveDecisionResult evaluate({
    required double currentWeightKg,
    required double temperatureC,
    required double humidityPercent,
    required WeightTrend weightTrend,
    required List<SensorReadingModel> recentReadings,
  }) {
    // Check Rule 2: Thermal or Weight Anomaly
    if (temperatureC > 36.0 || humidityPercent > 65.0 || currentWeightKg < 32.0) {
      return const HiveDecisionResult(
        status: HiveStatus.critical,
        assessmentState: AssessmentState.inspectionRecommended,
        insight:
            'Telemetry anomaly detected: elevated temperature/humidity or rapid weight drop.',
        recommendedAction:
            'Conduct immediate physical inspection. Telemetry alerts indicate potential colony stress; sensors cannot diagnose specific diseases or queen issues.',
      );
    }

    // Check Rule 1: Approaching Harvest Assessment
    if (currentWeightKg >= 44.0 && weightTrend == WeightTrend.increasing) {
      return const HiveDecisionResult(
        status: HiveStatus.stable,
        assessmentState: AssessmentState.approachingHarvest,
        insight:
            'Sustained weight buildup indicates potential harvest window.',
        recommendedAction:
            'Run harvest assessment. Confirm frame comb capping (>75%) through physical inspection before harvesting.',
      );
    }

    // Check Rule 3: Attention Required
    if (weightTrend == WeightTrend.fluctuating || temperatureC >= 35.0) {
      return const HiveDecisionResult(
        status: HiveStatus.attention,
        assessmentState: AssessmentState.attention,
        insight:
            'Unusual weight fluctuation or minor temperature rise detected over last 24h.',
        recommendedAction:
            'Schedule physical inspection during next visit to verify colony stability.',
      );
    }

    // Default Rule 4: Stable
    return const HiveDecisionResult(
      status: HiveStatus.stable,
      assessmentState: AssessmentState.stable,
      insight:
          'Weight, temperature, and humidity metrics are within normal seasonal range.',
      recommendedAction:
          'Continue routine monitoring. Sensors assist decision support.',
    );
  }
}

class HiveDecisionResult {
  const HiveDecisionResult({
    required this.status,
    required this.assessmentState,
    required this.insight,
    required this.recommendedAction,
  });

  final HiveStatus status;
  final AssessmentState assessmentState;
  final String insight;
  final String recommendedAction;
}
