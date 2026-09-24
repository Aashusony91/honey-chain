import '../models/apiary_model.dart';
import '../models/batch_model.dart';
import '../models/hive_model.dart';
import '../models/product_model.dart';
import '../models/quality_test_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/user_model.dart';

class MockData {
  MockData._();

  static const beekeeperId = 'user-bk-001';
  static const consumerId = 'user-cs-001';

  static const demoUser = UserModel(
    id: beekeeperId,
    fullName: 'Rajesh Kumar',
    email: 'rajesh@honeychain.demo',
    phone: '+91 98765 43210',
    location: 'Jammu, Jammu & Kashmir',
    role: UserRole.beekeeper,
    isVerified: true,
    apiaryIds: ['apiary-001'],
    createdAt: null,
  );

  static const demoConsumer = UserModel(
    id: consumerId,
    fullName: 'Priya Sharma',
    email: 'priya@honeychain.demo',
    phone: '+91 91234 56789',
    location: 'Srinagar, Jammu & Kashmir',
    role: UserRole.consumer,
    isVerified: true,
  );

  static const apiary = ApiaryModel(
    id: 'apiary-001',
    name: 'Kashmir Valley Apiary',
    location: 'Pahalgam, Jammu & Kashmir',
    beekeeperId: beekeeperId,
    hiveIds: ['hive-001', 'hive-002', 'hive-003', 'hive-004', 'hive-005'],
    description: 'High-altitude apiary with acacia and wildflower sources.',
  );

