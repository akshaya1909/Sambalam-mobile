class ReimbursementRequestItem {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final DateTime dateOfPayment;
  final String notes;
  final List<String> attachments;
  final String status;
  final DateTime requestedOn;

  ReimbursementRequestItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.dateOfPayment,
    required this.notes,
    required this.attachments,
    required this.status,
    required this.requestedOn,
  });

  factory ReimbursementRequestItem.fromJson(Map<String, dynamic> json) {
    return ReimbursementRequestItem(
      id: json['_id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      // Ensure backend populates name or handle fallback here
      employeeName: json['employeeName'] ?? 'Employee',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dateOfPayment: json['dateOfPayment'] != null
          ? DateTime.parse(json['dateOfPayment'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e['url'].toString())
              .toList() ??
          [],
      status: json['status'] ?? 'pending',
      requestedOn: json['requestedOn'] != null
          ? DateTime.parse(json['requestedOn'])
          : DateTime.now(),
    );
  }
}
