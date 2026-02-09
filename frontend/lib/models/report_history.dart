class ReportHistory {
  final String id;
  final String reportType;
  final String branch;
  final String duration;
  final String format;
  final String status;
  final DateTime createdAt;

  ReportHistory({
    required this.id,
    required this.reportType,
    required this.branch,
    required this.duration,
    required this.format,
    required this.status,
    required this.createdAt,
  });

  factory ReportHistory.fromJson(Map<String, dynamic> json) {
    return ReportHistory(
      id: json['_id'] ?? '',
      reportType: json['reportType'] ?? '',
      branch: json['branch'] ?? 'All Branches',
      duration: json['duration'] ?? '',
      format: json['format'] ?? 'XLSX',
      status: json['status'] ?? 'Ready',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
