import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/leave_api_service.dart';
import '../../models/leave_request_item.dart';

class LeaveRequestsAdminScreen extends StatefulWidget {
  const LeaveRequestsAdminScreen({Key? key}) : super(key: key);

  @override
  State<LeaveRequestsAdminScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaveApiService _leaveApi = LeaveApiService();

  // State variables
  bool _isLoading = true;
  List<LeaveRequestItem> _allRequests = [];
  List<LeaveRequestItem> _pendingRequests = [];
  List<LeaveRequestItem> _historyRequests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final requests =
            await _leaveApi.getPendingLeaveRequests(companyId: companyId);

        setState(() {
          _allRequests = requests;
          _filterRequests();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading leaves: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterRequests() {
    _pendingRequests =
        _allRequests.where((r) => r.status == 'pending').toList();
    _historyRequests =
        _allRequests.where((r) => r.status != 'pending').toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _pendingRequests = _pendingRequests
          .where((r) => r.name.toLowerCase().contains(query))
          .toList();
      _historyRequests = _historyRequests
          .where((r) => r.name.toLowerCase().contains(query))
          .toList();
    }
  }

  Future<void> _updateStatus(LeaveRequestItem request, String status) async {
    try {
      Navigator.pop(context); // Close details sheet

      await _leaveApi.updateLeaveStatus(
        employeeId: request.employeeId,
        leaveRequestId: request.id,
        status: status,
      );

      _loadLeaveRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Request ${status == 'approved' ? 'Approved' : 'Rejected'}"),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showLeaveDetails(LeaveRequestItem request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LeaveDetailSheet(
        request: request,
        onAction: (status) => _updateStatus(request, status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leave Requests',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'PENDING REQUESTS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employee',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _filterRequests();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(_pendingRequests, isHistory: false),
                      _buildRequestList(_historyRequests, isHistory: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<LeaveRequestItem> requests,
      {required bool isHistory}) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isHistory ? "No history found" : "No pending requests",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = requests[index];
        return InkWell(
          onTap: () => _showLeaveDetails(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar (Initials Only)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(item.name),
                  child: Text(
                    item.displayInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          _buildStatusBadge(item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatDateRange(item.fromDate, item.toDate),
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                  left: BorderSide(color: Colors.grey[300]!)),
                            ),
                            child: Text(
                              item.durationLabel,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 18, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAvatarColor(String name) {
    // Generate a consistent color based on the name hash
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF9A825);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'approved') ...[
            Icon(Icons.check_circle, size: 12, color: text),
            const SizedBox(width: 4),
          ] else if (status == 'pending') ...[
            Icon(Icons.access_time_filled, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final f = DateFormat('dd MMM yyyy (EEE)');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return f.format(start);
    }
    return "${DateFormat('dd MMM yyyy').format(start)} - ${f.format(end)}";
  }
}

// --- Detail Sheet Widget ---
class _LeaveDetailSheet extends StatelessWidget {
  final LeaveRequestItem request;
  final Function(String) onAction;

  const _LeaveDetailSheet({
    Key? key,
    required this.request,
    required this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'pending';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // Initials Avatar in Detail View
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue, // Or pass color from list
                    child: Text(
                      request.displayInitial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    request.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              _buildStatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 24),

          _buildDetailRow("Leave Duration",
              _formatDateRange(request.fromDate, request.toDate)),
          const Divider(height: 30),

          _buildDetailRow("Requested for", request.durationLabel),
          const SizedBox(height: 20),

          _buildDetailRow("Leave type", request.type),
          const Divider(height: 30),

          // Notes
          const Text("Notes",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            request.reason.isEmpty ? "No reason provided." : request.reason,
            style: const TextStyle(fontSize: 15, height: 1.3),
          ),
          const SizedBox(height: 20),

          // Attachments placeholder
          const Text("Attachments",
              style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          // Check if documentUrl exists (dummy check for now)
          Text(
              request.documentUrl != null && request.documentUrl!.isNotEmpty
                  ? "Attachment available (Download logic needed)"
                  : "No Attachments",
              style: const TextStyle(color: Colors.grey, fontSize: 14)),

          const SizedBox(height: 20),

          // Timestamp
          Text(
            "Requested on\n${DateFormat('dd MMM yyyy, hh:mm a').format(request.requestedAt)}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 30),

          // Action Buttons (Only for Pending)
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAction('rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAction('approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E9),
                      foregroundColor: const Color(0xFF2E7D32),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "Processed on ${DateFormat('dd MMM').format(DateTime.now())}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        text = const Color(0xFFC62828);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFF9A825);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: text, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final f = DateFormat('dd MMM yyyy (EEE)');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return f.format(start);
    }
    return "${DateFormat('dd MMM yyyy').format(start)} - ${f.format(end)}";
  }
}
