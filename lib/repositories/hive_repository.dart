import '../core/constants/app_constants.dart';
import '../models/apiary_model.dart';
import '../models/batch_model.dart';
import '../models/harvest_model.dart';
import '../models/hive_model.dart';
import '../models/sensor_reading_model.dart';
import 'mock_data.dart';

class HiveOverviewStats {
  const HiveOverviewStats({
    required this.totalHives,
    required this.stableHives,
    required this.attentionHives,
    required this.criticalHives,
  });

  final int totalHives;
  final int stableHives;
  final int attentionHives;
  final int criticalHives;
}

class BeekeeperDashboardData {
  const BeekeeperDashboardData({
    required this.stats,
    required this.totalWeightKg,
    required this.latestHarvestKg,
    required this.activeBatches,
    required this.pendingQualityChecks,
    required this.alertHives,
    required this.harvestCandidates,
    required this.recentBatches,
  });

  final HiveOverviewStats stats;
  final double totalWeightKg;
  final double latestHarvestKg;
  final int activeBatches;
  final int pendingQualityChecks;
  final List<HiveModel> alertHives;
  final List<HiveModel> harvestCandidates;
  final List<String> recentBatches;
}

abstract class HiveRepository {
  Future<List<HiveModel>> getHives({String? beekeeperId});
  Future<HiveModel?> getHiveById(String hiveId);
  Future<List<SensorReadingModel>> getWeightHistory(String hiveId);
  Future<List<SensorReadingModel>> getRecentReadings(String hiveId);
  Future<List<ApiaryModel>> getApiaries({String? beekeeperId});
  Future<BeekeeperDashboardData> getDashboardData({String? beekeeperId});
  Future<HarvestModel> recordHarvest({
    required String hiveId,
    required String beekeeperId,
    required double quantityKg,
    required DateTime harvestDate,
    required String floralSource,
    required String notes,
    required String batchCode,
  });
}

class MockHiveRepository implements HiveRepository {
  @override
  Future<List<HiveModel>> getHives({String? beekeeperId}) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return List.from(MockData.hives);
  }

  @override
  Future<HiveModel?> getHiveById(String hiveId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return MockData.hives.firstWhere((h) => h.id == hiveId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SensorReadingModel>> getWeightHistory(String hiveId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return MockData.weightHistory(hiveId);
  }

  @override
  Future<List<SensorReadingModel>> getRecentReadings(String hiveId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return MockData.recentReadings(hiveId);
  }

  @override
  Future<List<ApiaryModel>> getApiaries({String? beekeeperId}) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return [MockData.apiary];
  }

  @override
  Future<BeekeeperDashboardData> getDashboardData({String? beekeeperId}) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    final hives = MockData.hives;
    return BeekeeperDashboardData(
      stats: HiveOverviewStats(
        totalHives: hives.length,
        stableHives: hives.where((h) => h.status == HiveStatus.stable).length,
        attentionHives:
            hives.where((h) => h.status == HiveStatus.attention).length,
        criticalHives:
            hives.where((h) => h.status == HiveStatus.critical).length,
      ),
      totalWeightKg: hives.fold(0.0, (sum, h) => sum + h.currentWeightKg),
      latestHarvestKg: 12.5,
      activeBatches: MockData.batches.length,
      pendingQualityChecks: MockData.batches
          .where((b) => b.qualityStatus != StageStatus.verified)
          .length,
      alertHives: hives
          .where((h) =>
              h.status == HiveStatus.attention ||
              h.status == HiveStatus.critical)
          .toList(),
      harvestCandidates: hives
          .where((h) =>
              h.assessmentState == AssessmentState.approachingHarvest)
          .toList(),
      recentBatches:
          MockData.batches.map((b) => b.batchCode).take(3).toList(),
    );
  }

  @override
  Future<HarvestModel> recordHarvest({
    required String hiveId,
    required String beekeeperId,
    required double quantityKg,
    required DateTime harvestDate,
    required String floralSource,
    required String notes,
    required String batchCode,
  }) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    return HarvestModel(
      id: 'harvest-${DateTime.now().millisecondsSinceEpoch}',
      hiveId: hiveId,
      beekeeperId: beekeeperId,
      quantityKg: quantityKg,
      harvestDate: harvestDate,
      floralSource: floralSource,
      notes: notes,
      batchId: batchCode,
      createdAt: DateTime.now(),
    );
  }
}
