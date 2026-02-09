import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_history.dart';

class ReportsApiService {
  static const String BASE_URL = 'http://10.80.210.30:5000';
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // GET /api/reports/history?companyId=...
  Future<List<ReportHistory>> getReportHistory(String companyId) async {
    final token = await _getToken();
    final url = Uri.parse('$BASE_URL/api/reports/history?companyId=$companyId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ReportHistory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load report history');
    }
  }

  // GET /api/reports/generate?...
  // Note: On mobile, downloading a file usually involves getting a byte stream or a URL.
  // This function assumes the backend returns JSON { message, data } first,
  // or you might need a different approach for direct file download streams.
  // Based on your controller, it returns JSON { message: "Success", data: [...] }.
  // The actual Excel generation happens on client side in your web code logic?
  // No, looking at your controller "getReportData", it returns JSON data.
  // Your Web Frontend then converts JSON to Excel using XLSX lib.
  // For Flutter, we will simulate the "Generate" call.
  // To implement real Excel export in Flutter, you'd use the `excel` package on the returned JSON data.

  Future<void> generateReport({
    required String companyId,
    required String reportType,
    required String month, // MM
    required String year, // YYYY
    String? branch,
    String? department,
  }) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    // Get the ID of the person logged in (Admin/HR)
    final userId = prefs.getString('userId') ?? '';
    // Construct Query Params
    String query =
        'companyId=$companyId&reportType=$reportType&month=$month&year=$year&userId=$userId';
    if (branch != null && branch != 'All Branches') query += '&branch=$branch';
    if (department != null && department != 'All Departments')
      query += '&department=$department';

    final url = Uri.parse('$BASE_URL/api/reports/generate?$query');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // In a real app, parse this JSON and use 'excel' package to create .xlsx file
      // For now, we just trigger the backend history creation logic which happens in the controller.
      return;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to generate report');
    }
  }
}
