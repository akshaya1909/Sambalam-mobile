import 'dart:io'; // Required for File
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/staff_model.dart';
import '../../../models/branch_model.dart';
import '../../../models/company_user.dart';
import 'personal_details_screen.dart';
import 'employment_details_screen.dart';
import 'custom_details_screen.dart';
import 'salary_details_screen.dart';
import 'bank_details_screen.dart';
import 'penalty_and_overtime_screen.dart';
import 'leave_balance_and_policy_screen.dart';
import 'additional_settings_screen.dart';
import '../settings/sub_screens/background_verification_screen.dart';
import '../admin/crm_screen.dart';
import '../../api/company_settings_api_service.dart';
import '../../api/bank_api_service.dart';
import '../../api/branch_api_service.dart';
import '../../api/company_api_service.dart';
import '../../api/employee_api_service.dart';

class EditStaffScreen extends StatefulWidget {
  final Staff staff;

  const EditStaffScreen({Key? key, required this.staff}) : super(key: key);

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final CompanySettingsApiService _api = CompanySettingsApiService();
  final BankApiService _bankApi = BankApiService();
  final EmployeeApiService _employeeApi = EmployeeApiService();
  final BranchApiService _branchApi = BranchApiService();

  bool _savedDetailsVerified = false; // Define the missing variable
  bool _isCheckingVerification = true;
  String _employmentStatus = "active";

  String _currentRole = "Employee";
  String? _associatedUserId;
  bool _isLoadingRole = true;
  late Staff _currentStaff; // Track the latest staff data locally
  bool _isPageLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;
  List<Branch> _companyBranches = [];
  CompanyUser? _specificUserData;
  bool _pushNotificationsEnabled = false;

