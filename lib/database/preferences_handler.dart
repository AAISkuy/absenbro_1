import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyNama = "nama";
  static const _keyEmail = "email";
  static const _keyPassword = "password";
  static const _keyJenisKelamin = "jenis_kelamin";
  static const _keyProfilePhoto = "profile_photo";
  static const _keyBatchId = "batch_id";
  static const _keyTrainingId = "training_id";
  static const _keyThemeMode = "theme_mode";

  static Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  static String get themeMode => _prefs.getString(_keyThemeMode) ?? "light";

  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> saveUser({
    required String nama,
    required String email,
    required String password,
    String? jenisKelamin,
    String? profilePhoto,
    int? batchId,
    int? trainingId,
  }) async {
    await _prefs.setString(_keyNama, nama);
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyPassword, password);
    if (jenisKelamin != null) {
      await _prefs.setString(_keyJenisKelamin, jenisKelamin);
    } else {
      await _prefs.remove(_keyJenisKelamin);
    }
    if (profilePhoto != null) {
      await _prefs.setString(_keyProfilePhoto, profilePhoto);
    } else {
      await _prefs.remove(_keyProfilePhoto);
    }
    if (batchId != null) {
      await _prefs.setInt(_keyBatchId, batchId);
    } else {
      await _prefs.remove(_keyBatchId);
    }
    if (trainingId != null) {
      await _prefs.setInt(_keyTrainingId, trainingId);
    } else {
      await _prefs.remove(_keyTrainingId);
    }
  }

  static String get nama => _prefs.getString(_keyNama) ?? "";
  static String get email => _prefs.getString(_keyEmail) ?? "";
  static String get password => _prefs.getString(_keyPassword) ?? "";
  static String? get jenisKelamin => _prefs.getString(_keyJenisKelamin);
  static String? get profilePhoto => _prefs.getString(_keyProfilePhoto);
  static int? get batchId {
    final val = _prefs.getInt(_keyBatchId);
    return val == 0 ? null : val;
  }
  static int? get trainingId {
    final val = _prefs.getInt(_keyTrainingId);
    return val == 0 ? null : val;
  }

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
    await _prefs.remove(_keyNama);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyPassword);
    await _prefs.remove(_keyJenisKelamin);
    await _prefs.remove(_keyProfilePhoto);
    await _prefs.remove(_keyBatchId);
    await _prefs.remove(_keyTrainingId);
  }
}
