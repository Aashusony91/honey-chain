import 'package:flutter/foundation.dart';

import '../models/apiary_model.dart';
import '../models/batch_model.dart';
import '../models/harvest_model.dart';
import '../models/hive_model.dart';
import '../models/sensor_reading_model.dart';
import '../repositories/batch_repository.dart';
import '../repositories/hive_repository.dart';
import '../repositories/mock_data.dart';

class HiveService extends ChangeNotifier {
  HiveService({
    HiveRepository? hiveRepository,
    BatchRepository? batchRepository,
  })  : _hiveRepository = hiveRepository ?? MockHiveRepository(),
        _batchRepository = batchRepository ?? MockBatchRepository();

  final HiveRepository _hiveRepository;
  final BatchRepository _batchRepository;

  Future<List<HiveModel>> getHives({String? beekeeperId}) =>
      _hiveRepository.getHives(beekeeperId: beekeeperId);

  Future<HiveModel?> getHiveById(String hiveId) =>
      _hiveRepository.getHiveById(hiveId);

  Future<List<SensorReadingModel>> getWeightHistory(String hiveId) =>
      _hiveRepository.getWeightHistory(hiveId);

  Future<List<SensorReadingModel>> getRecentReadings(String hiveId) =>
      _hiveRepository.getRecentReadings(hiveId);

  Future<List<ApiaryModel>> getApiaries({String? beekeeperId}) =>
      _hiveRepository.getApiaries(beekeeperId: beekeeperId);

  Future<BeekeeperDashboardData> getDashboardData({String? beekeeperId}) =>
      _hiveRepository.getDashboardData(beekeeperId: beekeeperId);

  Future<({HarvestModel harvest, BatchModel batch})> submitHarvest({
    required String hiveId,
    required String beekeeperId,
    required String beekeeperName,
    required String hiveName,
    required String apiaryName,
    required String origin,
    required double quantityKg,
    required DateTime harvestDate,
    required String floralSource,
    required String notes,
  }) async {
    final batchCode = MockData.generateBatchCode();
    final harvest = await _hiveRepository.recordHarvest(
      hiveId: hiveId,
      beekeeperId: beekeeperId,
      quantityKg: quantityKg,
      harvestDate: harvestDate,
      floralSource: floralSource,
      notes: notes,
      batchCode: batchCode,
    );

    final batch = BatchModel(
      id: 'batch-${DateTime.now().millisecondsSinceEpoch}',
      batchCode: batchCode,
      hiveId: hiveId,
      hiveName: hiveName,
      apiaryName: apiaryName,
      origin: origin,
      beekeeperId: beekeeperId,
      beekeeperName: beekeeperName,
      harvestDate: harvestDate,
      quantityKg: quantityKg,
      floralSource: floralSource,
      qualityStatus: StageStatus.pending,
      processingStatus: StageStatus.pending,
      packagingStatus: StageStatus.pending,
      blockchainStatus: BlockchainStatus.notRegistered,
      timeline: MockData.newBatchTimeline(harvestDate),
      notes: notes,
    );

    await _batchRepository.createBatch(batch);

    // Update in-memory hive state after harvest
    final hiveIndex = MockData.hives.indexWhere((h) => h.id == hiveId);
    if (hiveIndex >= 0) {
      final oldHive = MockData.hives[hiveIndex];
      final newWeight = (oldHive.currentWeightKg - quantityKg).clamp(25.0, 60.0);
      MockData.hives[hiveIndex] = oldHive.copyWith(
        currentWeightKg: newWeight,
        status: HiveStatus.stable,
        weightTrend: WeightTrend.stable,
        assessmentState: AssessmentState.stable,
        insight:
            'Harvest of ${quantityKg.toStringAsFixed(1)} kg recorded on ${harvestDate.day}/${harvestDate.month}/${harvestDate.year}. Telemetry baseline reset.',
        recommendedAction:
            'Routine monitoring resumed. Inspect hive in 7 days.',
      );
    }

    notifyListeners();
    return (harvest: harvest, batch: batch);
  }
}
