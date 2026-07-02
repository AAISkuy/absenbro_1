import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

// Helper parsers to handle string to number conversions dynamically from PHP backend
int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return int.tryParse(value);
  }
  return null;
}

@JsonSerializable()
class User {
  @JsonKey(fromJson: _parseInt)
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'jenis_kelamin')
  final String? jenisKelamin;
  @JsonKey(name: 'profile_photo')
  final String? profilePhoto;
  @JsonKey(name: 'batch_id', fromJson: _parseNullableInt)
  final int? batchId;
  @JsonKey(name: 'training_id', fromJson: _parseNullableInt)
  final int? trainingId;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  
  // Custom role field determined locally or by backend (default 'peserta', or 'admin' if email matches admin pattern)
  final String? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.jenisKelamin,
    this.profilePhoto,
    this.batchId,
    this.trainingId,
    this.createdAt,
    this.updatedAt,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Helper to check if user is admin
  bool get isAdmin => role == 'admin' || email.toLowerCase().contains('admin');

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? emailVerifiedAt,
    String? jenisKelamin,
    String? profilePhoto,
    int? batchId,
    int? trainingId,
    String? createdAt,
    String? updatedAt,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      batchId: batchId ?? this.batchId,
      trainingId: trainingId ?? this.trainingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }
}
