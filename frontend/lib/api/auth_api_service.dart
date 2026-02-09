import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class AuthApiService extends ChangeNotifier {
  // Use your production base URL
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  String? _userId;
  String? _userRole;
  String? _employeeId;
  String? _adminId;

  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get employeeId => _employeeId;
  String? get adminId => _adminId;

  /// Private helper to retrieve unique hardware ID and model.
  /// This is used to differentiate between the same SIM card in different phones.
  Future<Map<String, String>> _getHardwareInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return {
          'id': androidInfo.id, // Unique Hardware ID
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return {
          'id': iosInfo.identifierForVendor ?? 'unknown',
          'model': iosInfo.utsname.machine,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return {'id': 'unknown', 'model': 'unknown'};
  }

  /// Verifies if the current physical device is authorized for this user.
  /// Returns: 'verified', 'pending', 'denied', or 'error'
  Future<String> checkDevice({required String userId}) async {
    try {
      final deviceData = await _getHardwareInfo();

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-device'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'deviceId': deviceData['id'],
          'deviceModel': deviceData['model'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] ?? 'error';
      } else {
        debugPrint('Device verify failed: ${response.body}');
        return 'error';
      }
    } catch (e) {
      debugPrint('Device verify exception: $e');
      return 'error';
    }
  }

  /// Verifies the 4-digit secure PIN and sets session IDs.
  Future<bool> verifyPin(String phone, String pin, String companyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-pin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phone,
          'secure_pin': pin,
          'companyId': companyId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userId = data['user']['_id'];
        _userRole = data['user']['role'];
        _employeeId = data['employeeId'];
        _adminId = data['adminId'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PIN verification error: $e');
      return false;
    }
  }
}
