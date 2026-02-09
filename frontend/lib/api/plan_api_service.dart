import 'dart:convert';
import 'package:http/http.dart' as http;
import 'company_api_service.dart'; // To reuse the baseUrl

class PlanApiService {
  // Use the same baseUrl defined in your CompanyApiService
  static const String baseUrl = 'http://10.80.210.30:5000';

  Future<List<dynamic>> getAllPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/plans'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching plans: $e');
      rethrow;
    }
  }
}
