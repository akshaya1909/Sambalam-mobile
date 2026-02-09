import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static late SharedPreferences _prefs;

  // Keys
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUserId = 'user_id';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyCompanyId = 'company_id';
  static const String _keyUserRole = 'user_role';

  factory StorageService() => _instance;

  StorageService._internal();

  /// Call this once in main() before runApp()
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding status
  bool getOnboardingComplete() =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool value) async =>
      _prefs.setBool(_keyOnboardingComplete, value);

  // User ID
  String? getUserId() => _prefs.getString(_keyUserId);

  Future<void> setUserId(String value) async =>
      _prefs.setString(_keyUserId, value);

  // Phone number
  String? getPhoneNumber() => _prefs.getString(_keyPhoneNumber);

  Future<void> setPhoneNumber(String value) async =>
      _prefs.setString(_keyPhoneNumber, value);

  // Biometric enabled
  bool getBiometricEnabled() =>
      _prefs.getBool(_keyBiometricEnabled) ?? false;

  Future<void> setBiometricEnabled(bool value) async =>
      _prefs.setBool(_keyBiometricEnabled, value);

  // Company ID
  String? getCompanyId() => _prefs.getString(_keyCompanyId);

  Future<void> setCompanyId(String value) async =>
      _prefs.setString(_keyCompanyId, value);

  // User role
  String? getUserRole() => _prefs.getString(_keyUserRole);

  Future<void> setUserRole(String value) async =>
      _prefs.setString(_keyUserRole, value);

  // Clear auth data
  Future<void> clearAuthData() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyPhoneNumber);
    await _prefs.remove(_keyBiometricEnabled);
    await _prefs.remove(_keyCompanyId);
    await _prefs.remove(_keyUserRole);
  }
}
