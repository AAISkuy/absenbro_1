// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendance _$AttendanceFromJson(Map<String, dynamic> json) => Attendance(
  id: _parseNullableInt(json['id']),
  userId: _parseNullableInt(json['user_id']),
  attendanceDate: json['attendance_date'] as String?,
  checkInTime: json['check_in_time'] as String?,
  checkOutTime: json['check_out_time'] as String?,
  checkInLat: _parseNullableDouble(json['check_in_lat']),
  checkInLng: _parseNullableDouble(json['check_in_lng']),
  checkOutLat: _parseNullableDouble(json['check_out_lat']),
  checkOutLng: _parseNullableDouble(json['check_out_lng']),
  checkInLocation: json['check_in_location'] as String?,
  checkOutLocation: json['check_out_location'] as String?,
  checkInAddress: json['check_in_address'] as String?,
  checkOutAddress: json['check_out_address'] as String?,
  status: json['status'] as String,
  alasanIzin: json['alasan_izin'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$AttendanceToJson(Attendance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'attendance_date': instance.attendanceDate,
      'check_in_time': instance.checkInTime,
      'check_out_time': instance.checkOutTime,
      'check_in_lat': instance.checkInLat,
      'check_in_lng': instance.checkInLng,
      'check_out_lat': instance.checkOutLat,
      'check_out_lng': instance.checkOutLng,
      'check_in_location': instance.checkInLocation,
      'check_out_location': instance.checkOutLocation,
      'check_in_address': instance.checkInAddress,
      'check_out_address': instance.checkOutAddress,
      'status': instance.status,
      'alasan_izin': instance.alasanIzin,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
