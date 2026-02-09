import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api/api_service.dart';
import '../utils/secure_storage.dart';
import 'storage_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  newUser,
}

class AuthService extends ChangeNotifier {
  final ApiService apiService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final StorageService storageService;
  final SecureStorage _secureStorage = SecureStorage();

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _phoneNumber;
  String? _pin;
  String? _companyId;
  String? _userRole;
  String? _verificationId;
  String? _employeeId;
  String? _adminId;

  AuthService({
    required this.apiService,
    required this.storageService,
  });

  // Getters
  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get companyId => _companyId;
  String? get userRole => _userRole;
  String? get employeeId => _employeeId;
  String? get adminId => _adminId;

  Map<String, dynamic>? get currentUser {
    if (_userId == null) return null;
    return {
      'id': _userId,
      'phoneNumber': _phoneNumber,
      'role': _userRole,
      'companyId': _companyId,
    };
  }

  List<dynamic> _userMemberships = [];
  List<dynamic> get userMemberships => _userMemberships;
  bool _isMaintenanceMode = false;
  bool get isMaintenanceMode => _isMaintenanceMode;

  // Initialize auth state
  Future<void> init() async {
    _userId = await storageService.getUserId();
    _phoneNumber = await storageService.getPhoneNumber();
    _companyId = await storageService.getCompanyId();
    _userRole = await storageService.getUserRole();

    final onboardingComplete = await storageService.getOnboardingComplete();

    if (_userId != null && _phoneNumber != null) {
      _status = AuthStatus.authenticated;
    } else if (onboardingComplete) {
      _status = AuthStatus.unauthenticated;
    } else {
      _status = AuthStatus.newUser;
    }

    notifyListeners();
  }

  // Check if a phone number exists
  Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final response = await apiService.checkPhoneExists(phoneNumber);

      if (response['exists'] == true) {
        // Store memberships in the service for use in SelectCompanyScreen
        _userMemberships = response['memberships'] ?? [];
        notifyListeners();
      }

