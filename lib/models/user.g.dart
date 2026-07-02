// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: _parseInt(json['id']),
  name: json['name'] as String,
  email: json['email'] as String,
  emailVerifiedAt: json['email_verified_at'] as String?,
  jenisKelamin: json['jenis_kelamin'] as String?,
  profilePhoto: json['profile_photo'] as String?,
  batchId: _parseNullableInt(json['batch_id']),
  trainingId: _parseNullableInt(json['training_id']),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  role: json['role'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'email_verified_at': instance.emailVerifiedAt,
  'jenis_kelamin': instance.jenisKelamin,
  'profile_photo': instance.profilePhoto,
  'batch_id': instance.batchId,
  'training_id': instance.trainingId,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'role': instance.role,
};
