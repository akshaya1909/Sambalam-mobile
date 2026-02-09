import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AnnouncementApiService {
  static const String baseUrl =
      'http://10.80.210.30:5000'; // Update with your API URL

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String description,
    required List<String> targetBranchIds, // Renamed
    required bool isAllBranches,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('adminId');
    final companyId = prefs.getString('companyId');

    if (adminId == null) {
      throw Exception('Admin ID not found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/announcements/create/$adminId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'companyId': companyId, // MANDATORY: The parent company
        'targetBranchIds': targetBranchIds,
        'isAllBranches': isAllBranches,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to create announcement: ${response.body}');
    }
  }

  static Future<List<dynamic>> getCompanyAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId');

    // CRITICAL: You must fetch the userId here to pass it to the backend
    final userId = prefs.getString('userId');

    if (companyId == null) {
      throw Exception('Company ID not found');
    }

    // Construct URL with userId query parameter
    final String url = userId != null
        ? '$baseUrl/api/announcements/company/$companyId?userId=$userId'
        : '$baseUrl/api/announcements/company/$companyId';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data['data']);
    } else {
      throw Exception('Failed to load announcements');
    }
  }

  static Future<void> markAsRead(String announcementId, String userId) async {
    final url = Uri.parse('$baseUrl/api/announcements/$announcementId/read');
    try {
      await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  static Future<int> getUnreadCount(String companyId, String userId) async {
    final url =
        Uri.parse('$baseUrl/api/announcements/unread-count/$companyId/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
    return 0;
  }
}
