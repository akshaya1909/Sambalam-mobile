import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/employee_api_service.dart';
import 'personal_details_screen.dart';
import 'current_employment_screen.dart';
import 'custom_details_screen.dart';
import 'attendance_settings_screen.dart';
import 'bank_details_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailsScreen({
    Key? key,
    required this.employeeId,
  }) : super(key: key);

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  final _api = EmployeeApiService();

  // Color Palette
  static const Color _primary = Color(0xFF206C5E);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textLight = Color(0xFF64748B);

  String fullName = '';
  String phoneNumber = '';
  String designation = '';
  String role = '';
  bool isLoading = true;
  bool hasError = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data =
          await _api.getEmployeeProfileById(employeeId: widget.employeeId);
      if (!mounted) return;
      setState(() {
        fullName = (data['fullName'] ?? '') as String;
        phoneNumber = (data['phoneNumber'] ?? '') as String;
        designation = (data['jobTitle'] ?? '') as String;
        role = (data['role'] ?? '') as String;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _handleDownload() async {
    setState(() => isDownloading = true);

    final path = await _api.downloadBiodataPdf(widget.employeeId, fullName);

    setState(() => isDownloading = false);

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download Complete")),
      );
      // Automatically open the PDF
      OpenFile.open(path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download Failed")),
      );
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: OutlinedButton.icon(
              onPressed: isDownloading ? null : _handleDownload,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: isDownloading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded, size: 15),
              label: Text(
                isDownloading ? 'Downloading...' : 'Biodata',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load profile'),
                      TextButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry',
                            style: TextStyle(color: _primary)),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildMenuGrid(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    String initial = 'U';
    if (fullName.trim().isNotEmpty) {
      initial = fullName.trim()[0].toUpperCase();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Camera Icon Badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.camera_alt, size: 16, color: _primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              designation.isNotEmpty ? designation : 'Employee',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            phoneNumber,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MenuSectionTitle(title: 'Basic Info'),
          _MenuTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal Details',
            subtitle: 'Name, DOB, Gender',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PersonalDetailsScreen(employeeId: widget.employeeId),
              ),
            ),
          ),
          _MenuTile(
            icon: Icons.work_outline_rounded,
            title: 'Current Employment',
            subtitle: 'Department, Branch, Date of Joining',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CurrentEmploymentScreen(employeeId: widget.employeeId),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MenuSectionTitle(title: 'Financials & Records'),
          _MenuTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank Details',
            subtitle: 'Account No, IFSC, Bank Name',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BankDetailsScreen(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.fingerprint_rounded,
            title: 'Attendance Details',
            subtitle: 'Shift timings, Punch logs',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AttendanceSettingsScreen(employeeId: widget.employeeId),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _MenuSectionTitle(title: 'Settings'),
          _MenuTile(
            icon: Icons.edit_note_rounded,
            title: 'Custom Details',
            subtitle: 'Additional company fields',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final cId = prefs.getString('companyId') ?? '';
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomDetailsScreen(
                    employeeId: widget.employeeId,
                    companyId: cId,
                  ),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'User Permission',
            subtitle: role.isNotEmpty ? 'Role: $role' : 'Manage access',
            onTap: () {
              // TODO: Implement Permissions
            },
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final String title;
  const _MenuSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Primary Color Reference
    const Color primary = Color(0xFF206C5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B), // Slate 800
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B), // Slate 500
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
