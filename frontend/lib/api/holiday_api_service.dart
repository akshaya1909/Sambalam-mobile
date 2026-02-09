import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_model.dart';

class HolidayApiService {
  // Update with your actual IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET COMPANY HOLIDAYS ---
  Future<List<Holiday>> getCompanyHolidays(String companyId, int year) async {
    final uri = Uri.parse('$baseUrl/api/company/$companyId/holidays/$year');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List<dynamic> list = data['holidays'] ?? [];
      return list.map((e) => Holiday.fromJson(e)).toList();
    } else {
      // It's possible the company has no doc for this year yet, return empty
      return [];
    }
  }

  // --- GET GOVT HOLIDAYS ---
  Future<List<Holiday>> getPublicHolidays(int year) async {
    final uri = Uri.parse('$baseUrl/api/public-holidays/india/$year');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> list = json.decode(res.body);
      // Map API response to our model, setting type to 'National'
      return list
          .map((e) => Holiday(
              name: e['name'],
              date: e['date'],
              type: 'National',
              source: 'api'))
          .toList();
    } else {
      throw Exception('Failed to fetch public holidays');
    }
  }

  // --- SAVE HOLIDAYS ---
  Future<void> saveHolidays(
      String companyId, int year, List<Holiday> holidays) async {
    final uri = Uri.parse('$baseUrl/api/company/$companyId/holidays/$year');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'holidays': holidays.map((h) => h.toJson()).toList(),
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save holidays');
    }
  }
}
