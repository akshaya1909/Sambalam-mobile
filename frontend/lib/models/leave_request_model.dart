class LeaveRequest {
  final String id;
  final String userId;
  final String userName; // For display purposes
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LeaveRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Calculate the number of days requested
  int get daysRequested {
    return endDate.difference(startDate).inDays + 1;
  }

  // Check if the leave request is pending
  bool get isPending => status == 'pending';

  // Check if the leave request is approved
  bool get isApproved => status == 'approved';

  // Check if the leave request is rejected
  bool get isRejected => status == 'rejected';
}