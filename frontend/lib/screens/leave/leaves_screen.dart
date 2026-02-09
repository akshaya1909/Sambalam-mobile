import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'request_leave_screen.dart';
import 'leave_request_detail_view.dart';
import '../../widgets/employee_bottom_nav.dart';
import '../home/employee_home_screen.dart';
import '../profile/profile_screen.dart';
import '../../../api/leave_api_service.dart';

class LeavesScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;

  const LeavesScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
  }) : super(key: key);

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color _primary = const Color(0xFF206C5E); // teal like other new screens
  String? _employeeId;
  final LeaveApiService _leaveApi = LeaveApiService();

  int _privilegeCurrent = 0;
  int _sickCurrent = 0;
  int _casualCurrent = 0;
  List<dynamic> _leaveBalances = [];
  bool _isLoadingBalance = true;

  List<dynamic> _pendingRequests = [];
  List<dynamic> _historyRequests = [];
  bool _isLoadingRequests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployeeId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRequestLeave() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => RequestLeaveScreen(
          leaveBalances: _leaveBalances, // Pass the dynamic list you fetched
        ),
      ),
    )
        .then((value) {
      if (value == true) {
        // Refresh logic if a leave was submitted
        _loadLeaveRequests(_employeeId!);
        _loadLeaveBalance(_employeeId!);
      }
    });
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('employeeId');
    setState(() {
      _employeeId = id;
    });
    if (id != null) {
      await Future.wait([
        _loadLeaveBalance(id),
        _loadLeaveRequests(id),
      ]);
    } else {
      setState(() {
        _isLoadingBalance = false;
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadLeaveBalance(String employeeId) async {
    try {
      final response = await _leaveApi.getLeaveBalance(
        employeeId: employeeId,
        companyId: widget.companyId,
      );

      // According to your backend controller: res.status(200).json({ data: doc });
      final data = response['data'];

      setState(() {
        if (data != null && data['balances'] != null) {
          _leaveBalances = data['balances'];
        }
        _isLoadingBalance = false;
      });
    } catch (e) {
      debugPrint("Error loading balances: $e");
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _loadLeaveRequests(String employeeId) async {
    setState(() => _isLoadingRequests = true);
    try {
      // Calling the new employee-specific API
      final data =
          await _leaveApi.getEmployeeLeaveRequests(employeeId: employeeId);

      setState(() {
        // The backend now returns them pre-separated
        _pendingRequests = List<dynamic>.from(data['pending'] ?? []);
        _historyRequests = List<dynamic>.from(data['history'] ?? []);
        _isLoadingRequests = false;
      });
    } catch (e) {
      debugPrint("Error loading requests: $e");
      setState(() => _isLoadingRequests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color _primaryStart = const Color(0xFF206C5E);
    final Color _primaryEnd = const Color(0xFF2BA98A);
    final Color bg = const Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Transparent for modern look
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: _primaryStart),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          'Leave Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _headerCard(),
            const SizedBox(height: 14),
            _tabSwitcher(),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openRequestLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Request leave',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            EmployeeBottomNav(
              selectedIndex: 1,
              activeColor: _primary,
              onItemSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => EmployeeHomeScreen(
                        phoneNumber: widget.phoneNumber,
                        companyId: widget.companyId,
                      ),
                    ),
                    (route) => false,
                  );
                } else if (index == 2) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        phoneNumber: widget.phoneNumber,
                        companyId: widget.companyId,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.beach_access_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your leaves',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track balance, pending approvals and leave history.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            tabBarTheme: const TabBarThemeData(
              // if your SDK still uses TabBarTheme, keep TabBarTheme but
              // WITHOUT const TabBarTheme(…) error comes from type mismatch
              dividerColor: Colors.transparent, // removes bottom line
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.black,
            unselectedLabelColor: const Color(0xFF6B7280),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Requests (${_pendingRequests.length})'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 16),
                    SizedBox(width: 6),
                    Text('History'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isLoadingBalance
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _balanceCard(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Pending requests',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _isLoadingRequests
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _pendingRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending requests',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final req = _pendingRequests[index];
                        return _buildLeaveRequestCard(
                            req as Map<String, dynamic>);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    if (_leaveBalances.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No leave policy assigned."),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            children: _leaveBalances.asMap().entries.map((entry) {
              int idx = entry.key;
              var balance = entry.value;

              // Extract the name from the populated leaveTypeId object
              String name = balance['leaveTypeId']?['name'] ?? 'Leave';
              double current = (balance['current'] as num? ?? 0).toDouble();

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceItem(
                        label: name,
                        balance:
                            current, // Changed _BalanceItem to accept double
                      ),
                    ),
                    // Add vertical divider except for the last item
                    if (idx < _leaveBalances.length - 1)
                      const VerticalDivider(
                        color: Color(0xFFE5E7EB),
                        thickness: 1,
                        width: 20,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _isLoadingRequests
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : _historyRequests.isEmpty
            ? const Center(
                child: Text(
                  'No history yet',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                itemCount: _historyRequests.length,
                itemBuilder: (context, index) {
                  final req = _historyRequests[index];
                  return _buildLeaveRequestCard(req as Map<String, dynamic>);
                },
              );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF97316);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDateFull(DateTime date) {
    final day = date.day;
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
    final month = months[date.month - 1];
    final year = date.year.toString().substring(2);
    return '$day $month $year';
  }

  String _formatTimeWithAmPm(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildLeaveRequestCard(Map<String, dynamic> req) {
    final type = req['leaveTypeId'] != null
        ? req['leaveTypeId']['name']
        : (req['leaveType'] ?? 'Leave');
    final fromDate = req['fromDate'] != null
        ? DateTime.parse(req['fromDate']).toLocal()
        : DateTime.now();
    final toDate = req['toDate'] != null
        ? DateTime.parse(req['toDate']).toLocal()
        : DateTime.now();
    final status = req['status'] ?? 'pending';
    final reason = req['reason'] ?? '';
    final isHalfDay = req['isHalfDay'] ?? false;
    final requestedAt = req['requestedAt'] != null
        ? DateTime.parse(req['requestedAt']).toLocal()
        : DateTime.now();

    return InkWell(
      onTap: () {
        // Navigate to Detail View
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LeaveRequestDetailView(request: req),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row: status + type + requested at
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        isHalfDay ? 'Half day' : 'Full days',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 3),
                    Text(
                      '${_formatDateFull(requestedAt)} • ${_formatTimeWithAmPm(requestedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHalfDay
                            ? _formatDateFull(fromDate)
                            : '${_formatDateFull(fromDate)} → ${_formatDateFull(toDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double balance;

  const _BalanceItem({
    Key? key,
    required this.label,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayBalance =
        balance % 1 == 0 ? balance.toInt().toString() : balance.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11, // Slightly smaller to accommodate dynamic text
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayBalance,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
