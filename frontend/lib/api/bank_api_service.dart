import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bank_details_model.dart';

class BankApiService {
  // Update with your actual IP/URL
  static const String baseUrl = 'https://sambalam.ifoxclicks.com/api/bank';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Assuming you store auth token
  }

  // Get Bank Details
  Future<BankDetails?> getBankDetails(String employeeId) async {
    final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['details'] == null && data['_id'] == null) {
          return null;
        }
        return BankDetails.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching bank details: $e');
      return null;
    }
  }

  // Save/Update Details
  Future<bool> saveBankDetails(Map<String, dynamic> payload) async {
    final token = await _getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to save: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving bank details: $e');
      return false;
    }
  }
}
