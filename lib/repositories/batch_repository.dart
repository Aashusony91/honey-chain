import '../core/constants/app_constants.dart';
import '../models/batch_model.dart';
import '../models/quality_test_model.dart';
import 'mock_data.dart';

abstract class BatchRepository {
  Future<List<BatchModel>> getBatches({String? beekeeperId});
  Future<BatchModel?> getBatchByCode(String batchCode);
  Future<BatchModel?> getBatchById(String batchId);
  Future<QualityTestModel?> getQualityTest(String batchId);
  Future<BatchModel> createBatch(BatchModel batch);
}

class MockBatchRepository implements BatchRepository {
  final List<BatchModel> _batches = List.from(MockData.batches);

  @override
  Future<List<BatchModel>> getBatches({String? beekeeperId}) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    if (beekeeperId == null) return List.from(_batches);
    return _batches.where((b) => b.beekeeperId == beekeeperId).toList();
  }

  @override
  Future<BatchModel?> getBatchByCode(String batchCode) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return _batches.firstWhere(
        (b) => b.batchCode.toUpperCase() == batchCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BatchModel?> getBatchById(String batchId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return _batches.firstWhere((b) => b.id == batchId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<QualityTestModel?> getQualityTest(String batchId) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    try {
      return MockData.qualityTests.firstWhere((q) => q.batchId == batchId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BatchModel> createBatch(BatchModel batch) async {
    await Future<void>.delayed(AppConstants.mockNetworkDelay);
    _batches.insert(0, batch);
    return batch;
  }
}
