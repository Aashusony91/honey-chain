enum StageStatus {
  pending,
  inProgress,
  verified,
  completed;

  String get label => switch (this) {
        StageStatus.pending => 'Pending',
        StageStatus.inProgress => 'In Progress',
        StageStatus.verified => 'Verified',
        StageStatus.completed => 'Completed',
      };
}

enum EvidenceType {
  sensorVerified,
  farmerRecorded,
  laboratoryVerified;

  String get label => switch (this) {
        EvidenceType.sensorVerified => 'Sensor Verified',
        EvidenceType.farmerRecorded => 'Farmer Recorded',
        EvidenceType.laboratoryVerified => 'Laboratory Verified',
      };
}

enum BlockchainStatus {
  notRegistered,
  pending,
  registered;

  String get label => switch (this) {
        BlockchainStatus.notRegistered => 'Not Registered',
        BlockchainStatus.pending => 'Pending',
        BlockchainStatus.registered => 'Registered',
      };
}

class TimelineStage {
  const TimelineStage({
    required this.title,
    required this.status,
    required this.date,
    required this.evidenceType,
    this.description,
  });

  final String title;
  final StageStatus status;
  final DateTime? date;
  final EvidenceType evidenceType;
  final String? description;

  factory TimelineStage.fromJson(Map<String, dynamic> json) {
    return TimelineStage(
      title: json['title'] as String,
      status: StageStatus.values.byName(json['status'] as String),
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      evidenceType:
          EvidenceType.values.byName(json['evidence_type'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'status': status.name,
        'date': date?.toIso8601String(),
        'evidence_type': evidenceType.name,
        'description': description,
      };
}

class BatchModel {
  const BatchModel({
    required this.id,
    required this.batchCode,
    required this.hiveId,
    required this.hiveName,
    required this.apiaryName,
    required this.origin,
    required this.beekeeperId,
    required this.beekeeperName,
    required this.harvestDate,
    required this.quantityKg,
    required this.floralSource,
    required this.qualityStatus,
    required this.processingStatus,
    required this.packagingStatus,
    required this.blockchainStatus,
    required this.timeline,
    this.parentBatchId,
    this.notes,
  });

  final String id;
  final String batchCode;
  final String hiveId;
  final String hiveName;
  final String apiaryName;
  final String origin;
  final String beekeeperId;
  final String beekeeperName;
  final DateTime harvestDate;
  final double quantityKg;
  final String floralSource;
  final StageStatus qualityStatus;
  final StageStatus processingStatus;
  final StageStatus packagingStatus;
  final BlockchainStatus blockchainStatus;
  final List<TimelineStage> timeline;
  final String? parentBatchId;
  final String? notes;

  BatchModel copyWith({
    String? id,
    String? batchCode,
    String? hiveId,
    String? hiveName,
    String? apiaryName,
    String? origin,
    String? beekeeperId,
    String? beekeeperName,
    DateTime? harvestDate,
    double? quantityKg,
    String? floralSource,
    StageStatus? qualityStatus,
    StageStatus? processingStatus,
    StageStatus? packagingStatus,
    BlockchainStatus? blockchainStatus,
    List<TimelineStage>? timeline,
    String? parentBatchId,
    String? notes,
  }) {
    return BatchModel(
      id: id ?? this.id,
      batchCode: batchCode ?? this.batchCode,
      hiveId: hiveId ?? this.hiveId,
      hiveName: hiveName ?? this.hiveName,
      apiaryName: apiaryName ?? this.apiaryName,
      origin: origin ?? this.origin,
      beekeeperId: beekeeperId ?? this.beekeeperId,
      beekeeperName: beekeeperName ?? this.beekeeperName,
      harvestDate: harvestDate ?? this.harvestDate,
      quantityKg: quantityKg ?? this.quantityKg,
      floralSource: floralSource ?? this.floralSource,
      qualityStatus: qualityStatus ?? this.qualityStatus,
      processingStatus: processingStatus ?? this.processingStatus,
      packagingStatus: packagingStatus ?? this.packagingStatus,
      blockchainStatus: blockchainStatus ?? this.blockchainStatus,
      timeline: timeline ?? this.timeline,
      parentBatchId: parentBatchId ?? this.parentBatchId,
      notes: notes ?? this.notes,
    );
  }

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      batchCode: json['batch_code'] as String,
      hiveId: json['hive_id'] as String,
      hiveName: json['hive_name'] as String,
      apiaryName: json['apiary_name'] as String,
      origin: json['origin'] as String,
      beekeeperId: json['beekeeper_id'] as String,
      beekeeperName: json['beekeeper_name'] as String,
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      floralSource: json['floral_source'] as String,
      qualityStatus: StageStatus.values.byName(json['quality_status'] as String),
      processingStatus:
          StageStatus.values.byName(json['processing_status'] as String),
      packagingStatus:
          StageStatus.values.byName(json['packaging_status'] as String),
      blockchainStatus:
          BlockchainStatus.values.byName(json['blockchain_status'] as String),
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => TimelineStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      parentBatchId: json['parent_batch_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_code': batchCode,
        'hive_id': hiveId,
        'hive_name': hiveName,
        'apiary_name': apiaryName,
        'origin': origin,
        'beekeeper_id': beekeeperId,
        'beekeeper_name': beekeeperName,
        'harvest_date': harvestDate.toIso8601String(),
        'quantity_kg': quantityKg,
        'floral_source': floralSource,
        'quality_status': qualityStatus.name,
        'processing_status': processingStatus.name,
        'packaging_status': packagingStatus.name,
        'blockchain_status': blockchainStatus.name,
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'parent_batch_id': parentBatchId,
        'notes': notes,
      };
}
