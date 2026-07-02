// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Training _$TrainingFromJson(Map<String, dynamic> json) => Training(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  participantCount: (json['participant_count'] as num?)?.toInt(),
  standard: json['standard'] as String?,
  duration: json['duration'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$TrainingToJson(Training instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'participant_count': instance.participantCount,
  'standard': instance.standard,
  'duration': instance.duration,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
