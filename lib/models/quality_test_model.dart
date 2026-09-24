class QualityTestModel {
  const QualityTestModel({
    required this.id,
    required this.batchId,
    required this.laboratoryId,
    required this.laboratoryName,
    required this.moisturePercent,
    required this.hmfLevel,
    required this.pollutantScreen,
    required this.isVerified,
    required this.testedAt,
    this.notes,
  });

  final String id;
  final String batchId;
  final String laboratoryId;
  final String laboratoryName;
  final double moisturePercent;
  final double hmfLevel;
  final String pollutantScreen;
  final bool isVerified;
  final DateTime testedAt;
  final String? notes;

  factory QualityTestModel.fromJson(Map<String, dynamic> json) {
    return QualityTestModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      laboratoryId: json['laboratory_id'] as String,
      laboratoryName: json['laboratory_name'] as String,
      moisturePercent: (json['moisture_percent'] as num).toDouble(),
      hmfLevel: (json['hmf_level'] as num).toDouble(),
      pollutantScreen: json['pollutant_screen'] as String,
      isVerified: json['is_verified'] as bool,
      testedAt: DateTime.parse(json['tested_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_id': batchId,
        'laboratory_id': laboratoryId,
        'laboratory_name': laboratoryName,
        'moisture_percent': moisturePercent,
        'hmf_level': hmfLevel,
        'pollutant_screen': pollutantScreen,
        'is_verified': isVerified,
        'tested_at': testedAt.toIso8601String(),
        'notes': notes,
      };
}

class ProcessingEventModel {
  const ProcessingEventModel({
    required this.id,
    required this.batchId,
    required this.processorId,
    required this.processorName,
    required this.eventType,
    required this.description,
    required this.completedAt,
  });

  final String id;
  final String batchId;
  final String processorId;
  final String processorName;
  final String eventType;
  final String description;
  final DateTime completedAt;

  factory ProcessingEventModel.fromJson(Map<String, dynamic> json) {
    return ProcessingEventModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      processorId: json['processor_id'] as String,
      processorName: json['processor_name'] as String,
      eventType: json['event_type'] as String,
      description: json['description'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'batch_id': batchId,
        'processor_id': processorId,
        'processor_name': processorName,
        'event_type': eventType,
        'description': description,
        'completed_at': completedAt.toIso8601String(),
      };
}
