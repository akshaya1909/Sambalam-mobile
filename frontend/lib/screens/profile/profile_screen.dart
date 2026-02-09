import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- WIDGET IMPORTS (Ensure these exist in your project) ---
import '../../widgets/employee_bottom_nav.dart';
import '../home/employee_home_screen.dart';
import '../leave/leaves_screen.dart';
import '../attendance/attendance_screen.dart';
import '../../../api/company_api_service.dart';
import '../../../api/employee_api_service.dart';
import '../../../models/company_model.dart';
import '../admin/announcements_screen.dart';
import '../profile/employee_details_screen.dart';
import '../settings/more_settings_screen.dart';
import '../../../api/attendance_alarm_api_service.dart';
import '../../api/announcement_api_service.dart';
import '../../../services/notification_service.dart';
import 'package:sambalam/screens/notifications/employee_notifications_screen.dart'; // Adjust path as needed
import '../employee/employee_announcement_screen.dart';
import '../profile/holiday_list_screen.dart';
import '../employee/employee_documents_screen.dart';
import '../reimbursement/reimbursement_screen.dart';
import '../work_report/work_report_calendar_screen.dart';
import '../notes/notes_screen.dart';
import '../admin/crm_screen.dart';

// --- METHOD CHANNEL FOR ALARM ---
const _alarmChannel = MethodChannel('com.example.sambalam/alarm');

Future<void> openSystemAlarm({
  required int hour,
  required int minute,
  required String label,
}) async {
  if (!Platform.isAndroid) return;
  try {
    await _alarmChannel.invokeMethod('setSystemAlarm', {
      'hour': hour,
      'minute': minute,
      'message': label,
    });
  } on PlatformException catch (e) {
    debugPrint('Failed to open system alarm: $e');
  }
}

class ProfileScreen extends StatefulWidget {
  final String phoneNumber;
  final String companyId;
  final bool hideInternalNav;

