import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

// Helper parsers to handle string to number conversions dynamically from PHP backend
int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return int.tryParse(value);
  }
  return null;
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return double.tryParse(value);
  }
  return null;
}

@JsonSerializable()
class Attendance {
  @JsonKey(fromJson: _parseNullableInt)
  final int? id;
  @JsonKey(name: 'user_id', fromJson: _parseNullableInt)
  final int? userId;
  @JsonKey(name: 'attendance_date')
  final String? attendanceDate;
  @JsonKey(name: 'check_in_time')
  final String? checkInTime;
  @JsonKey(name: 'check_out_time')
  final String? checkOutTime;
  @JsonKey(name: 'check_in_lat', fromJson: _parseNullableDouble)
  final double? checkInLat;
  @JsonKey(name: 'check_in_lng', fromJson: _parseNullableDouble)
  final double? checkInLng;
  @JsonKey(name: 'check_out_lat', fromJson: _parseNullableDouble)
  final double? checkOutLat;
  @JsonKey(name: 'check_out_lng', fromJson: _parseNullableDouble)
  final double? checkOutLng;
  @JsonKey(name: 'check_in_location')
  final String? checkInLocation;
  @JsonKey(name: 'check_out_location')
  final String? checkOutLocation;
  @JsonKey(name: 'check_in_address')
  final String? checkInAddress;
  @JsonKey(name: 'check_out_address')
  final String? checkOutAddress;
  final String status; // 'masuk' or 'izin'
  @JsonKey(name: 'alasan_izin')
  final String? alasanIzin;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Attendance({
    this.id,
    this.userId,
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInAddress,
    this.checkOutAddress,
    required this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceToJson(this);
}
