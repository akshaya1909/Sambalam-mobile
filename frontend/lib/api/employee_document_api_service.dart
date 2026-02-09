import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this to pubspec
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_document.dart';

class EmployeeDocumentApiService {
  // Update with your actual server IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // GET Employee Documents (Usually part of getEmployeeDetails, but let's assume we extract it)
  // Or fetch specifically if you have an endpoint.
  // Based on your React code, it fetches the whole employee.
  // Let's reuse your existing EmployeeApiService logic or create a fetch here.
  Future<List<EmployeeDocument>> getDocuments(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? companyId = prefs.getString('companyId');

    if (companyId == null) {
      throw Exception('Company ID not found in session');
    }

    // Append the companyId as a query parameter
    final url = Uri.parse(
        '$baseUrl/api/employees/get/$employeeId?companyId=$companyId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // Navigate to the 'employee' object, then 'documents' array
      final employeeData = data['employee'];
      if (employeeData == null || employeeData['documents'] == null) {
        return [];
      }

      final List list = employeeData['documents'];
      return list.map((json) => EmployeeDocument.fromJson(json)).toList();
    } else {
      // This will now capture the 'companyId is required' message if it fails
      throw Exception('Failed to load documents: ${response.body}');
    }
  }

  // POST Upload Document
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    Uint8List? fileBytes, // For Web
    String? filePath, // For Mobile
    required String name,
    required String category,
  }) async {
    final token = await _getToken();
    // Ensure we have companyId (Safety fallback for refresh)
    final prefs = await SharedPreferences.getInstance();
    final String? companyId = prefs.getString('companyId');

    if (companyId == null) {
      throw Exception('Company ID missing. Please login again.');
    }

    // Construct URL with companyId as query param if your backend requires it
    final uri = Uri.parse(
        '$baseUrl/api/employees/$employeeId/documents?companyId=$companyId');

    var request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add Metadata Fields
    request.fields['name'] = name;
    request.fields['category'] = category;

    // Determine Mime Type safely
    String mimeType =
        name.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';

    // Handle Multi-platform File Upload
    if (fileBytes != null) {
      // WEB FLOW: Use bytes
      request.files.add(http.MultipartFile.fromBytes(
        'file', // Must match upload.single('file') in your express route
        fileBytes,
        filename: name,
        contentType: MediaType.parse(mimeType),
      ));
    } else if (filePath != null) {
      // MOBILE FLOW: Use file path
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType.parse(mimeType),
      ));
    } else {
      throw Exception('No file data provided');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      // Based on your controller, it returns { message, document }
      return EmployeeDocument.fromJson(data['document']);
    } else {
      // Helpful debugging for 500 errors
      print("Upload Failed: ${response.body}");
      throw Exception('Failed to upload: ${response.body}');
    }
  }

  // DELETE Document
  Future<void> deleteDocument(String employeeId, String docId) async {
    final token = await _getToken();
    final uri =
        Uri.parse('$baseUrl/api/employees/$employeeId/documents/$docId');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document');
    }
  }
}
