import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({Key? key}) : super(key: key);

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<LeaveRequest> _pendingLeaves = [];
  List<LeaveRequest> _approvedLeaves = [];
  List<LeaveRequest> _rejectedLeaves = [];
  late TabController _tabController;
  String? _companyId;
  String? _userId;
  String? _userRole;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    setState(() {
      _userId = user?['id'];
      _companyId = user?['companyId'];
      _userRole = user?['role'];
    });
    
    if (_companyId != null && (_userRole == 'hr' || _userRole == 'admin')) {
      _fetchLeaveRequests();
    } else {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to access this page')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final leaveRequests = await apiService.getCompanyLeaveRequests(_companyId!);
      
      final pending = <LeaveRequest>[];
      final approved = <LeaveRequest>[];
      final rejected = <LeaveRequest>[];
      
      for (final request in leaveRequests) {
        if (request.status == 'pending') {
          pending.add(request);
        } else if (request.status == 'approved') {
          approved.add(request);
        } else if (request.status == 'rejected') {
          rejected.add(request);
        }
      }
      
      setState(() {
        _pendingLeaves = pending;
        _approvedLeaves = approved;
        _rejectedLeaves = rejected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching leave requests: ${e.toString()}')),
      );
    }
  }

  Future<void> _approveLeave(LeaveRequest leave) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateLeaveRequestStatus(
        leave.id,
        'approved',
        _userId!,
        // null,
      );
      
      // Refresh the leave requests
      await _fetchLeaveRequests();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request approved successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving leave request: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectLeave(LeaveRequest leave) async {
    _rejectionReasonController.clear();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final reason = _rejectionReasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason for rejection')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                final apiService = Provider.of<ApiService>(context, listen: false);
                await apiService.updateLeaveRequestStatus(
                  leave.id,
                  'rejected',
                  _userId!,
                  // reason,
                );
                
                // Refresh the leave requests
                await _fetchLeaveRequests();
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leave request rejected successfully')),
                );
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error rejecting leave request: ${e.toString()}')),
                );
              }
            },
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest leave, {bool showActions = false}) {
    final startDate = DateFormat('dd MMM yyyy').format(leave.startDate);
    final endDate = DateFormat('dd MMM yyyy').format(leave.endDate);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${leave.daysRequested} ${leave.daysRequested > 1 ? 'days' : 'day'}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                Text(
                  startDate == endDate
                      ? startDate
                      : '$startDate - $endDate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.subject, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (leave.isRejected && leave.rejectionReason != null) ...[  
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason for rejection: ${leave.rejectionReason}',
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Requested on ${DateFormat('dd MMM yyyy').format(leave.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            if (showActions) ...[  
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectLeave(leave),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _approveLeave(leave),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveList(List<LeaveRequest> leaves, {bool showActions = false}) {
    if (leaves.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy,
        title: 'No Leave Requests',
        message: 'There are no leave requests in this category.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        return _buildLeaveCard(leaves[index], showActions: showActions);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Leave Approval',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading leave requests...')
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(text: 'Pending (${_pendingLeaves.length})'),
                    Tab(text: 'Approved (${_approvedLeaves.length})'),
                    Tab(text: 'Rejected (${_rejectedLeaves.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _fetchLeaveRequests,
                        color: AppTheme.primaryColor,
                        child: _buildLeaveList(_pendingLeaves, showActions: true),
                      ),
                      RefreshIndicator(
                        onRefresh: _fetchLeaveRequests,
                        color: AppTheme.primaryColor,
                        child: _buildLeaveList(_approvedLeaves),
                      ),
                      RefreshIndicator(
                        onRefresh: _fetchLeaveRequests,
                        color: AppTheme.primaryColor,
                        child: _buildLeaveList(_rejectedLeaves),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}