import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/company_settings_api_service.dart';
import 'manage_incentives_screen.dart';
import 'attendance_cycle_screen.dart';
import '../manage_salary_template_screen.dart';

class SalarySettingsScreen extends StatefulWidget {
  const SalarySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SalarySettingsScreen> createState() => _SalarySettingsScreenState();
}

class _SalarySettingsScreenState extends State<SalarySettingsScreen> {
  final CompanySettingsApiService _api = CompanySettingsApiService();

  bool _isLoading = true;
  String? _companyId;

  // --- FORM STATE ---
  // Default values
  String _salaryMonth = 'calendar';
  bool _roundOffSalary = false;

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
            // Safely access nested objects
            final settings = data['salarySettings'] ?? {};
            _salaryMonth = settings['monthCalculation'] ?? 'calendar';
            _roundOffSalary = settings['roundOff'] ?? false;
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

  // --- LOGIC: HANDLE PERIOD CHANGE ---
  Future<void> _onPeriodChanged(String newValue) async {
    if (newValue == _salaryMonth) return; // No change

    // 1. Show Confirmation Dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Change Period Type?'),
        content: const Text(
          'Changing the salary calculation method will affect how employee salaries are computed for this month. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 14, color: Colors.black87),
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

    // 2. Optimistic Update
    final String oldValue = _salaryMonth;
    setState(() => _salaryMonth = newValue);

    // 3. API Call
    try {
      await _api.updateCompanySettings(
        companyId: _companyId!,
        payload: {
          'salarySettings': {'monthCalculation': newValue}
        },
      );
      _showSnack('Salary period updated');
    } catch (e) {
      // Revert on failure
      setState(() => _salaryMonth = oldValue);
      _showSnack('Failed to update period type', isError: true);
    }
  }

  // --- LOGIC: HANDLE ROUND OFF TOGGLE ---
  Future<void> _onRoundOffChanged(bool newValue) async {
    // 1. Optimistic Update
    setState(() => _roundOffSalary = newValue);

    // 2. API Call
    try {
      await _api.updateCompanySettings(
        companyId: _companyId!,
        payload: {
          'salarySettings': {'roundOff': newValue}
        },
      );
      _showSnack('Settings saved');
    } catch (e) {
      // Revert on failure
      setState(() => _roundOffSalary = !newValue);
      _showSnack('Failed to update settings', isError: true);
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
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Salary Settings',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // --- SECTION 1: PERIOD TYPE ---
                  const Text(
                    'Select period type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Scroll for cards to be mobile responsive
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PeriodTypeCard(
                          title: 'Calendar Month',
                          subtitle: 'eg. Jan - 31 days\nFeb - 28 days',
                          value: 'calendar',
                          groupValue: _salaryMonth,
                          onChanged: _onPeriodChanged,
                        ),
                        const SizedBox(width: 12),
                        _PeriodTypeCard(
                          title: 'Fixed Days Month',
                          subtitle: '30 days month\nselected',
                          value: '30-day',
                          groupValue: _salaryMonth,
                          onChanged: _onPeriodChanged,
                        ),
                        const SizedBox(width: 12),
                        _PeriodTypeCard(
                          title: '26 Day Month',
                          subtitle: 'eg. Jan - 26 days\nFeb - 26 days',
                          value: '26-day',
                          groupValue: _salaryMonth,
                          onChanged: _onPeriodChanged,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: OTHER SETTINGS ---
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.calendar_today_outlined,
                          title: 'Attendance Cycle',
                          onTap: () {
                            // --- NAVIGATE HERE ---
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AttendanceCycleScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _SettingsTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Manage Salary (CTC Template)',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageSalaryTemplateScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _SettingsTile(
                          icon: Icons.monetization_on_outlined,
                          title: 'Manage Incentive Types',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ManageIncentivesScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        // Round Off Toggle Tile
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.money_off_csred_outlined,
                                color: Color(0xFF6B7280), size: 22),
                          ),
                          title: const Text(
                            'Round Off Total Salary',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          trailing: Switch(
                            value: _roundOffSalary,
                            activeColor: primary,
                            onChanged: _onRoundOffChanged,
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
}

// --- CUSTOM WIDGETS ---

class _PeriodTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _PeriodTypeCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;
    final Color borderColor =
        isSelected ? const Color(0xFF206C5E) : const Color(0xFFE5E7EB);
    final Color titleColor =
        isSelected ? const Color(0xFF206C5E) : const Color(0xFF111827);
    final Color bgColor = isSelected ? const Color(0xFFF0FDFA) : Colors.white;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150, // Fixed width for horizontal scrolling
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                    maxLines: 2,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 18, color: Color(0xFF206C5E))
                else
                  // Placeholder for alignment
                  const SizedBox(width: 18, height: 18),
              ],
            ),
            const Spacer(),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6B7280), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
    );
  }
}
