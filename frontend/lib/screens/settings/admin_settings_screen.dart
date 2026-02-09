import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'more_admin_settings_screen.dart';
import 'company_settings_screen.dart';
import '../settings/sub_screens/users_permissions_screen.dart';
import '../settings/sub_screens/attendance_settings_screen.dart';
import '../settings/sub_screens/salary_settings_screen.dart';
import '../settings/sub_screens/custom_fields_screen.dart';
import '../reports/company_reports_screen.dart';
import '../../../api/company_api_service.dart';
import '../admin/crm_screen.dart';
import '../help/help_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/sub_screens/verification_staff_list_screen.dart'; // Adjust path
import '../settings/work_report_list_screen.dart';
import '../settings/subscription_billing_screen.dart';
import '../subscription/upgrade_pro_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  final String? planExpiryBanner;
  final bool hideInternalNav;

  const AdminSettingsScreen({
    Key? key,
    this.planExpiryBanner,
    this.hideInternalNav = false,
  }) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // 1. Define your state variables
  final CompanyApiService _companyApi = CompanyApiService();
  Map<String, dynamic>? _planData;
  bool _isPlanExpired = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 2. Trigger the plan check immediately when screen loads
    _checkPlanStatus();
  }

  Future<void> _checkPlanStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');
      if (companyId == null) return;

      final data = await _companyApi.getCompanyPlan(companyId);
      if (data != null && mounted) {
        setState(() {
          _planData = data;

          // Expiry Logic: TotalAmount 0 (Free Plan) never expires
          final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
          final String? expiryStr = data['expiryDate'];

          if (totalAmount > 0 && expiryStr != null) {
            final DateTime expiry = DateTime.parse(expiryStr);
            _isPlanExpired = expiry.isBefore(DateTime.now());
          } else {
            _isPlanExpired = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Plan check error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF206C5E);
    const Color bg = Color(0xFFF4F6FB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        // foregroundColor: Colors.black, // Sometimes this gets overridden, so we force it below
        titleSpacing: 0,
        title: const Text(
          'Admin settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16, // Matches the Home Screen font size
          ),
        ),
        actions: [
          IconButton(
            // The bell icon matches the style from AdminHomeScreen
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[800]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('Help'),
            style: TextButton.styleFrom(
              foregroundColor: primary, // Color(0xFF206C5E)
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _headerCard(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sectionLabel('Organisation'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.apartment_outlined,
                        title: 'Company settings',
                        subtitle: 'Branches, branding, GST & more',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CompanySettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.group_outlined,
                        title: 'Users & permissions',
                        subtitle: 'Owners, admins and staff roles',
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UsersPermissionsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Attendance & payroll'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.check_box_outlined,
                        title: 'Attendance settings',
                        subtitle: 'Shifts, overtime, rules & geofence',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          // --- NAVIGATE HERE ---
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AttendanceSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.currency_rupee_outlined,
                        title: 'Salary settings',
                        subtitle: 'Components, payouts & policies',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          // Navigate here
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SalarySettingsScreen()),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.edit_note_outlined,
                        title: 'Custom fields',
                        subtitle: 'Capture additional employee data',
                        color: const Color(0xFFEC4899), // Pink
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const CustomFieldsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('Growth & tools'),
                  _settingsCard(
                    children: [
                      _SettingsTileNew(
                        icon: Icons.subscriptions_outlined,
                        title: 'Subscriptions & billing',
                        subtitle: 'Plan, invoices & payment history',
                        color: const Color(0xFF0EA5E9),
                        onTap: () {
                          // 1. Safety check: Ensure plan data is loaded before navigating
                          if (_planData != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                // 2. Pass the dynamic plan data to handle renewals or top-ups
                                builder: (_) =>
                                    UpgradeProScreen(activePlan: _planData!),
                              ),
                            );
                          } else {
                            // Optional: Show a snackbar if data is still fetching
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Loading subscription details...")));
                          }
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons
                            .assignment_outlined, // Professional report icon
                        title: 'Work report',
                        subtitle: 'Configure daily reporting & task fields',
                        color: const Color(
                            0xFF059669), // Professional Emerald green
                        onTap: () {
                          // Navigates to the Work Report Settings screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WorkReportListScreen(),
                            ),
                          );
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.badge_outlined,
                        title: 'Background verification',
                        subtitle: 'Screening & compliance checks',
                        color: const Color(0xFF8B5CF6),
                        onTap: () async {
                          // 1. Get SharedPreferences instance
                          final prefs = await SharedPreferences.getInstance();

                          // 2. Fetch values (Keys usually don't need the 'flutter.' prefix in Dart code)
                          final String companyId =
                              prefs.getString('companyId') ?? '';
                          final String adminId =
                              prefs.getString('adminId') ?? '';

                          // 3. Check if context is still valid before navigating
                          if (context.mounted) {
                            if (companyId.isEmpty || adminId.isEmpty) {
                              // Optional: Handle missing data
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Error: Missing Company or Admin ID")),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VerificationStaffListScreen(
                                  userId:
                                      adminId, // Passed from local storage 'adminId'
                                  companyId:
                                      companyId, // Passed from local storage 'companyId'
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _SettingsTileNew(
                        icon: Icons.bar_chart_outlined,
                        title: 'Reports',
                        subtitle: 'Download attendance & salary reports',
                        color: const Color(0xFF14B8A6), // Teal color
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CompanyReportsScreen(),
                            ),
                          );
                        },
                      ),
                      // _SettingsTileNew(
                      //   icon: Icons.extension_outlined,
                      //   title: 'Free tools',
                      //   subtitle: 'Calculators & templates',
                      //   color: const Color(0xFF6B7280),
                      //   onTap: () {},
                      // ),
                      _SettingsTileNew(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Refer & earn',
                        subtitle: 'Invite businesses and earn rewards',
                        color: const Color(0xFFEF4444),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Earn 10%',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () {},
                      ),
                      _SettingsTileNew(
                        icon: Icons.more_horiz,
                        title: 'More settings',
                        subtitle: 'Integrations & advanced options',
                        color: const Color(0xFF4B5563),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MoreAdminSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _secureBanner(),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'v 6.73',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.hideInternalNav
          ? null
          : BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.handshake_outlined), label: 'CRM'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined), label: 'Settings'),
              ],
              currentIndex: 2,
              onTap: (idx) {
                if (idx == 0) {
                  Navigator.of(context).pop();
                } else if (idx == 1) {
                  // NAVIGATE TO CRM
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CRMScreen()),
                  );
                }
              },
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
                Icons.settings_suggest_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage attendance, payroll and user controls from one place.',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _secureBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(
                Icons.security_outlined,
                color: Color(0xFF1D4ED8),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '100% secure',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Made with ❤ in India',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
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

class _SettingsTileNew extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTileNew({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
      onTap: onTap,
    );
  }
}
