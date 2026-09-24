import 'package:flutter/foundation.dart';

import '../models/batch_model.dart';
import '../models/quality_test_model.dart';
import '../repositories/batch_repository.dart';

class BatchService extends ChangeNotifier {
  BatchService({BatchRepository? repository})
      : _repository = repository ?? MockBatchRepository();

  final BatchRepository _repository;

  Future<List<BatchModel>> getBatches({String? beekeeperId}) =>
      _repository.getBatches(beekeeperId: beekeeperId);

  Future<BatchModel?> getBatchByCode(String batchCode) =>
      _repository.getBatchByCode(batchCode);

  Future<BatchModel?> getBatchById(String batchId) =>
      _repository.getBatchById(batchId);

  Future<QualityTestModel?> getQualityTest(String batchId) =>
      _repository.getQualityTest(batchId);

  Future<BatchModel> createBatch(BatchModel batch) async {
    final result = await _repository.createBatch(batch);
    notifyListeners();
    return result;
  }
}
