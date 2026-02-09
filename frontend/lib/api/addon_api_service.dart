import 'dart:convert';
import 'package:http/http.dart' as http;

class AddonApiService {
  static const String baseUrl = 'http://10.80.210.30:5000';

  Future<List<dynamic>> getAllAddons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/addons'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load addons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching addons: $e');
      rethrow;
    }
  }
}
