import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user.dart';
import '../models/attendance.dart';
import '../models/training.dart';
import '../models/batch.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: 'https://appabsensi.mobileprojp.com')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // 1. Registrasi Peserta
  @POST('/api/register')
  Future<HttpResponse<dynamic>> register(
    @Body() Map<String, dynamic> body,
  );

  // 2. Login Pengguna
  @POST('/api/login')
  Future<HttpResponse<dynamic>> login(
    @Body() Map<String, dynamic> body,
  );

  // 3. Check-in Kehadiran
  @POST('/api/absen/check-in')
  Future<HttpResponse<dynamic>> checkIn(
    @Body() Map<String, dynamic> body,
  );

  // 4. Check-out Kehadiran
  @POST('/api/absen/check-out')
  Future<HttpResponse<dynamic>> checkOut(
    @Body() Map<String, dynamic> body,
  );

  // 5. Pengajuan Izin
  @POST('/api/izin')
  Future<HttpResponse<dynamic>> submitPermission(
    @Body() Map<String, dynamic> body,
  );

  // 6. Device Token
  @POST('/api/device-token')
  Future<HttpResponse<dynamic>> saveDeviceToken(
    @Body() Map<String, dynamic> body,
  );

  // 7. Absen Today
  @GET('/api/absen/today')
  Future<HttpResponse<dynamic>> getTodayAttendance(
    @Query('attendance_date') String attendanceDate,
  );

  // 8. Absen Stats
  @GET('/api/absen/stats')
  Future<HttpResponse<dynamic>> getAttendanceStats({
    @Query('start') String? start,
    @Query('end') String? end,
    @Query('year') String? year,
  });

  // 9. Delete Absen
  @DELETE('/api/absen/{id}')
  Future<HttpResponse<dynamic>> deleteAttendance(
    @Path('id') int id,
  );

  // 10. Get Profile
  @GET('/api/profile')
  Future<HttpResponse<dynamic>> getProfile();

  // 11. Edit Profile (Update Name)
  @PUT('/api/profile')
  Future<HttpResponse<dynamic>> updateProfile(
    @Body() Map<String, dynamic> body,
  );

  // 12. Edit Profile Photo (Update Photo Base64)
  @PUT('/api/profile/photo')
  Future<HttpResponse<dynamic>> updateProfilePhoto(
    @Body() Map<String, dynamic> body,
  );

  // 13. Get Users List (Admin)
  @GET('/api/users')
  Future<HttpResponse<dynamic>> getUsersList();

  // 14. List Trainings (Public)
  @GET('/api/trainings')
  Future<HttpResponse<dynamic>> getTrainings();

  // 15. Detail Training by ID (Public)
  @GET('/api/trainings/{id}')
  Future<HttpResponse<dynamic>> getTrainingDetail(
    @Path('id') int id,
  );

  // 16. List All Batches
  @GET('/api/batches')
  Future<HttpResponse<dynamic>> getBatches();

  // 17. Request OTP (Forgot Password)
  @POST('/api/forgot-password')
  Future<HttpResponse<dynamic>> forgotPassword(
    @Body() Map<String, dynamic> body,
  );

  // 18. Reset Password
  @POST('/api/reset-password')
  Future<HttpResponse<dynamic>> resetPassword(
    @Body() Map<String, dynamic> body,
  );
}
