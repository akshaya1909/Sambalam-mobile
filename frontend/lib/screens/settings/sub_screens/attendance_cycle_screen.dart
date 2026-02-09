import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/company_settings_api_service.dart';

class AttendanceCycleScreen extends StatefulWidget {
  const AttendanceCycleScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceCycleScreen> createState() => _AttendanceCycleScreenState();
}

class _AttendanceCycleScreenState extends State<AttendanceCycleScreen> {
  final CompanySettingsApiService _api = CompanySettingsApiService();

  bool _isLoading = true;
  String? _companyId;

  // Default value matching your backend default
  String _currentCycle = '1-end';

  final Map<String, String> _cycleOptions = {
    '1-end': '1st to End of Month',
    '21-20': '21st to 20th of next month',
    '26-25': '26th to 25th of next month',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');

    if (_companyId != null) {
      try {
        final data = await _api.getCompanySettings(_companyId!);
        if (mounted) {
          setState(() {
            final settings = data['salarySettings'] ?? {};
            _currentCycle = settings['attendanceCycle'] ?? '1-end';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        _showSnack('Failed to load settings', isError: true);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCycleChange(String newValue) async {
    if (newValue == _currentCycle) return;

    // 1. Show Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Attendance Cycle?'),
        content: const Text(
          'Changing the attendance cycle will recalculate attendance and salary reports based on the new date range. Are you sure you want to proceed?',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(
                    color: Color(0xFF206C5E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Optimistic Update & API Call
    final String previousValue = _currentCycle;
    setState(() => _currentCycle = newValue);

    try {
      await _api.updateCompanySettings(
        companyId: _companyId!,
        payload: {
          'salarySettings': {'attendanceCycle': newValue}
        },
      );
      _showSnack('Attendance cycle updated successfully');
    } catch (e) {
      // Revert on error
      setState(() => _currentCycle = previousValue);
      _showSnack('Failed to update cycle', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF206C5E),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFF206C5E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Attendance Cycle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE), // Light Blue
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline,
                            color: Color(0xFF0284C7), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select the date range for your monthly attendance and salary calculations.',
                            style: TextStyle(
                              color: Color(0xFF0C4A6E),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Select Cycle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Options List
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: _cycleOptions.entries.map((entry) {
                        final isSelected = entry.key == _currentCycle;
                        return RadioListTile<String>(
                          value: entry.key,
                          groupValue: _currentCycle,
                          onChanged: (val) => _handleCycleChange(val!),
                          activeColor: primary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE6F5F1)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.date_range,
                              size: 20,
                              color: isSelected
                                  ? primary
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
