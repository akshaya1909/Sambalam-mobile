import 'package:flutter/material.dart';
import '../../api/attendance_api_service.dart';
import '../../models/attendance_settings_model.dart';

class AttendanceSettingsScreen extends StatefulWidget {
  final String employeeId;

  const AttendanceSettingsScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  State<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState extends State<AttendanceSettingsScreen> {
  final AttendanceApiService _api = AttendanceApiService();
  static const Color _primary = Color(0xFF206C5E);
  static const Color _bg = Color(0xFFF5F7FA);

  bool _isLoading = true;
  AttendanceSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _api.getAttendanceSettings(widget.employeeId);
    if (mounted) {
      setState(() {
        _settings = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance Configurations',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _settings == null
              ? const Center(child: Text("No attendance configuration found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoBanner(),
                      const SizedBox(height: 20),
                      _buildWorkTimingsSection(),
                      const SizedBox(height: 20),
                      _buildAttendanceModesSection(),
                      const SizedBox(height: 20),
                      _buildAutomationRulesSection(),
                      const SizedBox(height: 20),
                      _buildPermissionsSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "These settings are managed by the admin. You can view the current configuration below.",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 1: WORK TIMINGS ---
  Widget _buildWorkTimingsSection() {
    final timings = _settings?.workTimings;
    final isFixed = timings?.scheduleType == "Fixed";

    return _ContentCard(
      title: "Work Timings",
      icon: Icons.access_time_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelValueRow(
            label: "Schedule Type",
            value: timings?.scheduleType ?? "Not Set",
            isHighlight: true,
          ),
          const Divider(height: 24),
          if (isFixed && timings?.fixed != null) ...[
            const Text(
              "Weekly Schedule",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...timings!.fixed!.days.map((day) => _buildDayRow(day)),
          ] else ...[
            const Text(
              "Flexible Schedule or Not Configured",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDayRow(FixedDay day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              day.day,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (day.isWeekoff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("Week Off",
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            )
          else
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day.selectedShift?.name ?? "Shift",
                      style:
                          TextStyle(fontSize: 12, color: Colors.teal.shade800),
                    ),
                    Text(
                      "${day.selectedShift?.startTime} - ${day.selectedShift?.endTime}",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- SECTION 2: ATTENDANCE MODES ---
  Widget _buildAttendanceModesSection() {
    final modes = _settings?.attendanceModes;
    final smart = modes?.smartphone;

    return _ContentCard(
      title: "Attendance Modes",
      icon: Icons.smartphone_rounded,
      child: Column(
        children: [
          _ModeToggleDisplay(
            label: "Smartphone App Access",
            isEnabled: modes?.enableSmartphone ?? false,
          ),
          if (modes?.enableSmartphone == true && smart != null) ...[
            const Divider(height: 20),
            _ModeToggleDisplay(
              label: "Selfie Attendance",
              isEnabled: smart.selfieAttendance,
              isSubItem: true,
            ),
            _ModeToggleDisplay(
              label: "QR Attendance",
              isEnabled: smart.qrAttendance,
              isSubItem: true,
            ),
            _ModeToggleDisplay(
              label: "GPS Tracking",
              isEnabled: smart.gpsAttendance,
              isSubItem: true,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text("Mark From",
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    smart.markAttendanceFrom,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primary),
                  ),
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  // --- SECTION 3: AUTOMATION RULES ---
  Widget _buildAutomationRulesSection() {
    final rules = _settings?.automationRules;

    return _ContentCard(
      title: "Automation Rules",
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          _ModeToggleDisplay(
            label: "Auto Present at Day Start",
            isEnabled: rules?.autoPresentAtDayStart ?? false,
          ),
          _ModeToggleDisplay(
            label: "Present on Punch In",
            isEnabled: rules?.presentOnPunchIn ?? true,
          ),
          const Divider(),
          _LabelValueRow(
            label: "Half Day if late by",
            value: rules?.autoHalfDayIfLateBy?.toString() ?? "Disabled",
          ),
          const SizedBox(height: 8),
          _LabelValueRow(
            label: "Min. Hrs for Half Day",
            value: rules?.mandatoryHalfDayHours?.toString() ?? "0h 0m",
          ),
          const SizedBox(height: 8),
          _LabelValueRow(
            label: "Min. Hrs for Full Day",
            value: rules?.mandatoryFullDayHours?.toString() ?? "0h 0m",
          ),
        ],
      ),
    );
  }

  // --- SECTION 4: PERMISSIONS ---
  Widget _buildPermissionsSection() {
    final viewOwn = _settings?.staffCanViewOwnAttendance ?? false;
    final leave = _settings?.leaveIntegration;

    return _ContentCard(
      title: "Permissions & Integrations",
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          _ModeToggleDisplay(
            label: "Staff can view own attendance",
            isEnabled: viewOwn,
          ),
          const Divider(),
          _ModeToggleDisplay(
            label: "Auto Deduct Leave on Absence",
            isEnabled: leave?.autoDeductLeave ?? false,
          ),
          _ModeToggleDisplay(
            label: "Notify on Low Attendance",
            isEnabled: leave?.notifyLowAttendance ?? true,
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE COMPONENTS ---

class _ContentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ContentCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF206C5E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF206C5E), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ModeToggleDisplay extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final bool isSubItem;

  const _ModeToggleDisplay({
    required this.label,
    required this.isEnabled,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: isSubItem ? 12 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSubItem ? Colors.grey.shade700 : Colors.black87,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                isEnabled ? "On" : "Off",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isEnabled ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isEnabled ? Colors.green : Colors.grey.shade400,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _LabelValueRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? const Color(0xFF206C5E) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
