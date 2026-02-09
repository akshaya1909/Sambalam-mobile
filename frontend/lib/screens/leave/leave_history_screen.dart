import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  bool _isLoading = true;
  List<LeaveRequest> _leaveRequests = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    setState(() {
      _userId = user?['id'];
    });
    
    if (_userId != null) {
      _fetchLeaveRequests();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLeaveRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final leaveRequests = await apiService.getUserLeaveRequests(_userId!);
      
      setState(() {
        _leaveRequests = leaveRequests;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Leave History',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading leave history...')
          : _leaveRequests.isEmpty
              ? const EmptyState(
                  icon: Icons.event_busy,
                  title: 'No Leave Requests',
                  message: 'You haven\'t made any leave requests yet.',
                )
              : RefreshIndicator(
                  onRefresh: _fetchLeaveRequests,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, index) {
                      final leave = _leaveRequests[index];
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
                                  Chip(
                                    label: Text(
                                      _getStatusText(leave.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(leave.status),
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/leave-request').then((_) {
            _fetchLeaveRequests();
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}