  const ProfileScreen({
    Key? key,
    required this.phoneNumber,
    required this.companyId,
    this.hideInternalNav = false,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _employeeId;
  static const Color _primary = Color(0xFF206C5E);
  static const Color _bg = Color(0xFFF8FAFC); // Very light grey-blue background

  final CompanyApiService _companyApi = CompanyApiService();
  final EmployeeApiService _employeeApi = EmployeeApiService();
  final AnnouncementApiService _announcementApiService =
      AnnouncementApiService();

  Company? _company;
  String? _companyName;
  String? _companyLogoUrl;
  bool _isLoadingCompany = true;

  String? _employeeFullName;
  String? _jobTitle;
  bool _isLoadingEmployee = true;
  String _employmentStatus = 'active';
  bool _hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
    _loadEmployeeDetails();
  }

  Future<void> _loadCompanyDetails() async {
    try {
      // 1. Check if the widget ID is missing (common on refresh)
      String? effectiveId = widget.companyId;

      if (effectiveId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        effectiveId = prefs.getString('companyId');
      }

      if (effectiveId == null || effectiveId.isEmpty) {
        debugPrint("No Company ID found in widget or storage");
        return;
      }

      // 2. Fetch from API
      final company = await _companyApi.getCompanyById(effectiveId);

      if (!mounted) return;
      setState(() {
        _company = company;
        _companyName = _company?.name ?? 'Your company';
        _companyLogoUrl = _company?.logo;
        _isLoadingCompany = false;
      });
    } catch (e) {
      debugPrint('Error loading company: $e');
      if (!mounted) return;
      setState(() {
        _companyName = 'Error Loading Name'; // Changed for debugging
        _isLoadingCompany = false;
      });
    }
  }

  Future<void> _loadEmployeeDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use a small delay or ensure we wait for the instance
      final employeeId = prefs.getString('employeeId');
      final userId = prefs.getString('userId');
      final companyId = prefs.getString('companyId');

      if (employeeId == null || companyId == null) {
        debugPrint("Storage is empty! Redirecting to login...");
        // Handle session expiry here
        return;
      }

      // Now call the API only AFTER we have the IDs
      final data = await _employeeApi.getEmployeeBasicDetails(
        employeeId: employeeId,
        companyId: companyId,
      );
      // print("Employee Data: $data");

      int unreadCount = 0;
      if (userId != null) {
        unreadCount =
            await AnnouncementApiService.getUnreadCount(companyId, userId);
      }

      if (!mounted) return;
      setState(() {
        _employeeId = employeeId;
        _employeeFullName = data['fullName'];
        _employmentStatus = data['employmentStatus'] ?? 'active';
        _hasNewNotifications = unreadCount > 0;
        _isLoadingEmployee = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployee = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back,
        //       color: Colors.black), // Explicitly set to black
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
        title: Row(
          children: [
            if (_companyLogoUrl != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(_companyLogoUrl!),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            Expanded(
              child: Text(
                _companyName ?? '',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: _hasNewNotifications,
            backgroundColor: Colors.red,
            // Reduced offset to ensure it stays visible on the icon
            alignment: const AlignmentDirectional(20, -6),
            // You can also add a small digit if you prefer: label: Text(unreadCount.toString())
            label: null,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: Colors.black87),
              onPressed: () async {
                // Navigate and wait for user to return
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeNotificationsScreen(
                      companyId: widget.companyId,
                    ),
                  ),
                );
                // Re-check count when user comes back from notifications screen
                _loadEmployeeDetails();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MoreSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Section
            _buildProfileCard(),

            const SizedBox(height: 32),

            // 2. Primary Actions (Attendance & Leave)
            const Text(
              'Essentials',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildEssentialsRow(),

            const SizedBox(height: 32),

            // 3. Tools Grid (Apps)
            const Text(
              'Tools & Utilities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildToolsGrid(),

            const SizedBox(height: 32),

            // 4. Preferences List
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPreferencesList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: widget.hideInternalNav
          ? null
          : SafeArea(
              top: false,
              child: EmployeeBottomNav(
                selectedIndex: 2,
                activeColor: _primary,
                inactiveColor: Colors.grey,
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
                  } else if (index == 1) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LeavesScreen(
                          phoneNumber: widget.phoneNumber,
                          companyId: widget.companyId,
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 32, color: _primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeFullName ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Text(
                //   _jobTitle ?? 'Staff', // Default to 'Staff' if null
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Colors.white.withOpacity(0.9),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // Dynamic color based on status
                    color: _employmentStatus.toLowerCase() == 'active'
                        ? const Color(0xFF10B981) // Green
                        : const Color(0xFFEF4444), // Red
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    // Capitalize the first letter for display
                    _employmentStatus[0].toUpperCase() +
                        _employmentStatus.substring(1) +
                        " Employee",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final employeeId = prefs.getString('employeeId');
              if (employeeId == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmployeeDetailsScreen(employeeId: employeeId),
                ),
              );
            },
            icon: const Icon(Icons.edit_square, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialsRow() {
    return Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.fingerprint,
            color: const Color(0xFF3B82F6), // Blue
            title: 'Attendance',
            subtitle: 'View Logs',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    phoneNumber: widget.phoneNumber,
                    companyId: widget.companyId,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _FeatureCard(
            icon: Icons.beach_access,
            color: const Color(0xFFF59E0B), // Amber
            title: 'Apply Leave',
            subtitle: 'Request Off',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeavesScreen(
                    phoneNumber: widget.phoneNumber,
                    companyId: widget.companyId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolsGrid() {
    // List of tools
    final tools = [
      {
        'icon': Icons.campaign_outlined,
        'color': const Color(0xFF8B5CF6), // Purple
        'label': 'Announcements',
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const EmployeeAnnouncementScreen()),
            ),
      },
      {
        'icon': Icons.celebration_outlined,
        'color': const Color(0xFFEC4899), // Pink
        'label': 'Holiday List',
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HolidayListScreen(companyId: widget.companyId),
            ),
          );
        },
      },
      {
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFF10B981), // Green
        'label': 'Reimbursement',
        'isNew': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReimbursementScreen(
                employeeId: _employeeId!, // Pass current employee ID
                companyId: widget.companyId,
                employeeName: _employeeFullName ?? 'Employee',
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.description_outlined,
        'color': const Color(0xFF6366F1), // Indigo
        'label': 'Documents',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDocumentsScreen(
                employeeId:
                    _employeeId!, // Ensure you pass the correct employeeId here
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.note_alt_outlined,
        'color': const Color(0xFFF43F5E), // Rose
        'label': 'My Notes',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyNotesScreen()),
          );
        },
      },
      {
        'icon': Icons.assignment_outlined, // Icon for Work Report
        'color': const Color(0xFF059669), // Emerald Green
        'label': 'Work Report',
        'isNew': true,
        'onTap': () {
          // Navigates to the Work Report Calendar view
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkReportCalendarScreen(
                employeeId: _employeeId ?? '', // Pass the resolved ID
                companyId: widget.companyId, // Pass the company context
              ),
            ),
          );
        },
      },
      {
        'icon': Icons.handshake_outlined,
        'color': const Color(0xFF0EA5E9), // Sky
        'label': 'CRM',
        'isNew': true,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const CRMScreen(), // Ensure CrmScreen is imported
            ),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _ToolGridItem(
          icon: tool['icon'] as IconData,
          color: tool['color'] as Color,
          label: tool['label'] as String,
          isNew: tool['isNew'] == true,
          onTap: tool['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildPreferencesList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _ListTileItem(
            icon: Icons.access_alarm_rounded,
            color: const Color(0xFFF97316), // Orange
            title: 'Attendance Reminder',
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AlarmsListSheet(primaryColor: _primary),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _ListTileItem(
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFFEF4444), // Red
            title: 'Refer & Earn',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolGridItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isNew;
  final VoidCallback onTap;

  const _ToolGridItem({
    required this.icon,
    required this.color,
    required this.label,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 28, color: color),
                  if (isNew)
                    Positioned(
                      top: -2,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTileItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _ListTileItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
    );
  }
}

// --- ALARM SHEET ---

class AlarmsListSheet extends StatefulWidget {
  final Color primaryColor;

  const AlarmsListSheet({Key? key, required this.primaryColor})
      : super(key: key);

  @override
  State<AlarmsListSheet> createState() => _AlarmsListSheetState();
}

class _AlarmsListSheetState extends State<AlarmsListSheet> {
  Map<String, dynamic>? _punchInAlarm;
  Map<String, dynamic>? _punchOutAlarm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employeeId');
      if (employeeId == null) {
        setState(() => _loading = false);
        return;
      }

      final api = AttendanceAlarmApiService();
      final alarms = await api.getMobileAlarms(employeeId: employeeId);

      Map<String, dynamic>? inA;
      Map<String, dynamic>? outA;
      for (final a in alarms) {
        if (a['type'] == 'PunchIn') inA = a;
        if (a['type'] == 'PunchOut') outA = a;
      }

      if (!mounted) return;
      setState(() {
        _punchInAlarm = inA;
        _punchOutAlarm = outA;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatTime(Map<String, dynamic>? alarm) {
    if (alarm == null || alarm['enabled'] != true) return 'Not set';
    final h = (alarm['hour'] as num).toInt();
    final m = (alarm['minute'] as num).toInt();
    final t = TimeOfDay(hour: h, minute: m);
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hour12:$mm $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Attendance Alarms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set reminders to never miss a punch.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _AlarmOption(
            title: 'Punch In Reminder',
            time: _formatTime(_punchInAlarm),
            icon: Icons.wb_sunny_rounded,
            color: Colors.orange,
            onTap: () {
              _openTimePicker(context, widget.primaryColor, 'Punch In Alarm');
            },
          ),
          const SizedBox(height: 16),
          _AlarmOption(
            title: 'Punch Out Reminder',
            time: _formatTime(_punchOutAlarm),
            icon: Icons.nightlight_round,
            color: Colors.indigo,
            onTap: () {
              _openTimePicker(context, widget.primaryColor, 'Punch Out Alarm');
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openTimePicker(
      BuildContext context, Color primary, String title) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmPickerSheet(
        primaryColor: primary,
        title: title,
      ),
    );
  }
}

class _AlarmOption extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AlarmOption({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      color: time == 'Not set'
                          ? Colors.grey
                          : const Color(0xFF206C5E),
                      fontWeight: time == 'Not set'
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Reuse your existing AlarmPickerSheet class logic here or import it if separate
// I will include a placeholder for completeness to avoid errors
class AlarmPickerSheet extends StatefulWidget {
  final Color primaryColor;
  final String title;

  const AlarmPickerSheet(
      {Key? key, required this.primaryColor, required this.title})
      : super(key: key);

  @override
  State<AlarmPickerSheet> createState() => _AlarmPickerSheetState();
}

class _AlarmPickerSheetState extends State<AlarmPickerSheet> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(widget.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: TimePickerDialog(
                initialTime:
                    _selectedTime), // Use standard picker or your custom spinner
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor),
                onPressed: () async {
                  // --- SAVE ALARM LOGIC (Same as your previous snippet) ---
                  // ... (Implementation details for API call & NotificationService)
                  Navigator.pop(context);
                },
                child: const Text('Save Alarm'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
