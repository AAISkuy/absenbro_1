import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/dio_client.dart';
import '../services/token_storage.dart';
import '../database/preferences_handler.dart';
import '../models/user.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  late final ApiService _apiService = ApiService(createDioClient());
  final TokenStorage _tokenStorage = TokenStorage();

  // Key for local storage
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyBatchId = 'user_batch_id';
  static const String _keyTrainingId = 'user_training_id';

  // Current session values
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;

  // Initialize and check current session
  Future<bool> checkSession() async {
    _token = await _tokenStorage.getToken();
    if (_token == null) {
      return false;
    }

    try {
      // Fetch user profile from API to verify token
      final response = await _apiService.getProfile();
      if (response.response.statusCode == 200) {
        final profileData = response.data['data'] as Map<String, dynamic>;
        _currentUser = User.fromJson(profileData);
        
        // Save session locally
        await _saveLocalSession(_currentUser!);
        return true;
      }
    } catch (e) {
      // If network fails, try to load locally saved user data
      if (PreferencesHandler.isLogin) {
        final localEmail = PreferencesHandler.email;
        final localName = PreferencesHandler.nama;
        final localGender = PreferencesHandler.jenisKelamin;
        final localPhoto = PreferencesHandler.profilePhoto;
        final localBatch = PreferencesHandler.batchId;
        final localTraining = PreferencesHandler.trainingId;

        // Construct dummy user from local preference
        if (localEmail.isNotEmpty) {
          _currentUser = User(
            id: 0, // placeholder
            name: localName,
            email: localEmail,
            jenisKelamin: localGender,
            profilePhoto: localPhoto,
            batchId: localBatch,
            trainingId: localTraining,
          );
          return true;
        }
      }
    }
    
    // In case of error (e.g. 401 unauthorized), clear session
    await logout();
    return false;
  }

  // Register a new participant
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required int batchId,
    required int trainingId,
    String profilePhotoBase64 = "",
  }) async {
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'jenis_kelamin': gender,
        'profile_photo': profilePhotoBase64,
        'batch_id': batchId,
        'training_id': trainingId,
      });

      if (response.response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        
        _token = token;
        final rawUser = User.fromJson(userData);
        _currentUser = rawUser.copyWith(
          jenisKelamin: rawUser.jenisKelamin ?? gender,
          batchId: rawUser.batchId ?? batchId,
          trainingId: rawUser.trainingId ?? trainingId,
          profilePhoto: rawUser.profilePhoto ?? (profilePhotoBase64.isNotEmpty ? profilePhotoBase64 : null),
        );

        await _tokenStorage.saveToken(token);
        await _saveLocalSession(_currentUser!);
        return null; // Return null if success
      }
      return 'Registrasi gagal. Silakan coba lagi.';
    } on DioException catch (e) {
      return _parseDioError(e);
    } catch (e) {
      return e.toString();
    }
  }

  // Login a user
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
      });

      if (response.response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        _token = token;
        _currentUser = User.fromJson(userData);

        await _tokenStorage.saveToken(token);
        await _saveLocalSession(_currentUser!);
        return null; // Return null if success
      }
      return 'Email atau password salah';
    } on DioException catch (e) {
      return _parseDioError(e);
    } catch (e) {
      return e.toString();
    }
  }

  // Logout current session
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _tokenStorage.deleteToken();
    await PreferencesHandler.setLogin(false);
    await PreferencesHandler.logOut();
  }

  // Update the current user's profile photo URL in-memory and in cache
  Future<void> updateProfilePhotoUrl(String photoUrl) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(profilePhoto: photoUrl);
      await _saveLocalSession(_currentUser!);
    }
  }

  // Save session info to local preferences
  Future<void> _saveLocalSession(User user) async {
    await PreferencesHandler.setLogin(true);
    
    // Fallback to existing cached values if the incoming data contains nulls, zeroes, or placeholder defaults
    final finalBatchId = (user.batchId != null && user.batchId != 0) 
        ? user.batchId 
        : PreferencesHandler.batchId;
    final finalTrainingId = (user.trainingId != null && user.trainingId != 0) 
        ? user.trainingId 
        : PreferencesHandler.trainingId;
    final finalGender = (user.jenisKelamin != null && user.jenisKelamin!.isNotEmpty && user.jenisKelamin!.toLowerCase() != 'null') 
        ? user.jenisKelamin 
        : PreferencesHandler.jenisKelamin;
    
    final rawPhoto = user.profilePhoto;
    final isPhotoValid = rawPhoto != null && 
                         rawPhoto.isNotEmpty && 
                         rawPhoto.toLowerCase() != 'null' && 
                         !rawPhoto.contains('default');
    final finalPhoto = isPhotoValid ? rawPhoto : PreferencesHandler.profilePhoto;

    await PreferencesHandler.saveUser(
      nama: user.name,
      email: user.email,
      password: "", // do not store password in plain text preferences
      jenisKelamin: finalGender,
      profilePhoto: finalPhoto,
      batchId: finalBatchId,
      trainingId: finalTrainingId,
    );

    // Update in-memory user with the merged values so they are immediately available to the UI
    _currentUser = user.copyWith(
      batchId: finalBatchId,
      trainingId: finalTrainingId,
      jenisKelamin: finalGender,
      profilePhoto: finalPhoto,
    );
  }

  // Helper method to parse network errors
  String _parseDioError(DioException error) {
    if (error.response != null && error.response!.data != null) {
      try {
        final errorData = error.response!.data;
        if (errorData is Map) {
          if (errorData.containsKey('message')) {
            return errorData['message'] as String;
          }
        }
      } catch (_) {}
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Pastikan koneksi internet aktif.';
      default:
        return 'Terjadi kesalahan sistem (${error.response?.statusCode ?? "Unknown"}).';
    }
  }
}
