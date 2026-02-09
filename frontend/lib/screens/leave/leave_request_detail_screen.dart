// lib/ui/leaves/leave_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/leave_api_service.dart';
import '../../models/leave_request_item.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final LeaveRequestItem item;

  LeaveRequestDetailScreen({Key? key, required this.item}) : super(key: key);
  final LeaveApiService _leaveApi = LeaveApiService();

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }

  Future<void> _handleAction(BuildContext context,
      {required String status}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve leave?' : 'Reject leave?'),
        content: const Text(
            'Confirming this will update the employee\'s leave balance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'approved' ? 'Approve' : 'Reject',
                style: TextStyle(
                    color: status == 'approved' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId =
          prefs.getString('userId'); // Required for decider field

      // Logic: Decrease from employee happens in this backend controller call
      await _leaveApi.updateLeaveRequestStatus(
        employeeId: item.employeeId,
        requestId: item.id,
        status: status,
        deciderUserId: currentUserId ?? '',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Leave $status successfully')));
      Navigator.of(context).pop(true); // Return true to refresh parent list
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF206C5E);
    final Color accentGreen = const Color(0xFF2BA98A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF232B2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(item.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildInfoSection(
                    'Leave Duration',
                    "${_formatDate(item.fromDate)} - ${_formatDate(item.toDate)}",
                    Icons.calendar_month),
                _buildInfoSection(
                    'Requested for', item.durationLabel, Icons.timer_outlined),
                _buildInfoSection(
                    'Leave Type', item.leaveTypeName, Icons.category_outlined),
                _buildInfoSection(
                    'Notes',
                    item.reason.isEmpty ? 'No notes provided' : item.reason,
                    Icons.notes),

                // --- ATTACHMENTS SECTION ---
                const Text('Attachments',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 12),
                if (item.documentUrl != null && item.documentUrl!.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                          "https://sambalam.ifoxclicks.com${item.documentUrl}");
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.file_present_rounded, color: Colors.blue),
                          SizedBox(width: 12),
                          Text("View Supporting Document",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  const Text('No Attachments provided',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          // Bottom Action Buttons
          if (item.status == 'pending')
            _buildBottomActions(context, primaryGreen, accentGreen),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB))),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Color start, Color end) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleAction(context, status: 'rejected'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [start, end]),
              ),
              child: ElevatedButton(
                onPressed: () => _handleAction(context, status: 'approved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Approve',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
