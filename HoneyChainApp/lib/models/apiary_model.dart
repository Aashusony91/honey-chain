class ApiaryModel {
  const ApiaryModel({
    required this.id,
    required this.name,
    required this.location,
    required this.beekeeperId,
    required this.hiveIds,
    this.description,
  });

  final String id;
  final String name;
  final String location;
  final String beekeeperId;
  final List<String> hiveIds;
  final String? description;

  factory ApiaryModel.fromJson(Map<String, dynamic> json) {
    return ApiaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      beekeeperId: json['beekeeper_id'] as String,
      hiveIds: (json['hive_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'beekeeper_id': beekeeperId,
        'hive_ids': hiveIds,
        'description': description,
      };
}
