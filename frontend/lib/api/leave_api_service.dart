// lib/api/leave_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/leave_request_item.dart';

class LeaveApiService {
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  Future<Map<String, dynamic>> getLeaveBalance({
    required String employeeId,
    required String companyId,
  }) async {
    // Use the endpoint you defined in your backend router
    final uri =
        Uri.parse('$baseUrl/api/leave-and-balance/employee/$employeeId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load leave balances');
    }
  }

  Future<void> createLeaveRequest({
    required String employeeId,
    required String companyId,
    required DateTime fromDate,
    required DateTime toDate,
    required bool isHalfDay,
    required String leaveTypeId, // Changed from leaveType
    required String reason,
    dynamic file,
  }) async {
    final uri = Uri.parse('$baseUrl/api/leave-and-balance/request');
    var request = http.MultipartRequest('POST', uri);

    request.fields['employeeId'] = employeeId;
    request.fields['companyId'] = companyId;
    request.fields['fromDate'] = fromDate.toIso8601String();
    request.fields['toDate'] = toDate.toIso8601String();
    request.fields['isHalfDay'] = isHalfDay.toString();
    request.fields['leaveTypeId'] = leaveTypeId; // Matches backend req.body key
    request.fields['reason'] = reason;

    if (file != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      }
    }

    var response = await request.send();
    if (response.statusCode != 201) {
      final resBody = await response.stream.bytesToString();
      throw Exception('Failed to submit leave request: $resBody');
    }
  }

  Future<List<LeaveRequestItem>> getPendingLeaveRequests({
    required String companyId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/leaves/pending?companyId=$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> itemsJson = data['items'] ?? [];
      return itemsJson
          .map((e) => LeaveRequestItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load pending leaves: ${res.body}');
    }
  }

  Future<void> updateLeaveStatus({
    required String employeeId,
    required String leaveRequestId,
    required String status, // "approved" or "rejected"
  }) async {
    final uri = Uri.parse('$baseUrl/api/leaves/status');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'employeeId': employeeId,
        'leaveRequestId': leaveRequestId,
        'status': status,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update leave status: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getEmployeeLeaveRequests(
      {required String employeeId}) async {
    // hits the new /api/leave/employee/:id/requests route
    final uri = Uri.parse(
        '$baseUrl/api/leave-and-balance/employee/$employeeId/requests');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return json.decode(res.body);
      } else {
        throw Exception('Failed to load your requests');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateLeaveRequestStatus({
    required String employeeId,
    required String requestId,
    required String status,
    required String deciderUserId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/leave-and-balance/request/status');

    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'employeeId': employeeId,
        'requestId': requestId,
        'status': status,
        'deciderUserId': deciderUserId, // Sent to backend to fetch AdminDetails
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
          json.decode(res.body)['message'] ?? 'Status update failed');
    }
  }

  Future<void> upsertLeavePolicy({
    required String employeeId,
    required String policyType, // "Monthly" or "Yearly"
    required List<Map<String, dynamic>> policies,
  }) async {
    final uri = Uri.parse('$baseUrl/api/leave-and-balance/upsert');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'employeeId': employeeId,
        'policyType': policyType,
        'policies': policies,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to save policy');
  }

  Future<void> updateBalances({
    required String employeeId,
    required List<Map<String, dynamic>> balances,
  }) async {
    final uri = Uri.parse('$baseUrl/api/leave-and-balance/update-balance');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'employeeId': employeeId, 'balances': balances}),
    );
    if (res.statusCode != 200) throw Exception('Failed to update balances');
  }

  Future<void> resetPolicy(String employeeId) async {
    final uri = Uri.parse('$baseUrl/api/leave-and-balance/reset/$employeeId');
    final res = await http.put(uri);
    if (res.statusCode != 200) throw Exception('Reset failed');
  }
}
