import 'package:flutter/material.dart';
import 'shifts_screen.dart';
import 'breaks_screen.dart';
import 'qr_codes_screen.dart';
import 'biometric_devices_screen.dart';
import 'attendance_kiosk_screen.dart';
import 'holiday_list_screen.dart';
import 'custom_paid_leave_screen.dart';
import '../../leave/leave_requests_admin_screen.dart';

class AttendanceSettingsScreen extends StatefulWidget {
  const AttendanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState extends State<AttendanceSettingsScreen> {
  // State for the Automation toggle
  bool _isAutoLiveTrackEnabled = false;
  bool _isFaceRecognitionEnabled = false;

  // --- SHOW UPGRADE DIALOG ---
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Activate Smart Face ID?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Prevent buddy punching and ensure 100% authentic attendance. Unlock advanced biometric security for your team today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Green
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Update state to ENABLED
                    setState(() {
                      _isFaceRecognitionEnabled = true;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Face Recognition Enabled!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB); // Matching Admin Settings BG
    const Color cardBg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Attendance Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: [
            // --- SECTION 1: SHIFTS & BREAKS ---
            _sectionLabel('Shifts & Breaks'),
            _settingsCard(
              children: [
                _AttendanceTile(
                  icon: Icons.access_time_filled_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'Shifts',
                  showNewBadge: true,
                  onTap: () {
                    // Navigate here
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShiftsScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.coffee_outlined,
                  color: const Color(0xFFA855F7), // Purple
                  title: 'Breaks',
                  showNewBadge: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BreaksScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionLabel('Attendance Modes'),
            _settingsCard(
              children: [
                _AttendanceTile(
                  icon: Icons.face_retouching_natural,
                  color: const Color(0xFFEF4444),
                  title: 'AI Face Recognition',
                  showNewBadge:
                      !_isFaceRecognitionEnabled, // Hide 'New' if enabled
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFaceRecognitionEnabled
                          ? const Color(0xFFD1FAE5) // Light Green if enabled
                          : const Color(0xFFE5E7EB), // Gray if disabled
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isFaceRecognitionEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isFaceRecognitionEnabled
                            ? const Color(0xFF059669) // Dark Green text
                            : const Color(0xFF4B5563), // Gray text
                      ),
                    ),
                  ),
                  onTap: () {
                    // Only show popup if it is currently disabled
                    if (!_isFaceRecognitionEnabled) {
                      _showUpgradeDialog();
                    }
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.qr_code_2,
                  color: const Color(0xFF10B981), // Green
                  title: 'QR Codes',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QrCodesScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.fingerprint,
                  color: const Color(0xFF3B82F6), // Blue
                  title: 'Biometric Devices',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BiometricDevicesScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFFF97316), // Orange
                  title: 'Attendance Kiosk',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AttendanceKioskScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.perm_device_information,
                  color: const Color(0xFF6366F1), // Indigo
                  title: 'Device Verification',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionLabel('Leaves & Holidays'),
            _settingsCard(
              children: [
                _AttendanceTile(
                  icon: Icons.event_note_outlined,
                  color: const Color(0xFFEC4899), // Pink
                  title: 'Leave Requests',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const LeaveRequestsAdminScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF14B8A6), // Teal
                  title: 'Holiday List',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HolidayListScreen()),
                    );
                  },
                ),
                _divider(),
                _AttendanceTile(
                  icon: Icons.event_available_outlined,
                  color: const Color(0xFF8B5CF6), // Violet
                  title: 'Custom Paid Leaves',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CustomPaidLeaveScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionLabel('Automation'),
            _settingsCard(
              children: [
                _AttendanceTile(
                  icon: Icons.location_on_outlined,
                  color: const Color(0xFF6B7280), // Gray
                  title: 'Auto-Live Track',
                  hideChevron: true, // Hide the arrow for toggle rows
                  trailing: Switch(
                    value: _isAutoLiveTrackEnabled,
                    activeColor: const Color(0xFF206C5E),
                    onChanged: (val) {
                      setState(() {
                        _isAutoLiveTrackEnabled = val;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _isAutoLiveTrackEnabled = !_isAutoLiveTrackEnabled;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827), // Darker text for headers inside body
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0, // Flat look to match admin settings
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFE5E7EB));
  }
}

// --- Custom Tile Widget matching the "Admin Settings" style but adapted ---
class _AttendanceTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool showNewBadge;
  final Widget? trailing;
  final bool hideChevron;
  final VoidCallback onTap;

  const _AttendanceTile({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    this.showNewBadge = false,
    this.trailing,
    this.hideChevron = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      // --- FIX: Use Flexible to prevent Overflow ---
      title: Row(
        mainAxisSize: MainAxisSize.min, // Keep content tight
        children: [
          Flexible(
            // Allows text to shrink if needed
            child: Text(
              title,
              overflow: TextOverflow.ellipsis, // Add dots if too long
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (showNewBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626), // Red
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'New',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          if (!hideChevron && trailing == null)
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          if (!hideChevron && trailing != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ]
        ],
      ),
    );
  }
}
