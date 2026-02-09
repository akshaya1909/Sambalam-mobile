class Validators {
  /// Validates an Indian phone number
  /// Valid formats: 10 digits starting with 9, 8, 7, or 6
  /// Can optionally include +91 prefix
  static bool isValidIndianPhoneNumber(String phone) {
    // Remove any whitespace
    phone = phone.replaceAll(RegExp(r'\s+'), '');

    // Check if the number starts with +91, remove it
    if (phone.startsWith('+91')) {
      phone = phone.substring(3);
    }

    // Check if it's exactly 10 digits and starts with 9, 8, 7, or 6
    final validPattern = RegExp(r'^[6-9]\d{9}$');
    return validPattern.hasMatch(phone);
  }

  /// Validates a 4-digit PIN
  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// Validates an email address
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates a name (at least 2 characters, letters only)
  static bool isValidName(String name) {
    return name.length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  static bool isValidIFSC(String ifsc) {
    final pattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return pattern.hasMatch(ifsc);
  }

  /// Formats a phone number to standard format: +91 XXXXX XXXXX
  static String formatIndianPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'\D'), '');

    // If it's a 10-digit number, add the +91 prefix
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }

    // If it already has the country code (12 or 13 digits)
    if (phone.length == 12 && phone.startsWith('91')) {
      return '+${phone.substring(0, 2)} ${phone.substring(2, 7)} ${phone.substring(7)}';
    }

    // Return original if it doesn't match expected formats
    return phone;
  }

  static String? validateIndianPhoneNumber(String phone) {
    if (phone.length != 10) return 'Phone number must be exactly 10 digits.';
    final indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!indianPhoneRegex.hasMatch(phone))
      return 'Please enter a valid Indian mobile number.';
    return null;
  }
}
