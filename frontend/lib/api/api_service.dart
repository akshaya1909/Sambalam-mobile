import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final Dio _dio;

  // Base URL would be replaced with actual API endpoint in production
  final String baseUrl = 'http://10.80.210.30:5000';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor for debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  // Set auth token for authenticated requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear auth token on logout
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Check if a phone number exists in the backend DB
  Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final response = await _dio.post('/api/check-phone', data: {
        'phoneNumber': phoneNumber,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phoneNumber, "otp": otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend response: $data");
        bool hasCompanies = data['hasCompanies'] ?? false;
        return hasCompanies;
      } else {
        print("Error from backend: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      return false;
    }
  }

  // Create a new user
  Future<User> createUser({
    required String companyId,
    required String name,
    required String phoneNumber,
    String? email,
    required String role,
    File? profileImage,
  }) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, replace with API response
      return User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        companyId: companyId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        role: role,
        profileImage: profileImage?.path, // just storing file path for now
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<User> createUserWithPin(
      String phoneNumber, String pin, String companyId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/update-secure-pin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "secure_pin": pin,
          "companyId": companyId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend response: $data");

        List<dynamic> rolesList = data["role"] is List ? data["role"] : [];
        String primaryRole =
            rolesList.isNotEmpty ? rolesList.first.toString() : "employee";
        // Build a User object – adjust if your backend sends user details
        return User(
          id: data["id"] ?? "unknown", // backend can be updated to send this
          phoneNumber: phoneNumber,
          role: primaryRole,
          companyId: companyId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData["message"] ?? "Failed to set PIN");
      }
    } catch (e) {
      print("Error creating user with PIN: $e");
      rethrow;
    }
  }

  Future<User> getUserById(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    return User(
      id: userId,
      phoneNumber: '9876543210',
      name: 'John Doe',
      email: 'john.doe@example.com',
      role: 'employee',
      companyId: 'company_123',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Attendance>> getUserAttendanceRecords(String userId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Attendance(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        checkInTime: DateTime.now().subtract(const Duration(hours: 8)),
        checkOutTime: DateTime.now(),
        status: 'present',
        remarks: 'On time',
        checkInLatitude: 12.9716, // sample latitude (Bangalore)
        checkInLongitude: 77.5946, // sample longitude
      ),
    ];
  }

  // Verify PIN
  Future<bool> verifyPin(String phoneNumber, String hashedPin) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would validate against the stored hash
      return true; // Mock: always succeed for now
    } catch (e) {
      print('Error verifying PIN: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> _getHardwareInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String fullName =
            "${androidInfo.brand.toUpperCase()} ${androidInfo.model}";
        return {
          'id': androidInfo.id, // Unique Hardware ID
          'model': fullName,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return {
          'id': iosInfo.identifierForVendor ?? 'unknown',
          'model': "Apple ${iosInfo.utsname.machine}",
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return {'id': 'unknown', 'model': 'unknown'};
  }

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String pin,
    String companyId,
    String role,
  ) async {
    try {
      final deviceData = await _getHardwareInfo();
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'pin': pin,
          'companyId': companyId,
          'role': role,
          'deviceId': deviceData['id'],
          'deviceModel': deviceData['model'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login successful: ${data['message']}, role: ${data['role']}');
        return {
          'success': true,
          'status': data['status'],
          'role': data['role'],
          'phoneNumber': data['phoneNumber'],
          'companyId': data['companyId'],
          'employeeId': data['employeeId'],
          'adminId': data['adminId'],
          'userId': data['userId'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('Login failed: ${error['message']}');
        return {'success': false, 'message': error['message']};
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Verify company ID
  Future<Map<String, dynamic>> verifyCompanyId({
    required String teamCode,
    required String phoneNumber,
  }) async {
    final url = Uri.parse('$baseUrl/api/company/validate-teamcode');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'teamCode': teamCode,
        'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)
          as Map<String, dynamic>; // { message, company }
    }

    if (response.statusCode == 404) {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Invalid team code');
    }

    throw Exception(
        'Failed to validate team code: ${response.statusCode} ${response.body}');
  }

  // Mark attendance (check in)
  Future<Attendance> checkIn(String userId, double latitude, double longitude,
      String? imagePath) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return Attendance(
        id: 'attendance_${now.millisecondsSinceEpoch}',
        userId: userId,
        checkInTime: now,
        checkInLatitude: latitude,
        checkInLongitude: longitude,
        checkInImagePath: imagePath,
        status: 'present',
      );
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  // Mark attendance (check out)
  Future<Attendance> checkOut(String attendanceId, double latitude,
      double longitude, String? imagePath) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return Attendance(
        id: attendanceId,
        userId: 'user_id', // In a real app, this would be the actual user ID
        checkInTime:
            now.subtract(const Duration(hours: 8)), // Mock check-in time
        checkOutTime: now,
        checkInLatitude: latitude - 0.001, // Mock check-in location
        checkInLongitude: longitude - 0.001,
        checkOutLatitude: latitude,
        checkOutLongitude: longitude,
        checkOutImagePath: imagePath,
        status: 'present',
      );
    } catch (e) {
      print('Error checking out: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<User> getUserProfile(String userId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      return User(
        id: userId,
        phoneNumber: '9876543210',
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'employee',
        companyId: 'company_123',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Get company details
  Future<Company> getCompanyDetails(String companyId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      return Company(
        id: companyId,
        name: 'Sambalam Technologies',
        address: '123 Tech Park, Bangalore',
        email: 'info@sambalam.com',
        phone: '1234567890',
        website: 'https://sambalam.com',
        latitude: 12.9716,
        longitude: 77.5946,
        attendanceRadius: 100, // 100 meters radius
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error getting company details: $e');
      rethrow;
    }
  }

  // Get all users in a company (for HR/Admin)
  Future<List<User>> getCompanyUsers(String companyId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      return [
        User(
          id: 'user_1',
          phoneNumber: '9876543210',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'employee',
          companyId: companyId,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        User(
          id: 'user_2',
          phoneNumber: '9876543211',
          name: 'Jane Smith',
          email: 'jane.smith@example.com',
          role: 'hr',
          companyId: companyId,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
        User(
          id: 'user_3',
          phoneNumber: '9876543212',
          name: 'Robert Johnson',
          email: 'robert.johnson@example.com',
          role: 'admin',
          companyId: companyId,
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      print('Error getting company users: $e');
      rethrow;
    }
  }

  Future<bool> resetPin({
    required String phoneNumber,
    required String newPin,
    required String companyId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/reset-pin',
        data: {
          'phoneNumber': phoneNumber,
          'newPin': newPin,
          'companyId': companyId, // Crucial for multi-tenant model
        },
      );

      // Dio usually throws on non-200, so if we get here, it's likely success
      return response.statusCode == 200;
    } catch (e) {
      print("ApiService Reset PIN Error: $e");
      return false;
    }
  }

  // Create a leave request
  Future<LeaveRequest> createLeaveRequest(String userId, String userName,
      DateTime startDate, DateTime endDate, String reason) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return LeaveRequest(
        id: 'leave_${now.millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        status: 'pending',
        createdAt: now,
      );
    } catch (e) {
      print('Error creating leave request: $e');
      rethrow;
    }
  }

  // Get leave requests for a user
  Future<List<LeaveRequest>> getUserLeaveRequests(String userId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return [
        LeaveRequest(
          id: 'leave_1',
          userId: userId,
          userName: 'John Doe',
          startDate: now.add(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 7)),
          reason: 'Family vacation',
          status: 'pending',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        LeaveRequest(
          id: 'leave_2',
          userId: userId,
          userName: 'John Doe',
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.subtract(const Duration(days: 8)),
          reason: 'Medical leave',
          status: 'approved',
          approvedBy: 'user_2',
          approvedAt: now.subtract(const Duration(days: 15)),
          createdAt: now.subtract(const Duration(days: 20)),
        ),
      ];
    } catch (e) {
      print('Error getting user leave requests: $e');
      rethrow;
    }
  }

  // Get all leave requests for a company (for HR/Admin)
  Future<List<LeaveRequest>> getCompanyLeaveRequests(String companyId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return [
        LeaveRequest(
          id: 'leave_1',
          userId: 'user_1',
          userName: 'John Doe',
          startDate: now.add(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 7)),
          reason: 'Family vacation',
          status: 'pending',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        LeaveRequest(
          id: 'leave_2',
          userId: 'user_1',
          userName: 'John Doe',
          startDate: now.subtract(const Duration(days: 10)),
          endDate: now.subtract(const Duration(days: 8)),
          reason: 'Medical leave',
          status: 'approved',
          approvedBy: 'user_2',
          approvedAt: now.subtract(const Duration(days: 15)),
          createdAt: now.subtract(const Duration(days: 20)),
        ),
        LeaveRequest(
          id: 'leave_3',
          userId: 'user_2',
          userName: 'Jane Smith',
          startDate: now.add(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 3)),
          reason: 'Personal work',
          status: 'pending',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    } catch (e) {
      print('Error getting company leave requests: $e');
      rethrow;
    }
  }

  // Approve or reject a leave request (for HR/Admin)
  Future<LeaveRequest> updateLeaveRequestStatus(
      String leaveId, String status, String approverUserId,
      {String? rejectionReason}) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return LeaveRequest(
        id: leaveId,
        userId: 'user_1',
        userName: 'John Doe',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 7)),
        reason: 'Family vacation',
        status: status,
        approvedBy: status == 'approved' ? approverUserId : null,
        approvedAt: status == 'approved' ? now : null,
        rejectionReason: status == 'rejected' ? rejectionReason : null,
        createdAt: now.subtract(const Duration(days: 2)),
      );
    } catch (e) {
      print('Error updating leave request status: $e');
      rethrow;
    }
  }

  // Create a new user (for HR/Admin)
  Future<User> createUserByAdmin(String phoneNumber, String name, String email,
      String role, String companyId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return User(
        id: 'user_${now.millisecondsSinceEpoch}',
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        role: role,
        companyId: companyId,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating user by admin: $e');
      rethrow;
    }
  }

  // Update user details (for HR/Admin or self-update)
  Future<User> updateUser({
    required String id,
    String? name,
    String? phoneNumber,
    String? email,
    String? role,
    File? profileImage,
  }) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, replace with API response
      return User(
        id: id,
        companyId: 'company_123', // you can pass this if needed
        name: name ?? 'John Doe',
        phoneNumber: phoneNumber ?? '9876543210',
        email: email ?? 'john.doe@example.com',
        role: role ?? 'employee',
        profileImage: profileImage?.path,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Delete a user (for Admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      return true; // Success
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Get attendance records for a user
  Future<List<Attendance>> getUserAttendance(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return [
        Attendance(
          id: 'attendance_1',
          userId: userId,
          checkInTime: now.subtract(const Duration(days: 1, hours: 9)),
          checkOutTime: now.subtract(const Duration(days: 1, hours: 1)),
          checkInLatitude: 12.9716,
          checkInLongitude: 77.5946,
          checkOutLatitude: 12.9716,
          checkOutLongitude: 77.5946,
          status: 'present',
        ),
        Attendance(
          id: 'attendance_2',
          userId: userId,
          checkInTime: now.subtract(const Duration(days: 2, hours: 9)),
          checkOutTime: now.subtract(const Duration(days: 2, hours: 1)),
          checkInLatitude: 12.9716,
          checkInLongitude: 77.5946,
          checkOutLatitude: 12.9716,
          checkOutLongitude: 77.5946,
          status: 'present',
        ),
      ];
    } catch (e) {
      print('Error getting user attendance: $e');
      rethrow;
    }
  }

  // Get attendance records for all users in a company (for HR/Admin)
  Future<List<Map<String, dynamic>>> getCompanyAttendance(String companyId,
      {DateTime? date}) async {
    try {
      // In a real app, this would be an actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock response - in a real app, this would be from the API
      final now = DateTime.now();
      return [
        {
          'user': User(
            id: 'user_1',
            phoneNumber: '9876543210',
            name: 'John Doe',
            email: 'john.doe@example.com',
            role: 'employee',
            companyId: companyId,
          ),
          'attendance': Attendance(
            id: 'attendance_1',
            userId: 'user_1',
            checkInTime: now.subtract(const Duration(hours: 9)),
            checkOutTime: now.subtract(const Duration(hours: 1)),
            checkInLatitude: 12.9716,
            checkInLongitude: 77.5946,
            checkOutLatitude: 12.9716,
            checkOutLongitude: 77.5946,
            status: 'present',
          ),
        },
        {
          'user': User(
            id: 'user_2',
            phoneNumber: '9876543211',
            name: 'Jane Smith',
            email: 'jane.smith@example.com',
            role: 'hr',
            companyId: companyId,
          ),
          'attendance': Attendance(
            id: 'attendance_2',
            userId: 'user_2',
            checkInTime: now.subtract(const Duration(hours: 8, minutes: 30)),
            checkOutTime: null, // Still checked in
            checkInLatitude: 12.9716,
            checkInLongitude: 77.5946,
            status: 'present',
          ),
        },
        {
          'user': User(
            id: 'user_3',
            phoneNumber: '9876543212',
            name: 'Robert Johnson',
            email: 'robert.johnson@example.com',
            role: 'admin',
            companyId: companyId,
          ),
          'attendance': null, // No attendance record for today
        },
      ];
    } catch (e) {
      print('Error getting company attendance: $e');
      rethrow;
    }
  }

  Future<List<Company>> getUserCompanies(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/companies?phone=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🔵 Get companies status: ${response.statusCode}');
      print('🔵 Get companies response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => Company.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 403) {
        throw Exception('Access denied - not an admin');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to fetch companies');
      }
    } catch (e) {
      print('❌ Get companies error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCompany({
    required String name,
    required String phoneNumber,
    required int staffCount,
    String? category,
    bool sendWhatsappAlerts = true,
    String? logo,
  }) async {
    final url = Uri.parse('$baseUrl/api/company/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phoneNumber': phoneNumber,
        'logo': logo,
        'staffCount': staffCount,
        'category': category,
        'sendWhatsappAlerts': sendWhatsappAlerts,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
        'Failed to create company: ${response.statusCode} ${response.body}');
  }

  Future<void> createJoinRequest({
    required String companyId,
    required String phoneNumber,
    required String name,
    String? email,
    Uint8List? imageBytes,
    String? imageName,
    String? imagePath, // Change String? to File?
  }) async {
    final url = Uri.parse('$baseUrl/api/company/join-request');
    var request = http.MultipartRequest('POST', url);

    // Add text fields
    request.fields['companyId'] = companyId;
    request.fields['phoneNumber'] = phoneNumber;
    request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;

    if (kIsWeb) {
      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? 'profile.jpg',
        ));
      }
    } else {
      if (imagePath != null) {
        // Mobile uses dart:io paths
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createAdminDetails({
    required String phoneNumber,
    required String companyId,
    required String name,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin-details');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token', // if you use JWT
      },
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'companyId': companyId,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'Failed to save admin details: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> createAdvertiseDetails({
    required String adminDetailsId,
    required String companyId,
    List<String>? featuresInterestedIn,
    String? heardFrom,
    String? salaryRange,
  }) async {
    final url = Uri.parse('$baseUrl/api/advertise-details');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'adminDetailsId': adminDetailsId,
        'companyId': companyId,
        'featuresInterestedIn': featuresInterestedIn ?? [],
        'heardFrom': heardFrom,
        'salaryRange': salaryRange,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
        'Failed to save advertise details: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> checkAdminStatus(String phoneNumber) async {
    try {
      // Using standard http.get to match your other methods
      final url = Uri.parse('$baseUrl/api/admin-details/status/$phoneNumber');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'exists': false};
    } catch (e) {
      print("❌ Error checking admin status: $e");
      return {'exists': false};
    }
  }

  Future<List<String>> getAssignedBranches(String companyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('userId'); // Ensure you saved this during login

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/assigned-branches?userId=$userId&companyId=$companyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map the dynamic list to a List of Strings
        return List<String>.from(
            data['assignedBranches'].map((id) => id.toString()));
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching assigned branches: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await _dio.get('/api/system/settings');
      return response.data; // Returns { isMaintenanceMode: true/false }
    } catch (e) {
      // If server is down, we assume it's NOT maintenance so app can try to load
      return {'isMaintenanceMode': false};
    }
  }
}
