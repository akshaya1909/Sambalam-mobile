import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart'; // Add mime package
import '../models/reimbursement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reimbursement_request_item.dart';

class ReimbursementApiService {
  static const String baseUrl =
      'https://sambalam.ifoxclicks.com/api/reimbursements'; // Update IP

  Future<void> createReimbursement({
    required String employeeId,
    required String companyId,
    required double amount,
    required DateTime date,
    String? notes,
    List<PlatformFile>? files,
  }) async {
    final uri = Uri.parse(baseUrl);
    var request = http.MultipartRequest('POST', uri);

    request.fields['employeeId'] = employeeId;
    request.fields['companyId'] = companyId;
    request.fields['amount'] = amount.toString();
    request.fields['dateOfPayment'] = date.toIso8601String();
    if (notes != null) request.fields['notes'] = notes;

    if (files != null) {
      for (var file in files) {
        // Use fromBytes instead of fromPath for Web
        request.files.add(http.MultipartFile.fromBytes(
          'attachments',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'), // Simplified for example
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Failed to create reimbursement: ${response.body}');
    }
  }

  Future<List<Reimbursement>> getReimbursements({
    required String companyId,
    String? employeeId,
    String? status,
    int? month,
    int? year,
  }) async {
    String query = 'companyId=$companyId';
    if (employeeId != null) query += '&employeeId=$employeeId';
    if (status != null) query += '&status=$status';
    if (month != null) query += '&month=$month';
    if (year != null) query += '&year=$year';

    final res = await http.get(Uri.parse('$baseUrl?$query'));

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Reimbursement.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load reimbursements');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<ReimbursementRequestItem>> getPendingReimbursements(
      String companyId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/pending?companyId=$companyId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => ReimbursementRequestItem.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load pending reimbursements');
    }
  }

  Future<void> updateReimbursementStatusByAdmin({
    required String reimbursementId,
    required String status,
  }) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('userId');

    final uri = Uri.parse('$baseUrl/update/$reimbursementId/status');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        'adminId': adminId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }
}
