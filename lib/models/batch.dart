import 'package:json_annotation/json_annotation.dart';

part 'batch.g.dart';

@JsonSerializable()
class Batch {
  final int id;
  final String? name;
  final String? title;

  Batch({
    required this.id,
    this.name,
    this.title,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
  Map<String, dynamic> toJson() => _$BatchToJson(this);

  // Helper getter to get display name
  String get displayName => name ?? title ?? 'Batch $id';
}
