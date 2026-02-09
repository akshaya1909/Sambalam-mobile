class Reimbursement {
  final String id;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime date;
  final String notes;
  final List<String> attachments; // URLs

  Reimbursement({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
    required this.notes,
    required this.attachments,
  });

  factory Reimbursement.fromJson(Map<String, dynamic> json) {
    return Reimbursement(
      id: json['_id'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      date: DateTime.parse(json['requestedOn']),
      notes: json['notes'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e['url'].toString())
              .toList() ??
          [],
    );
  }
}
