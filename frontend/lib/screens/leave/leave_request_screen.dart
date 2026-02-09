import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api/api.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  String? _userId;
  String? _userName;

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
      _userName = user?['phoneNumber'];
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, update end date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null || _userName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not available. Please try again.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final leaveRequest = await apiService.createLeaveRequest(
          _userId!,
          _userName!,
          _startDate,
          _endDate,
          _reasonController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Show success dialog
        await DialogHelper.showSuccessDialog(
          context : context,
          title : 'Leave Request Submitted',
          message: 'Your leave request has been submitted successfully. You will be notified once it is approved.',
        );

        // Navigate back
        Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Show error dialog
        DialogHelper.showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Failed to submit leave request. Please try again.\n\nError: ${e.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int daysRequested = _endDate.difference(_startDate).inDays + 1;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Request Leave',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Submitting leave request...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selection
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Dates',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Date'),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _selectStartDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy').format(_startDate),
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const Icon(Icons.calendar_today, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Date'),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _selectEndDate(context),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy').format(_endDate),
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const Icon(Icons.calendar_today, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total days requested: $daysRequested',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reason
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reason for Leave',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                           TextFormField(
  controller: _reasonController,
  maxLines: 3,
  decoration: InputDecoration(
    labelText: 'Reason',
    hintText: 'Enter reason for leave',
    border: OutlineInputBorder(),
  ),
),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit button
                    CustomButton(
                      onPressed: _submitLeaveRequest,
                      text: 'Submit Leave Request',
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}