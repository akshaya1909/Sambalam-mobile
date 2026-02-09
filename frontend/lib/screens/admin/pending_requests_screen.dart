import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports (Adjust paths based on your project structure)
import '../../api/leave_api_service.dart';
import '../../api/admin_api_service.dart';
import '../../models/leave_request_item.dart';
import '../../api/reimbursement_api_service.dart';
import '../../models/reimbursement_request_item.dart';
import '../leave/leave_request_detail_screen.dart'; // Ensure this exists or use modal logic

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // APIs
  final LeaveApiService _leaveApi = LeaveApiService();
  final ReimbursementApiService _reimbursementApi = ReimbursementApiService();
  final AdminApiService _adminApi = AdminApiService();

  // Data Lists
  List<LeaveRequestItem> _leaveItems = [];
  List<ReimbursementRequestItem> _reimbursementItems = [];
  List<dynamic> _deviceItems = [];

  // Loading State
  bool _isLoading = true;

  static const Color primaryGreen = Color(0xFF206C5E);
  static const Color primaryGradientEnd = Color(0xFF2BA98A);
  static const Color topBarColor = Color(0xFF232B2F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllPendingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllPendingData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch both in parallel
      final results = await Future.wait([
        _leaveApi.getPendingLeaveRequests(companyId: companyId),
        _reimbursementApi.getPendingReimbursements(companyId),
        _adminApi.getPendingDeviceRequests(companyId),
      ]);

      if (mounted) {
        setState(() {
          _leaveItems = results[0] as List<LeaveRequestItem>;
          _reimbursementItems = results[1] as List<ReimbursementRequestItem>;
          _deviceItems = results[2] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  void _handleReimbursementAction(
      ReimbursementRequestItem item, String status) async {
    try {
      await _reimbursementApi.updateReimbursementStatusByAdmin(
          reimbursementId: item.id, status: status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Reimbursement $status"),
            backgroundColor: status == 'approved' ? primaryGreen : Colors.red,
          ),
        );
        _fetchAllPendingData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _handleDeviceAction(String requestId, String action) async {
    try {
      await _adminApi.processDeviceRequest(requestId, action);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Device $action")));
      _fetchAllPendingData(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showDeviceRequestDetails(dynamic request) {
    String formattedDate = "N/A";
    try {
      DateTime dt = DateTime.parse(request['requestedAt']).toLocal();
      DateTime now = DateTime.now();

      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        formattedDate = "Today, ${DateFormat('hh:mm a').format(dt)}";
      } else if (dt.day == now.subtract(const Duration(days: 1)).day) {
        formattedDate = "Yesterday, ${DateFormat('hh:mm a').format(dt)}";
      } else {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    } catch (e) {
      debugPrint("Date parsing error: $e");
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Device Approval",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Employee", request['name']),
            _infoRow("Phone", request['phoneNumber']),
            _infoRow("New Device", request['newDeviceModel'], isBold: true),
            _infoRow("Device ID", request['newDeviceId']),
            _infoRow("Requested On", formattedDate),
            const SizedBox(height: 12),
            const Text(
              "Note: Approving this will allow the user to mark attendance from this phone only.",
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleDeviceAction(request['_id'], 'rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleDeviceAction(request['_id'], 'approved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Approve",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    const Color topBarColor = Color(0xFF232B2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: topBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pending Requests',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Tabs Container
          Container(
            color: topBarColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14191D),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryGreen, primaryGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Leaves (${_leaveItems.length})'),
                  Tab(text: 'Devices (${_deviceItems.length})'),
                  Tab(text: 'Reimburse. (${_reimbursementItems.length})'),
                ],
              ),
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaveTab(),
                      _buildDeviceTab(),
                      _buildReimbursementTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- LEAVE TAB ---
  Widget _buildLeaveTab() {
    final filtered = _leaveItems
        .where((e) =>
            e.name.toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(
          child: Text('No pending leave requests',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return InkWell(
          onTap: () async {
            // Navigate to detail screen or show bottom sheet
            // Assuming LeaveRequestDetailScreen exists from previous code
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => LeaveRequestDetailScreen(item: item),
              ),
            );
            if (changed == true) _fetchAllPendingData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2D9CDB),
                  child: Text(
                    item.displayInitial,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM')
                                .format(item.fromDate), // Simple format
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text("|  ${item.durationLabel}",
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceTab() {
    final filtered = _deviceItems
        .where((e) => e['name']
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(
          child: Text("No device verifications",
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final request = filtered[index];
        return InkWell(
          onTap: () => _showDeviceRequestDetails(request),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.phone_android, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['name'],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        "${request['newDeviceModel']} • ${request['phoneNumber']}",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text("New Device",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- REIMBURSEMENT TAB ---
  Widget _buildReimbursementTab() {
    final filtered = _reimbursementItems
        .where((e) => e.employeeName
            .toLowerCase()
            .contains(_searchController.text.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(
          child: Text('No pending reimbursements',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return InkWell(
          onTap: () => _showReimbursementDetails(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.receipt_long, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.employeeName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        "₹${item.amount.toStringAsFixed(2)}  •  ${DateFormat('dd MMM').format(item.dateOfPayment)}",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text("Pending",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- REIMBURSEMENT DETAIL SHEET ---
  void _showReimbursementDetails(ReimbursementRequestItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Reimbursement Details",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Employee", item.employeeName),
            _infoRow("Amount", "₹${item.amount.toStringAsFixed(2)}",
                isBold: true),
            _infoRow(
                "Date", DateFormat('dd MMM yyyy').format(item.dateOfPayment)),
            _infoRow("Notes", item.notes.isEmpty ? "No notes" : item.notes),
            const SizedBox(height: 16),

            // Attachments
            const Text("Attachments",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            if (item.attachments.isNotEmpty)
              Wrap(
                spacing: 8,
                children: item.attachments
                    .map((url) => InkWell(
                          onTap: () {
                            // Handle open logic
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Open attachment (Mock)")));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.attachment,
                                color: Colors.blue),
                          ),
                        ))
                    .toList(),
              )
            else
              const Text("No attachments", style: TextStyle(fontSize: 14)),

            const SizedBox(height: 30),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleReimbursementAction(item, 'rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleReimbursementAction(item, 'approved');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontSize: isBold ? 16 : 14))),
        ],
      ),
    );
  }
}
