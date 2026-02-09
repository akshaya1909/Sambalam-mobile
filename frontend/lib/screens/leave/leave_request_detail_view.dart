import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml

class LeaveRequestDetailView extends StatelessWidget {
  final Map<String, dynamic> request;

  const LeaveRequestDetailView({Key? key, required this.request})
      : super(key: key);

  // Helper to format Date with Time
  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final dt = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';
    final deciderName = request['decidedBy']?['name'] ?? 'Admin';
    final docUrl = request['documentUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Request Details',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(Icons.info_outline,
                        color: _getStatusColor(status)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.toUpperCase(),
                          style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold)),
                      Text(
                          'Requested on ${_formatDateTime(request['requestedAt'])}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Request Details Card
            _buildSection(
              title: "Leave Information",
              children: [
                _detailRow("Type", request['leaveTypeId']?['name'] ?? 'Leave'),
                _detailRow("Duration",
                    request['isHalfDay'] == true ? "Half Day" : "Full Day"),
                _detailRow("From", _formatDateTime(request['fromDate'])),
                _detailRow("To", _formatDateTime(request['toDate'])),
                _detailRow("Reason", request['reason'] ?? 'No reason provided'),
              ],
            ),
            const SizedBox(height: 20),

            // Approval Info (Only show if not pending)
            if (status != 'pending')
              _buildSection(
                title: "Approval Information",
                children: [
                  _detailRow(
                      "Status", status == 'approved' ? "Accepted" : "Declined"),
                  _detailRow("Processed By", deciderName),
                  _detailRow("Time", _formatDateTime(request['decidedAt'])),
                ],
              ),

            const SizedBox(height: 20),

            // Document Link
            if (docUrl != null && docUrl.isNotEmpty)
              _buildSection(
                title: "Attachments",
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description, color: Colors.blue),
                    title: const Text("View Supporting Document",
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline)),
                    onTap: () async {
                      final url = Uri.parse(
                          "https://sambalam.ifoxclicks.com$docUrl"); // Your Base URL
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey)),
          const Divider(height: 24),
          ...children
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}
