class AppConstants {
  // App Info
  static const String appName = 'Sambalam';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Simplified Attendance Management';
  
  // API Constants
  static const String baseUrl = 'https://api.sambalam.com/v1';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Validation Constants
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;
  static const int pinLength = 4;
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int companyIdLength = 6;
  
  // Location Constants
  static const double defaultOfficeRadius = 100.0; // meters
  static const int locationTimeoutSeconds = 15;
  
  // Animation Constants
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 800; // milliseconds
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String timeoutErrorMessage = 'Request timed out. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  static const String invalidPhoneMessage = 'Please enter a valid 10-digit phone number';
  static const String invalidOtpMessage = 'Please enter a valid 6-digit OTP';
  static const String invalidPinMessage = 'Please enter a valid 4-digit PIN';
  static const String pinMismatchMessage = 'PINs do not match. Please try again.';
  static const String invalidCompanyIdMessage = 'Please enter a valid company ID';
  static const String locationPermissionMessage = 'Location permission is required for attendance';
  static const String cameraPermissionMessage = 'Camera permission is required for attendance';
  
  // Success Messages
  static const String otpSentMessage = 'OTP sent successfully';
  static const String pinCreatedMessage = 'PIN created successfully';
  static const String biometricEnabledMessage = 'Biometric login enabled';
  static const String biometricDisabledMessage = 'Biometric login disabled';
  static const String checkInSuccessMessage = 'Check-in recorded successfully';
  static const String checkOutSuccessMessage = 'Check-out recorded successfully';
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableLocationTracking = true;
  static const bool enableOfflineMode = false;
  static const bool enablePushNotifications = true;
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'employee';
  
  // Attendance Status
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusHalfDay = 'half_day';
  static const String statusLeave = 'leave';
  static const String statusHoliday = 'holiday';
  static const String statusWeekend = 'weekend';
}