      return response;
    } catch (e) {
      debugPrint('Error checking phone: $e');
      rethrow;
    }
  }

  bool _biometricEnabled = false;

  bool get biometricEnabled => _biometricEnabled;

  void enableBiometric(bool value) {
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<bool> createUser(String pin, bool enableBiometric) async {
    try {
      // TODO: Replace this with Firebase or backend logic
      _phoneNumber = "dummy"; // or pass phone number from screen
      _pin = pin;
      _biometricEnabled = enableBiometric;

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Sign in with phone number
  Future<bool> signInWithPhone(String phoneNumber) async {
    try {
      _phoneNumber = phoneNumber;
      await storageService.setPhoneNumber(phoneNumber);

      // In a real app, this would trigger Firebase phone auth
      // For now, we'll just return true
      return true;
    } catch (e) {
      print('Error signing in with phone: $e');
      rethrow;
    }
  }

  // Send OTP using Firebase
  Future<void> sendOtp(String phoneNumber) async {
    //comment
    await _firebaseAuth.setSettings(
        appVerificationDisabledForTesting: false, forceRecaptchaFlow: false);
    //comment
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: "+91$phoneNumber",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception("Verification failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        print('DEBUG: codeSent, verificationId=$_verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        print('DEBUG: timeout, verificationId=$_verificationId');
      },
    );
  }

  // Verify OTP
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    if (_verificationId == null) {
      throw Exception("No verification ID. Request OTP first.");
    }

    // Step 1: Verify with Firebase
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Step 2: If Firebase OTP success → Call backend
      // final apiService = ApiService(); // make sure you created an instance
      final success = await apiService.verifyOtp(phoneNumber, otp);

      return success;
    }

    return false;
  }

  // Create user with secure PIN
  Future<bool> createUserWithPin(
      String phoneNumber, String pin, String companyId) async {
    try {
      // if (_phoneNumber == null) {
      //   throw Exception('Phone number not set');
      // }

      // Call backend
      final user =
          await apiService.createUserWithPin(phoneNumber, pin, companyId);
      _phoneNumber = phoneNumber;

      _status = AuthStatus.authenticated;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Verify PIN
  Future<String> verifyPin(
      String phoneNumber, String pin, String companyId, String role) async {
    try {
      final response =
          await apiService.login(phoneNumber, pin, companyId, role);

      if (response['success'] == true) {
        // You can also save the role if needed: response['role']

        _userRole = response['role'];
        _employeeId = response['employeeId'];
        _adminId = response['adminId'];
        _companyId = response['companyId'];
        _userId = response['userId'];
        if (response['status'] == 'device_pending') {
          return 'pending';
        }
        _status = AuthStatus.authenticated;
        notifyListeners();

        return 'success';
      } else {
        // Handle login failure, response['message'] contains error msg
        return 'invalid';
      }
    } catch (e) {
      print('Error verifying PIN: $e');
      rethrow;
    }
  }

  Future<bool> resetPin(
      String phoneNumber, String newPin, String companyId) async {
    try {
      // FIX: Use named arguments here to match the ApiService definition
      final success = await apiService.resetPin(
        phoneNumber: phoneNumber,
        newPin: newPin,
        companyId: companyId,
      );

      if (success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }

      return success;
    } catch (e) {
      print("AuthService Reset PIN Error: $e");
      return false;
    }
  }

  // Set company ID
  Future<String?> setCompanyId(String teamCode, String phoneNumber) async {
    try {
      final result = await apiService.verifyCompanyId(
        teamCode: teamCode,
        phoneNumber: phoneNumber,
      );

      final company = result['company'];
      if (company == null) return null;

      // Mongo style: _id field
      final companyId = company['_id'] as String;
      return companyId;
    } catch (e) {
      print('Error verifying company ID: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear auth data
      _userId = null;
      _phoneNumber = null;
      _companyId = null;
      _userRole = null;
      _status = AuthStatus.unauthenticated;

      // Clear stored data
      await storageService.clearAuthData();

      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    await storageService.setOnboardingComplete(true);
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String> createCompany(
    String companyName,
    String phoneNumber,
    int staffCount,
    String? category,
    bool sendWhatsappAlerts,
  ) async {
    // if (_phoneNumber == null) {
    //   throw Exception('No phone number in session');
    // }

    final result = await apiService.createCompany(
      name: companyName,
      phoneNumber: phoneNumber,
      staffCount: staffCount,
      category: category,
      sendWhatsappAlerts: sendWhatsappAlerts,
    );

    // backend returns { message, company_code }
    // if you also return company _id, store it here
    // e.g. await storageService.setCompanyId(result['companyId']);

    final companyId = result['companyId'] as String;
    _companyId = companyId;
    _phoneNumber = phoneNumber;
    return companyId;
  }

  Future<void> saveAdminAndAdvertiseDetails({
    required String name,
    required String email,
    required String phoneNumber,
    required String companyId,
    required List<String> features,
    String? heardFrom,
    String? salaryRange,
  }) async {
    // 1. create admin details
    final adminRes = await apiService.createAdminDetails(
      phoneNumber: phoneNumber, // Only phoneNumber
      companyId: companyId,
      name: name,
      email: email,
    );

    final adminDetailsId = adminRes['adminDetailsId'] as String;

    // 2. create advertise details
    await apiService.createAdvertiseDetails(
      adminDetailsId: adminDetailsId,
      companyId: companyId,
      featuresInterestedIn: features,
      heardFrom: heardFrom,
      salaryRange: salaryRange,
    );
  }

  Future<bool> hasAdminDetails(String phoneNumber) async {
    // Create an endpoint in your backend that returns true/false
    // if AdminDetails exists for this phoneNumber
    final response = await apiService.checkAdminStatus(phoneNumber);
    return response['exists'] ?? false;
  }

  Future<void> checkMaintenanceStatus() async {
    try {
      final settings = await apiService.getSystemSettings();
      _isMaintenanceMode = settings['isMaintenanceMode'] ?? false;
      notifyListeners(); // This tells the UI to refresh
    } catch (e) {
      debugPrint('Maintenance check failed: $e');
    }
  }
}
