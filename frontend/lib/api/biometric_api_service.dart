import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/biometric_device_model.dart';
import '../models/branch_model.dart'; // Reuse existing Branch model

class BiometricApiService {
  // Update with your actual IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET DEVICES ---
  Future<List<BiometricDevice>> getCompanyDevices(String companyId) async {
    final uri =
        Uri.parse('$baseUrl/api/biometrics/$companyId/biometric-devices');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List<dynamic> list = data['devices'];
      return list.map((e) => BiometricDevice.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load devices');
    }
  }

  // --- CREATE DEVICE ---
  Future<void> createDevice(String companyId, Map<String, dynamic> data) async {
    final uri =
        Uri.parse('$baseUrl/api/biometrics/$companyId/biometric-devices');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to create device');
    }
  }

  // --- UPDATE DEVICE ---
  Future<void> updateDevice(String deviceId, Map<String, dynamic> data) async {
    final uri =
        Uri.parse('$baseUrl/api/biometrics/biometric-devices/$deviceId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update device');
    }
  }

  // --- DELETE DEVICE ---
  Future<void> deleteDevice(String deviceId) async {
    final uri =
        Uri.parse('$baseUrl/api/biometrics/biometric-devices/$deviceId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete device');
    }
  }

  // --- FETCH BRANCHES (Helper for dropdown) ---
  Future<List<Branch>> getBranches(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/branches/$companyId/branches');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Branch.fromJson(e)).toList();
    }
    return [];
  }
}
