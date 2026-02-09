class BankDetails {
  final String? id;
  final String? employeeId;
  final String? type;

  // Bank Fields
  final String? accountHolderName;
  final String? accountNumber;
  final String? bankName;
  final String? ifscCode;
  final String? branch;
  final String? accountType;
  final bool isAccnVerified;

  // UPI Fields
  final String? upiId;
  final String? linkedMobileNumber;
  final bool isUpiVerified;

  BankDetails({
    this.id,
    this.employeeId,
    this.type,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.ifscCode,
    this.branch,
    this.accountType,
    this.isAccnVerified = false,
    this.upiId,
    this.linkedMobileNumber,
    this.isUpiVerified = false,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      id: json['_id'],
      employeeId: json['employeeId'],
      type: json['type'],
      accountHolderName: json['accountHolderName'],
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      ifscCode: json['ifscCode'],
      branch: json['branch'],
      accountType: json['accountType'],
      isAccnVerified: json['isAccnVerified'] ?? false,
      upiId: json['upiId'],
      linkedMobileNumber: json['linkedMobileNumber'],
      isUpiVerified: json['isUpiVerified'] ?? false,
    );
  }
}
