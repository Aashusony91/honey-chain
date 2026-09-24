enum UserRole {
  beekeeper,
  consumer,
  laboratory,
  processor,
  buyer;

  String get label => switch (this) {
        UserRole.beekeeper => 'Beekeeper',
        UserRole.consumer => 'Consumer',
        UserRole.laboratory => 'Laboratory',
        UserRole.processor => 'Processor',
        UserRole.buyer => 'Buyer',
      };

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => UserRole.consumer,
    );
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.role,
    this.isVerified = false,
    this.apiaryIds = const [],
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final UserRole role;
  final bool isVerified;
  final List<String> apiaryIds;
  final DateTime? createdAt;

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? location,
    UserRole? role,
    bool? isVerified,
    List<String>? apiaryIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      apiaryIds: apiaryIds ?? this.apiaryIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      location: json['location'] as String,
      role: UserRole.fromString(json['role'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      apiaryIds: (json['apiary_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'role': role.name,
        'is_verified': isVerified,
        'apiary_ids': apiaryIds,
        'created_at': createdAt?.toIso8601String(),
      };
}
