class HarvestModel {
  const HarvestModel({
    required this.id,
    required this.hiveId,
    required this.beekeeperId,
    required this.quantityKg,
    required this.harvestDate,
    required this.floralSource,
    required this.notes,
    required this.batchId,
    required this.createdAt,
  });

  final String id;
  final String hiveId;
  final String beekeeperId;
  final double quantityKg;
  final DateTime harvestDate;
  final String floralSource;
  final String notes;
  final String batchId;
  final DateTime createdAt;

  factory HarvestModel.fromJson(Map<String, dynamic> json) {
    return HarvestModel(
      id: json['id'] as String,
      hiveId: json['hive_id'] as String,
      beekeeperId: json['beekeeper_id'] as String,
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      floralSource: json['floral_source'] as String,
      notes: json['notes'] as String? ?? '',
      batchId: json['batch_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hive_id': hiveId,
        'beekeeper_id': beekeeperId,
        'quantity_kg': quantityKg,
        'harvest_date': harvestDate.toIso8601String(),
        'floral_source': floralSource,
        'notes': notes,
        'batch_id': batchId,
        'created_at': createdAt.toIso8601String(),
      };
}
