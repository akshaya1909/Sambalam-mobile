import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../models/staff_model.dart'; // Ensure you have this from previous code

class NotificationApiService {
  static const String baseUrl =
      'https://sambalam.ifoxclicks.com/api'; // Update IP

  Future<List<NotificationModel>> getNotifications({
    required String companyId,
    String? type,
    String? employeeId,
  }) async {
    String url = '$baseUrl/notifications?companyId=$companyId';
    if (type != null && type != "All Notifications") url += '&type=$type';
    if (employeeId != null) url += '&employeeId=$employeeId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Reuse your existing getStaffList from company_api_service if possible
}