  // Theme colors matching Admin Home Screen
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _currentStaff = widget.staff;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Run everything in parallel
    await Future.wait([
      _fetchEmployeeDetails(), // Fetch fresh DB data
      _checkVerificationStatus(),
      _fetchUserRole(),
    ]);
    if (mounted) setState(() => _isPageLoading = false);
  }

  Future<void> _fetchEmployeeDetails() async {
    try {
      // You need a method in EmployeeApiService that returns a Staff object by ID
      final freshStaff = await _employeeApi.getEmployeeById(widget.staff.id);
      if (mounted && freshStaff != null) {
        setState(() {
          _currentStaff = freshStaff;
          _employmentStatus = freshStaff.employmentStatus ?? "active";
        });
      }
    } catch (e) {
      debugPrint("Error fetching fresh staff data: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Compress to save bandwidth
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploading = true;
        });

        // TODO: Call your API to upload the image
        // Example:
        // bool success = await _employeeApi.uploadProfilePic(widget.staff.id, _imageFile!);

        setState(() => _isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully")),
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      setState(() => _isUploading = false);
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      // Fetch the list but only keep this specific user's data
      final users = await _employeeApi.getCompanyUsers(companyId);
      final currentUser =
          users.firstWhere((u) => u.phone == widget.staff.phone);

      setState(() {
        _specificUserData = currentUser;
        _associatedUserId = currentUser.id;
        _currentRole =
            currentUser.role; // This is the role string (e.g., 'employee')
        _pushNotificationsEnabled = currentUser.hasFcmToken ?? false;
        _isLoadingRole = false;
      });
    } catch (e) {
      debugPrint("Error fetching role: $e");
      setState(() => _isLoadingRole = false);
    }
  }

  void _shareInviteMessage() {
    const String appUrl = "https://sambalam.ifoxclicks.com/app.apk";
    const String tutorialUrl = "https://www.youtube.com/shorts/01-Qy7tkDv0";

    final String message = "Hi,\n"
        "Download the Sambalam App and mark your attendance. Click on this link 👇👇👇\n\n"
        "$appUrl\n\n"
        "How to Use App: $tutorialUrl";

    Share.share(
      message,
      subject: 'Join Sambalam Attendance System',
    );
  }

  Future<void> _handleStatusToggle() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final newStatus =
          await _employeeApi.toggleEmployeeStatus(widget.staff.id);

      if (mounted) {
        Navigator.pop(context); // Close loading
        if (newStatus != null) {
          setState(() {
            _employmentStatus = newStatus;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Employee marked as $newStatus")),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to update status"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final bankDetails = await _bankApi.getBankDetails(widget.staff.id);
      if (mounted) {
        setState(() {
          // Logic: ONLY true if BOTH are verified
          _savedDetailsVerified = (bankDetails?.isAccnVerified ?? false) &&
              (bankDetails?.isUpiVerified ?? false);
          _isCheckingVerification = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingVerification = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch phone dialer")),
      );
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any non-numeric characters (like spaces or +)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // WhatsApp URL scheme
    final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$cleanPhone");
    // Fallback SMS URI
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        // WhatsApp not installed, open native SMS messenger
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          throw 'Could not launch messaging apps';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open messaging apps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // Elegant Gradient Header
          SliverAppBar(
            expandedHeight: 230.0,
            floating: false,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.staff.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryDeepTeal, secondaryTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: _buildAvatarContent(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage, // Tapping icon opens gallery
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.camera_alt,
                                  size: 14, color: primaryDeepTeal),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ID: ${widget.staff.employeeId}",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                children: [
                  _buildQuickActionGrid(),
                  const SizedBox(height: 24),
                  _buildDetailSection("Core Information", [
                    _buildMenuTile(
                      Icons.person_outline,
                      "Personal Details",
                      "DOB, Marital Status, Address",
                      () async {
                        try {
                          // 1. Show a loading dialog so user knows something is happening
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          // 2. Get the real User ID from the phone number
                          final String userId =
                              await _api.getUserIdFromPhone(widget.staff.phone);

                          // 3. Close loading dialog
                          if (mounted) Navigator.pop(context);

                          // 4. Navigate using the retrieved userId
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PersonalDetailsScreen(
                                  employeeUserId:
                                      userId, // Now passing the real userId from DB
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) Navigator.pop(context); // Close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error: ${e.toString()}"),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                    _buildMenuTile(Icons.work_outline, "Current Employment",
                        "Job Title, Joining Date, ID", () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        final String userId =
                            await _api.getUserIdFromPhone(widget.staff.phone);
                        if (mounted) Navigator.pop(context); // Close loading

                        if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EmploymentDetailsScreen(
                                employeeUserId: userId,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) Navigator.pop(context); // Close loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              backgroundColor: Colors.red),
                        );
                      }
                    }),
                    _buildMenuTile(Icons.account_tree_outlined,
                        "Custom Details", "New Fields", () async {
                      try {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ));
                        final String userId =
                            await _api.getUserIdFromPhone(widget.staff.phone);
                        if (mounted)
                          Navigator.pop(context); // Close loading dialog

                        if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomDetailsScreen(employeeUserId: userId),
                            ),
                          );
                          // Removed .then((_) => _loadData()) because _loadData is not in this class
                        }
                      } catch (e) {
                        if (mounted)
                          Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              backgroundColor: Colors.red),
                        );
                      }
                    }, isNew: true),
                    _buildMenuTile(
                        Icons.verified_user_outlined,
                        "Background Verification",
                        "Identity & Records", () async {
                      try {
                        // 1. Show a loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        // 2. Get companyId from local storage
                        final prefs = await SharedPreferences.getInstance();
                        final String companyId =
                            prefs.getString('companyId') ?? "";

                        // 3. Close the loading indicator
                        if (mounted) Navigator.pop(context);

                        // 4. Navigate with the retrieved companyId
                        if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  BackgroundVerificationScreen(
                                userId:
                                    widget.staff.id, // Current Admin/User ID
                                employeeId:
                                    widget.staff.id, // Target employee ID
                                companyId:
                                    companyId, // Now passing from local storage
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              backgroundColor: Colors.red),
                        );
                      }
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection("Finance & Compliance", [
                    _buildMenuTile(Icons.currency_rupee, "Salary Details",
                        "Structure, Allowances, Bonus", () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SalaryDetailsScreen(
                            employeeId: widget.staff.id,
                            staffName: widget.staff.name,
                          ),
                        ),
                      );
                    }),
                    _buildMenuTile(
                      Icons.account_balance_outlined,
                      "Bank Details",
                      _isCheckingVerification
                          ? "Checking..."
                          : (_savedDetailsVerified
                              ? "Verified"
                              : "Not Verified"),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  BankDetailsScreen(staff: widget.staff)),
                        ).then((_) =>
                            _checkVerificationStatus()); // Refresh status when coming back
                      },
                      statusColor: _isCheckingVerification
                          ? Colors.grey
                          : (_savedDetailsVerified ? Colors.green : Colors.red),
                    ),
                    _buildMenuTile(Icons.security, "User Permission",
                        _isLoadingRole ? "Loading..." : _currentRole, () {
                      if (_associatedUserId != null) {
                        _showPermissionSheet(context);
                      }
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection("Policies", [
                    _buildMenuTile(
                      Icons.timer_outlined,
                      "Penalty & Overtime",
                      "Rate & Calculation",
                      () {
                        // Add the navigation logic here
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PenaltyAndOvertimeScreen(
                              employeeId: widget.staff.id,
                              employeeName: widget.staff.name,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildMenuTile(
                      Icons.calendar_today_outlined,
                      "Leave Balance & Policy",
                      "Annual, Sick leaves",
                      () {
                        // Navigate to the Leave Balances & Policy screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LeaveBalancesAndPolicyScreen(
                              employeeId: widget.staff.id, // Pass unique DB ID
                              employeeName: widget
                                  .staff.name, // Pass staff name for the header
                            ),
                          ),
                        );
                      },
                    ),
                    _buildMenuTile(Icons.description_outlined, "Documents",
                        "ID Proofs, Contracts", () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildDetailSection("Advanced Settings", [
                    _buildSwitchTile(
                      Icons.notifications_none,
                      "Push Notifications",
                      _pushNotificationsEnabled,
                      (bool newValue) {
                        if (!_pushNotificationsEnabled && newValue) {
                          // User tried to turn it on, but no token exists
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Cannot enable: User has not logged into the mobile app yet."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          // Logic to update preference in DB could go here
                          setState(() => _pushNotificationsEnabled = newValue);
                        }
                      },
                    ),
                    _buildMenuTile(Icons.vpn_key_outlined, "Generate Login OTP",
                        "Reset mobile access", () {}),
                    _buildMenuTile(
                      Icons.settings_outlined,
                      "Additional Settings",
                      "Timezone, Language",
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AdditionalSettingsScreen(
                              employeeName: widget.staff.name,
                              employeeId: widget.staff.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildDangerZone(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to determine what to show in the Avatar
  Widget _buildAvatarContent() {
    if (_isUploading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child:
            Image.file(_imageFile!, width: 80, height: 80, fit: BoxFit.cover),
      );
    }

    // if (_currentStaff.profilePic != null &&
    //     _currentStaff.profilePic!.isNotEmpty) {
    //   return ClipRRect(
    //     borderRadius: BorderRadius.circular(40),
    //     child: Image.network(
    //       _currentStaff.profilePic!,
    //       width: 80,
    //       height: 80,
    //       fit: BoxFit.cover,
    //       errorBuilder: (context, error, stackTrace) => _buildInitials(),
    //     ),
    //   );
    // }

    return _buildInitials();
  }

  Widget _buildInitials() {
    return Text(
      widget.staff.name[0].toUpperCase(),
      style: const TextStyle(fontSize: 32, color: Colors.white),
    );
  }

  Widget _buildQuickActionGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(Icons.call, "Call", Colors.blue, () {
          _makePhoneCall(widget.staff.phone); // Triggers the call
        }),
        _quickAction(Icons.message, "Text", Colors.green, () {
          _openWhatsApp(
              widget.staff.phone); // Opens WhatsApp or falls back to SMS
        }),
        _quickAction(Icons.share, "Invite", Colors.orange, () {
          _shareInviteMessage(); // Triggers the share sheet
        }),
        _quickAction(Icons.location_on, "Location", Colors.purple, () {}),
        _quickAction(
          Icons.handshake,
          "CRM",
          Colors.teal,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CRMScreen(), // Ensure CrmScreen is imported
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          // Wrap with GestureDetector or InkWell
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
      IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool isNew = false, Color? statusColor}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: scaffoldBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: primaryDeepTeal),
      ),
      title: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          if (isNew) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: const Text("NEW",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 12, color: statusColor ?? Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile(
      IconData icon, String title, bool value, Function(bool)? onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: scaffoldBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: primaryDeepTeal),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: secondaryTeal,
      ),
    );
  }

  Widget _buildDangerZone() {
    bool isActive = _employmentStatus == "active";
    return Column(
      children: [
        OutlinedButton(
          onPressed: _handleStatusToggle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            // ✅ Toggle border color: Orange if currently active, Green if currently inactive
            side: BorderSide(
              color: isActive ? Colors.orange : Colors.green,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isActive ? "MARK INACTIVE" : "MAKE ACTIVE",
            style: TextStyle(
              // Toggle font color between orange and green
              color: isActive ? Colors.orange : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("DELETE STAFF",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showPermissionSheet(BuildContext context) async {
    if (_specificUserData == null) return;

    String selectedRole = _currentRole.toLowerCase();
    List<String> selectedBranchIds =
        List.from(_specificUserData!.assignedBranches);

    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId') ?? "";

    // Fetch branches if not loaded
    if (_companyBranches.isEmpty) {
      _companyBranches = await _branchApi.getCompanyBranches(companyId);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Permission",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildRoleOption("Employee", "employee", selectedRole,
                        (val) => setModalState(() => selectedRole = val!)),
                    _buildRoleOption(
                        "Attendance Manager",
                        "attendance manager",
                        selectedRole,
                        (val) => setModalState(() => selectedRole = val!)),
                    _buildRoleOption(
                        "Advanced Attendance Manager",
                        "advanced attendance manager",
                        selectedRole,
                        (val) => setModalState(() => selectedRole = val!)),
                    _buildRoleOption(
                        "Branch Admin",
                        "branch admin",
                        selectedRole,
                        (val) => setModalState(() => selectedRole = val!)),

                    // Branch selection for Branch Admin
                    if (selectedRole == 'branch admin') ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("Assign Branches *",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey)),
                      ),
                      ..._companyBranches
                          .map((branch) => CheckboxListTile(
                                title: Text(branch.name,
                                    style: const TextStyle(fontSize: 13)),
                                value: selectedBranchIds.contains(branch.id),
                                activeColor: Colors.green,
                                dense: true,
                                onChanged: (bool? checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      selectedBranchIds.add(branch.id);
                                    } else {
                                      selectedBranchIds.remove(branch.id);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ],

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [primaryDeepTeal, secondaryTeal]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedRole == 'branch admin' &&
                              selectedBranchIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please select at least one branch")));
                            return;
                          }

                          try {
                            // Call the service with oldRole for proper replacement
                            await _employeeApi.updateUserRole(
                              companyId: companyId,
                              userId: _associatedUserId!,
                              oldRole:
                                  _currentRole, // The role before modification
                              newRole: selectedRole,
                              branchIds: selectedBranchIds,
                            );

                            setState(() => _currentRole = selectedRole);
                            // Refresh user data so assignedBranches are updated locally
                            await _fetchUserRole();

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Permission updated successfully"),
                                      backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Update Permission",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Updated helper
  Widget _buildRoleOption(String title, String value, String groupVal,
      Function(String?) onChanged) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupVal,
      onChanged: onChanged,
      activeColor: secondaryTeal,
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
