import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Add this for kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NotesApiService {
  static const String baseUrl = 'http://10.80.210.30:5000/api/notes';

  // Fetch private notes for this employee
  Future<List<dynamic>> fetchNotes(String employeeId) async {
    final response = await http.get(Uri.parse('$baseUrl/$employeeId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load notes');
  }

  // Send a text note
  Future<void> sendNote({
    required String employeeId,
    required String companyId,
    required String senderId,
    required String senderName,
    required String senderType,
    String? text,
    PlatformFile? file, // Accept the picked file
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

    // 1. Add Text Fields
    request.fields['employeeId'] = employeeId;
    request.fields['companyId'] = companyId;
    request.fields['senderId'] = senderId;
    request.fields['senderName'] = senderName;
    request.fields['senderType'] = senderType;
    request.fields['text'] = text ?? "";

    // 2. Add File if it exists
    if (file != null) {
      if (kIsWeb) {
        // Web uses bytes
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType(
              'application', 'octet-stream'), // or detect specific type
        ));
      } else {
        // Mobile uses path
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      }
    }

    var streamedResponse = await request.send();
    if (streamedResponse.statusCode != 201) {
      throw Exception('Failed to send note/file');
    }
  }

  // Validate file size (5MB limit) before processing
  bool isFileValid(File file) {
    const int maxBytes = 5 * 1024 * 1024; // 5MB
    return file.lengthSync() <= maxBytes;
  }
}
