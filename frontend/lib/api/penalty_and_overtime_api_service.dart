import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PenaltyAndOvertimeApiService {
  final String baseUrl =
      "https://sambalam.ifoxclicks.com/api/penalty-and-overtime";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getEarlyLeavingPolicy(String employeeId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/early-leaving/$employeeId'),
        headers: await _getHeaders());
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getLateComingPolicy(String employeeId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/late-coming/$employeeId'),
        headers: await _getHeaders());
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getOvertimePolicy(String employeeId) async {
    final response = await http.get(Uri.parse('$baseUrl/over-time/$employeeId'),
        headers: await _getHeaders());
    return json.decode(response.body);
  }

  Future<bool> updateEarlyLeaving(
      String employeeId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/early-leaving/$employeeId'),
      headers: await _getHeaders(),
      body: json.encode({'earlyLeavingPolicy': data}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateLateComing(
      String employeeId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/late-coming/$employeeId'),
      headers: await _getHeaders(),
      body: json.encode({'lateComingPolicy': data}),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateOvertime(
      String employeeId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/over-time/$employeeId'),
      headers: await _getHeaders(),
      body: json.encode({'overtimePolicy': data}),
    );
    return response.statusCode == 200;
  }
}