  static final hives = <HiveModel>[
    HiveModel(
      id: 'hive-001',
      name: 'Hive Alpha',
      apiaryId: 'apiary-001',
      deviceId: 'ESP32-HC-001',
      status: HiveStatus.stable,
      currentWeightKg: 42.8,
      temperatureC: 34.2,
      humidityPercent: 58,
      weightTrend: WeightTrend.stable,
      assessmentState: AssessmentState.stable,
      insight:
          'Weight and environmental readings are within expected seasonal range.',
      recommendedAction: 'Continue routine monitoring. Next inspection in 5 days.',
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    HiveModel(
      id: 'hive-002',
      name: 'Hive Beta',
      apiaryId: 'apiary-001',
      deviceId: 'ESP32-HC-002',
      status: HiveStatus.attention,
      currentWeightKg: 38.1,
      temperatureC: 35.8,
      humidityPercent: 62,
      weightTrend: WeightTrend.fluctuating,
      assessmentState: AssessmentState.attention,
      insight:
          'Unusual weight variation detected over the last 24 hours. Inspect hive and verify colony condition.',
      recommendedAction:
          'Physical inspection recommended. Check for swarming signs or external disturbance.',
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    HiveModel(
      id: 'hive-003',
      name: 'Hive Gamma',
      apiaryId: 'apiary-001',
      deviceId: 'ESP32-HC-003',
      status: HiveStatus.stable,
      currentWeightKg: 45.6,
      temperatureC: 33.9,
      humidityPercent: 55,
      weightTrend: WeightTrend.increasing,
      assessmentState: AssessmentState.approachingHarvest,
      insight:
          'Sustained weight increase over 14 days suggests potential harvest window. Confirm readiness through physical inspection.',
      recommendedAction:
          'Run harvest assessment. Do not harvest based on sensors alone.',
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    HiveModel(
      id: 'hive-004',
      name: 'Hive Delta',
      apiaryId: 'apiary-001',
      deviceId: 'ESP32-HC-004',
      status: HiveStatus.critical,
      currentWeightKg: 31.4,
      temperatureC: 36.5,
      humidityPercent: 68,
      weightTrend: WeightTrend.decreasing,
      assessmentState: AssessmentState.inspectionRecommended,
      insight:
          'Rapid weight decrease and elevated humidity may indicate colony stress. Immediate inspection advised.',
      recommendedAction:
          'Inspect immediately for disease, pest activity, or queen issues. Sensors cannot diagnose colony health.',
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    HiveModel(
      id: 'hive-005',
      name: 'Hive Epsilon',
      apiaryId: 'apiary-001',
      deviceId: 'ESP32-HC-005',
      status: HiveStatus.stable,
      currentWeightKg: 40.2,
      temperatureC: 34.0,
      humidityPercent: 57,
      weightTrend: WeightTrend.stable,
      assessmentState: AssessmentState.stable,
      insight: 'Colony metrics appear consistent with healthy seasonal activity.',
      recommendedAction: 'Maintain regular monitoring schedule.',
      lastReadingAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  static List<SensorReadingModel> weightHistory(String hiveId) {
    final base = switch (hiveId) {
      'hive-001' => 41.0,
      'hive-002' => 37.5,
      'hive-003' => 42.0,
      'hive-004' => 34.0,
      'hive-005' => 39.5,
      _ => 40.0,
    };
    final now = DateTime.now();
    return List.generate(7, (i) {
      final dayOffset = 6 - i;
      final variation = (i % 3 - 1) * 0.4 + (hiveId == 'hive-003' ? i * 0.5 : 0);
      return SensorReadingModel(
        id: 'reading-$hiveId-$i',
        hiveId: hiveId,
        deviceId: 'ESP32-HC-${hiveId.split('-').last}',
        weightKg: base + variation,
        temperatureC: 33.5 + (i % 2) * 0.8,
        humidityPercent: 55 + (i % 3) * 2,
        recordedAt: DateTime(now.year, now.month, now.day - dayOffset, 8, 0),
      );
    });
  }

  static List<SensorReadingModel> recentReadings(String hiveId) {
    final history = weightHistory(hiveId);
    return history.reversed.take(5).toList();
  }

  static final batches = <BatchModel>[
    BatchModel(
      id: 'batch-001',
      batchCode: 'HC-JH-2026-00017',
      hiveId: 'hive-003',
      hiveName: 'Hive Gamma',
      apiaryName: 'Kashmir Valley Apiary',
      origin: 'Pahalgam, Jammu & Kashmir',
      beekeeperId: beekeeperId,
      beekeeperName: 'Rajesh Kumar',
      harvestDate: DateTime(2026, 3, 15),
      quantityKg: 12.5,
      floralSource: 'Acacia & Wildflower',
      qualityStatus: StageStatus.verified,
      processingStatus: StageStatus.completed,
      packagingStatus: StageStatus.completed,
      blockchainStatus: BlockchainStatus.pending,
      childBatchCode: 'HC-JH-2026-00017-A',
      productId: 'HC-PROD-2026-0012',
      timeline: _fullTimeline(DateTime(2026, 3, 15)),
    ),
    BatchModel(
      id: 'batch-002',
      batchCode: 'HC-JH-2026-00012',
      hiveId: 'hive-001',
      hiveName: 'Hive Alpha',
      apiaryName: 'Kashmir Valley Apiary',
      origin: 'Pahalgam, Jammu & Kashmir',
      beekeeperId: beekeeperId,
      beekeeperName: 'Rajesh Kumar',
      harvestDate: DateTime(2026, 2, 28),
      quantityKg: 10.0,
      floralSource: 'Kashmiri Acacia',
      qualityStatus: StageStatus.verified,
      processingStatus: StageStatus.inProgress,
      packagingStatus: StageStatus.pending,
      blockchainStatus: BlockchainStatus.notRegistered,
      timeline: _partialTimeline(DateTime(2026, 2, 28)),
    ),
    BatchModel(
      id: 'batch-003',
      batchCode: 'HC-JH-2026-00008',
      hiveId: 'hive-005',
      hiveName: 'Hive Epsilon',
      apiaryName: 'Kashmir Valley Apiary',
      origin: 'Pahalgam, Jammu & Kashmir',
      beekeeperId: beekeeperId,
      beekeeperName: 'Rajesh Kumar',
      harvestDate: DateTime(2026, 2, 10),
      quantityKg: 8.5,
      floralSource: 'Mixed Wildflower',
      qualityStatus: StageStatus.inProgress,
      processingStatus: StageStatus.pending,
      packagingStatus: StageStatus.pending,
      blockchainStatus: BlockchainStatus.notRegistered,
      timeline: _earlyTimeline(DateTime(2026, 2, 10)),
    ),
  ];

  static List<TimelineStage> _fullTimeline(DateTime harvestDate) => [
        TimelineStage(
          title: 'Hive Registered',
          status: StageStatus.completed,
          date: harvestDate.subtract(const Duration(days: 30)),
          evidenceType: EvidenceType.sensorVerified,
          description: 'Hive Gamma registered with ESP32 Smart Sensor Node.',
        ),
        TimelineStage(
          title: 'Telemetry Recorded',
          status: StageStatus.completed,
          date: harvestDate.subtract(const Duration(days: 2)),
          evidenceType: EvidenceType.sensorVerified,
          description: 'Stable weight growth (45.6kg) and temp (33.9°C) recorded.',
        ),
        TimelineStage(
          title: 'Harvest Recorded',
          status: StageStatus.completed,
          date: harvestDate,
          evidenceType: EvidenceType.farmerRecorded,
          description: '12.5 kg honey harvested by Beekeeper Rajesh Kumar.',
        ),
        TimelineStage(
          title: 'Batch Created',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 1)),
          evidenceType: EvidenceType.farmerRecorded,
          description: 'Batch HC-JH-2026-00017 logged in local supply chain ledger.',
        ),
        TimelineStage(
          title: 'Laboratory QC',
          status: StageStatus.verified,
          date: harvestDate.add(const Duration(days: 4)),
          evidenceType: EvidenceType.laboratoryVerified,
          description: 'Moisture 17.2%, HMF 12.5mg/kg. Clean adulterant screen.',
        ),
        TimelineStage(
          title: 'Processing',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 7)),
          evidenceType: EvidenceType.processorRecorded,
          description: 'Cold mesh filtration. Child Batch HC-JH-2026-00017-A created.',
        ),
        TimelineStage(
          title: 'Packaging',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 9)),
          evidenceType: EvidenceType.processorRecorded,
          description: 'Bottled in 500g glass jars at Pahalgam Hub #2.',
        ),
        TimelineStage(
          title: 'Product Registered',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 10)),
          evidenceType: EvidenceType.processorRecorded,
          description: 'Product HC-PROD-2026-0012 linked to Passport QR Code.',
        ),
      ];

  static List<TimelineStage> _partialTimeline(DateTime harvestDate) => [
        TimelineStage(
          title: 'Hive Registered',
          status: StageStatus.completed,
          date: harvestDate.subtract(const Duration(days: 20)),
          evidenceType: EvidenceType.sensorVerified,
        ),
        TimelineStage(
          title: 'Harvest Recorded',
          status: StageStatus.completed,
          date: harvestDate,
          evidenceType: EvidenceType.farmerRecorded,
        ),
        TimelineStage(
          title: 'Batch Created',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 1)),
          evidenceType: EvidenceType.farmerRecorded,
        ),
        TimelineStage(
          title: 'Laboratory QC',
          status: StageStatus.verified,
          date: harvestDate.add(const Duration(days: 3)),
          evidenceType: EvidenceType.laboratoryVerified,
          description: 'Lab test verified by Kashmir Food Testing Lab.',
        ),
        TimelineStage(
          title: 'Processing',
          status: StageStatus.inProgress,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
          description: 'Currently undergoing filtration.',
        ),
        TimelineStage(
          title: 'Packaging',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
        ),
      ];

  static List<TimelineStage> _earlyTimeline(DateTime harvestDate) => [
        TimelineStage(
          title: 'Hive Registered',
          status: StageStatus.completed,
          date: harvestDate.subtract(const Duration(days: 15)),
          evidenceType: EvidenceType.sensorVerified,
        ),
        TimelineStage(
          title: 'Harvest Recorded',
          status: StageStatus.completed,
          date: harvestDate,
          evidenceType: EvidenceType.farmerRecorded,
        ),
        TimelineStage(
          title: 'Batch Created',
          status: StageStatus.completed,
          date: harvestDate.add(const Duration(days: 1)),
          evidenceType: EvidenceType.farmerRecorded,
        ),
        TimelineStage(
          title: 'Laboratory QC',
          status: StageStatus.inProgress,
          date: null,
          evidenceType: EvidenceType.laboratoryVerified,
          description: 'Samples submitted for moisture and HMF testing.',
        ),
        TimelineStage(
          title: 'Processing',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
        ),
        TimelineStage(
          title: 'Packaging',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
        ),
      ];

  static List<TimelineStage> newBatchTimeline(DateTime harvestDate) => [
        TimelineStage(
          title: 'Harvest Recorded',
          status: StageStatus.completed,
          date: harvestDate,
          evidenceType: EvidenceType.farmerRecorded,
          description: 'Harvest recorded by beekeeper.',
        ),
        TimelineStage(
          title: 'Batch Created',
          status: StageStatus.completed,
          date: harvestDate,
          evidenceType: EvidenceType.farmerRecorded,
        ),
        TimelineStage(
          title: 'Laboratory QC',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.laboratoryVerified,
        ),
        TimelineStage(
          title: 'Processing',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
        ),
        TimelineStage(
          title: 'Packaging',
          status: StageStatus.pending,
          date: null,
          evidenceType: EvidenceType.processorRecorded,
        ),
      ];

  static final qualityTests = <QualityTestModel>[
    QualityTestModel(
      id: 'qt-001',
      batchId: 'batch-001',
      laboratoryId: 'lab-001',
      laboratoryName: 'Kashmir Food Testing Lab',
      moisturePercent: 17.2,
      hmfLevel: 12.5,
      pollutantScreen: 'Clear — no contaminants detected',
      isVerified: true,
      testedAt: DateTime(2026, 3, 19),
      notes: 'Meets FSSAI honey standards.',
    ),
  ];

  static final processingEvents = <ProcessingEventModel>[
    ProcessingEventModel(
      id: 'proc-001',
      batchId: 'batch-001',
      processorId: 'processor-001',
      processorName: 'Kashmir Processing Facility',
      eventType: 'Cold Extraction & Mesh Filtration',
      description:
          'Raw honey filtered through 200-micron stainless steel mesh at 34°C. Pollen preserved, wax removed.',
      completedAt: DateTime(2026, 3, 22),
      facility: 'Pahalgam Processing Plant #1',
      inputBatchId: 'HC-JH-2026-00017',
      outputBatchId: 'HC-JH-2026-00017-A',
    ),
  ];

  static final packagingEvents = <PackagingEventModel>[
    PackagingEventModel(
      id: 'pack-001',
      batchId: 'batch-001',
      facility: 'Pahalgam Bottling Hub #2',
      packageSize: '500g Food-Grade Glass Jar',
      productId: 'HC-PROD-2026-0012',
      outputBatchId: 'HC-JH-2026-00017-A',
      packagedAt: DateTime(2026, 3, 24),
      packagerName: 'Kashmir Valley Packaging Team',
      notes: 'Tamper-evident seal applied with unique QR batch code label.',
    ),
  ];

  static final products = <ProductModel>[
    ProductModel(
      id: 'prod-001',
      name: 'Kashmiri Acacia Raw Honey',
      description:
          'Pure raw honey from high-altitude acacia forests of Pahalgam. Mild, floral sweetness with traceable HoneyChain batch identity.',
      batchId: 'batch-001',
      batchCode: 'HC-JH-2026-00017',
      sellerId: beekeeperId,
      sellerName: 'Rajesh Kumar',
      origin: 'Pahalgam, Jammu & Kashmir',
      priceInr: 650,
      weightGrams: 500,
      quantityAvailable: 48,
      category: ProductCategory.rawHoney,
      isVerified: true,
      harvestDate: DateTime(2026, 3, 15),
    ),
    ProductModel(
      id: 'prod-002',
      name: 'Wildflower Forest Honey',
      description:
          'Rich wildflower honey harvested from Kashmir Valley apiaries. Laboratory verified for quality and moisture content.',
      batchId: 'batch-002',
      batchCode: 'HC-JH-2026-00012',
      sellerId: beekeeperId,
      sellerName: 'Rajesh Kumar',
      origin: 'Pahalgam, Jammu & Kashmir',
      priceInr: 580,
      weightGrams: 500,
      quantityAvailable: 32,
      category: ProductCategory.organicHoney,
      isVerified: true,
      harvestDate: DateTime(2026, 2, 28),
    ),
    ProductModel(
      id: 'prod-003',
      name: 'Premium Comb Honey',
      description:
          'Natural comb honey with full traceability from hive to jar. Cut directly from verified HoneyChain batch.',
      batchId: 'batch-001',
      batchCode: 'HC-JH-2026-00017',
      sellerId: beekeeperId,
      sellerName: 'Rajesh Kumar',
      origin: 'Pahalgam, Jammu & Kashmir',
      priceInr: 890,
      weightGrams: 350,
      quantityAvailable: 15,
      category: ProductCategory.combHoney,
      isVerified: true,
      harvestDate: DateTime(2026, 3, 15),
    ),
    ProductModel(
      id: 'prod-004',
      name: 'Himalayan Multiflora Honey',
      description:
          'Blend of seasonal wildflowers from the Himalayan foothills. Traceable batch with pending quality verification.',
      batchId: 'batch-003',
      batchCode: 'HC-JH-2026-00008',
      sellerId: beekeeperId,
      sellerName: 'Rajesh Kumar',
      origin: 'Pahalgam, Jammu & Kashmir',
      priceInr: 520,
      weightGrams: 500,
      quantityAvailable: 20,
      category: ProductCategory.specialtyHoney,
      isVerified: false,
      harvestDate: DateTime(2026, 2, 10),
    ),
  ];

  static int _batchCounter = 18;

  static String generateBatchCode() {
    final code = 'HC-JH-2026-${_batchCounter.toString().padLeft(5, '0')}';
    _batchCounter++;
    return code;
  }
}
