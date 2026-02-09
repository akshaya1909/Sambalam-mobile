import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../widgets/company_avatar.dart';
import '../../../widgets/staff_detail_screen.dart';
import '../../../widgets/expired_plan_overlay.dart';
import '../../../api/company_api_service.dart';
import '../../../models/company_model.dart';
import '../../../models/staff_model.dart';
import '../../../models/branch_model.dart';
import '../admin/pending_requests_screen.dart';
import '../admin/announcements_screen.dart';
import '../attendance/daily_attendance_screen.dart';
import '../settings/admin_settings_screen.dart';
import '../attendance/attendance_screen.dart';
import '../reports/company_reports_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/sub_screens/branches_screen.dart';
import '../../api/leave_api_service.dart';
import '../../api/api_service.dart';
import '../../models/leave_request_item.dart';
import '../../api/reimbursement_api_service.dart';
import '../../api/admin_api_service.dart';
import '../../api/branch_api_service.dart';
import '../../models/reimbursement_request_item.dart';
import '../leave/leave_request_detail_screen.dart'; // Ensure this exists or use modal logic
import '../admin/crm_screen.dart';
import '../help/help_screen.dart';
import '../employee/add_staff_screen.dart';
import '../subscription/upgrade_pro_screen.dart';

// enum AttendanceFilter { inStaff, outStaff, noPunchIn, all }

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback onAddStaff;
  final VoidCallback onInviteStaff;
  final VoidCallback onReports;
  final VoidCallback onEditAttendance;
  final VoidCallback onHelp;
  final String? planExpiryBanner;
  final String phoneNumber;
  final bool hideInternalNav;
  final String role; // Add this
  final List<String>? allowedBranchIds;

  const AdminHomeScreen({
    Key? key,
    required this.onAddStaff,
    required this.onInviteStaff,
    required this.onReports,
    required this.onEditAttendance,
    required this.onHelp,
    this.planExpiryBanner,
    required this.phoneNumber,
    this.hideInternalNav = false,
    required this.role,
    this.allowedBranchIds,
  }) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final CompanyApiService _companyApi = CompanyApiService();
  final LeaveApiService _leaveApi = LeaveApiService();
  final ReimbursementApiService _reimbursementApi = ReimbursementApiService();
  final AdminApiService _adminApi = AdminApiService();

  Company? _company;
  bool _isLoadingCompany = true;

  int _inCount = 0;
  int _outCount = 0;
  int _noPunchInCount = 0;
  int _totalStaff = 0;
  bool _isLoadingStats = true;
  int _totalPendingCount = 0;
  bool _isLoadingPendingCount = true;

  List<Staff> _staffList = [];
  bool _isLoadingStaff = true;
  List<Staff> _filteredStaffList = []; // This will hold the search results
  List<Branch> _branches = [];
  Branch? _selectedBranch; // null represents "All Branches"
  final BranchApiService _branchApi = BranchApiService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _planData;
  bool _isPlanExpired = false;

  static final Branch allBranchesSelection = Branch(
      id: 'ALL',
      name: 'All Branches',
      address: '',
      radius: 0,
      latitude: 0,
      longitude: 0);

  @override
  void initState() {
    super.initState();
    _initializeDefaultBranch();
    _loadCompanyDetails();
    _loadBranchDetails();
    _loadAttendanceStats();
    _loadStaffList();
    _loadAllPendingCounts();
    _checkPlanStatus();
  }

  void _initializeDefaultBranch() {
    // If user is a Branch Admin and has exactly one assigned branch
    if (widget.role.toLowerCase() == 'branch admin' &&
        widget.allowedBranchIds != null &&
        widget.allowedBranchIds!.length == 1) {
      // We create a temporary Branch object with just the ID
      // so the subsequent API calls (Stats & Staff) use the correct filter immediately.
      _selectedBranch = Branch(
          id: widget.allowedBranchIds!.first,
          name:
              'Loading...', // Temporary name until _loadBranchDetails finishes
          address: '',
          radius: 0,
          latitude: 0,
          longitude: 0);
    } else {
      // Ensure it is null for Super Admins
      _selectedBranch = null;
    }
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

          // Expiry Logic: TotalAmount 0 (Free Plan) never expires.
          // Otherwise, check if current date is past expiryDate.
          final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
          final String? expiryStr = data['expiryDate'];

          if (totalAmount > 0 && expiryStr != null) {
            final DateTime expiry = DateTime.parse(expiryStr);
            _isPlanExpired = expiry.isBefore(DateTime.now());
          } else {
            _isPlanExpired = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Plan check error: $e");
    }
  }

  Future<void> _loadCompanyDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final company = await _companyApi.getCompanyById(companyId);
        if (!mounted) return;
        setState(() {
          _company = company;
          _isLoadingCompany = false;
        });
      } else {
        setState(() {
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading company: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingCompany = false;
      });
    }
  }

  void _navigateToBranches({bool openAddForm = false}) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => const BranchesScreen()),
    )
        .then((_) {
      // Refresh branches in dropdown when returning
      _loadBranchDetails();
    });

    // If you want to automatically open the form upon navigation,
    // you would usually pass a parameter to BranchesScreen.
  }

  Future<void> _loadBranchDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        List<Branch> branches = await _branchApi.getCompanyBranches(companyId);

        // --- NEW FILTERING LOGIC ---
        if (widget.role.toLowerCase() == 'branch admin' &&
            widget.allowedBranchIds != null) {
          // Filter list to only include branches the user is assigned to
          branches = branches
              .where((b) => widget.allowedBranchIds!.contains(b.id))
              .toList();
        }

        if (!mounted) return;
        setState(() {
          _branches = branches;

          // If there's only one branch, select it automatically and disable "All Branches"
          if (widget.role.toLowerCase() == 'branch admin' &&
              _branches.length == 1) {
            _selectedBranch = _branches.first;
          } else if (widget.role.toLowerCase() == 'admin') {
            _selectedBranch = null; // Forces "All Branches"
          }
          _isLoadingCompany = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
      if (mounted) setState(() => _isLoadingCompany = false);
    }
  }

  Future<void> _loadAllPendingCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        // Fetch all pending lists in parallel
        final results = await Future.wait([
          _leaveApi.getPendingLeaveRequests(companyId: companyId),
          _reimbursementApi.getPendingReimbursements(companyId),
          _adminApi.getPendingDeviceRequests(companyId),
        ]);

        final leaveCount = (results[0] as List).length;
        final reimbursementCount = (results[1] as List).length;
        final deviceCount = (results[2] as List).length;

        if (!mounted) return;
        setState(() {
          _totalPendingCount = leaveCount + reimbursementCount + deviceCount;
          _isLoadingPendingCount = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading counts: $e');
      if (mounted) setState(() => _isLoadingPendingCount = false);
    }
  }

  void _shareInviteMessage() {
    const String appUrl = "https://sambalam.ifoxclicks.com/app.apk";
    const String tutorialUrl =
        "https://www.youtube.com/shorts/01-Qy7tkDv0"; // Your tutorial link

    final String message = "Hi,\n"
        "Download the Sambalam App and mark your attendance. Click on this link 👇👇👇\n\n"
        "$appUrl\n\n"
        "How to Use App: $tutorialUrl";

    Share.share(
      message,
      subject: 'Join Sambalam Attendance System',
    );
  }

  Future<void> _loadAttendanceStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final stats = await _companyApi.getCompanyAttendanceStats(
          companyId: companyId,
          branchId: _selectedBranch?.id,
        );
        if (!mounted) return;
        setState(() {
          _inCount = stats['inCount'] ?? 0;
          _outCount = stats['outCount'] ?? 0;
          _noPunchInCount = stats['noPunchInCount'] ?? 0;
          _totalStaff = stats['totalStaff'] ?? 0;
          _isLoadingStats = false;
        });
      } else {
        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadStaffList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final staffList = await _companyApi.getCompanyStaffList(
          companyId: companyId,
          branchId: _selectedBranch?.id,
        );
        if (!mounted) return;
        setState(() {
          _staffList = staffList;
          _filteredStaffList = staffList;
          _isLoadingStaff = false;
        });
      } else {
        setState(() {
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading staff: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingStaff = false;
      });
    }
  }

  void _runFilter(String enteredKeyword) {
    List<Staff> results = [];
    if (enteredKeyword.isEmpty) {
      // if the search field is empty, display all users
      results = _staffList;
    } else {
      results = _staffList
          .where((staff) =>
              staff.name.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              staff.phone.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredStaffList = results;
    });
  }

  void _openDailyAttendance(AttendanceFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getString('companyId');
    if (companyId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyAttendanceScreen(
          initialFilter: filter,
          companyId: companyId,
          branchId: _selectedBranch?.id, // Pass the ID (null if All Branches)
          branchName: _selectedBranch?.name ?? "All Branches",
        ),
      ),
    );
  }

  void _navigateToAddStaff() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddStaffScreen()),
    );

    // If the screen returns true, refresh the staff list and stats
    if (result == true) {
      _loadStaffList();
      _loadAttendanceStats();
    }
  }

  String _shortCompanyName(String? name) {
    if (name == null || name.trim().isEmpty) return 'All Branches';
    final words = name.trim().split(' ');
    final firstWord = words.first;
    if (firstWord.length <= 16) return firstWord;
    return '${firstWord.substring(0, 13)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = const Color(0xFF206C5E); // deep teal
    final Color surface = Colors.white;
    final Color bg = const Color(0xFFF4F6FB);
    final bool isBranchAdmin = widget.role.toLowerCase() == 'branch admin';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surface,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            _isLoadingCompany
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : !_isLoadingCompany
                    ? PopupMenuButton<Branch?>(
                        // Branch? allows null to represent the "All Branches" selection
                        offset: const Offset(10, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (Branch? selected) {
                          if (selected?.id == 'ADD_NEW_BRANCH') {
                            _navigateToBranches(openAddForm: true);
                          } else {
                            setState(() {
                              // If the ID is 'ALL', we treat it as null for the API calls
                              if (selected?.id == 'ALL') {
                                _selectedBranch = null;
                              } else {
                                _selectedBranch = selected;
                              }

                              // Trigger loaders
                              _isLoadingStaff = true;
                              _isLoadingStats = true;
                            });

                            // These calls will now use _selectedBranch (which is null for "All")
                            _loadAttendanceStats();
                            _loadStaffList();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            // --- "All Branches" Option ---
                            if (!isBranchAdmin || _branches.length > 1)
                              PopupMenuItem<Branch?>(
                                value: allBranchesSelection,
                                child: Row(
                                  children: [
                                    // const Icon(Icons.account_tree_outlined,
                                    //     size: 22, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    const Text("All Branches",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    if (_selectedBranch == null ||
                                        _selectedBranch?.id == 'ALL')
                                      Icon(Icons.check_circle,
                                          color: primary, size: 16),
                                  ],
                                ),
                              ),
                            // const PopupMenuDivider(),
                            // --- Individual Branch Options ---
                            ..._branches.map((Branch branch) {
                              return PopupMenuItem<Branch?>(
                                value: branch,
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 22, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Text(branch.name),
                                    const Spacer(),
                                    if (_selectedBranch?.id == branch.id)
                                      Icon(Icons.check_circle,
                                          color: primary, size: 16),
                                  ],
                                ),
                              );
                            }),
                            // const PopupMenuDivider(),
                            // --- ADD NEW BRANCH BUTTON ---
                            if (!isBranchAdmin)
                              PopupMenuItem<Branch?>(
                                value: Branch(
                                    id: 'ADD_NEW_BRANCH',
                                    name: 'Add New',
                                    address: '',
                                    radius: 0,
                                    latitude: 0,
                                    longitude: 0),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline,
                                        size: 22, color: primary),
                                    const SizedBox(width: 12),
                                    Text("Add New Branch",
                                        style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ];
                        },
                        enabled: _branches.length > 1 || !isBranchAdmin,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Show Company Logo / Avatar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _company?.logo != null
                                    ? Image.network(
                                        // FIX: Prepend the base URL to the relative path
                                        _company!.logo!.startsWith('http')
                                            ? _company!.logo!
                                            : '${CompanyApiService.baseUrl}${_company!.logo!}',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                CompanyAvatar(
                                                    name: _company?.name ?? 'C',
                                                    size: 36),
                                      )
                                    : CompanyAvatar(
                                        name: _company?.name ?? 'C', size: 36),
                              ),
                              const SizedBox(width: 12),
                              // 2. Text Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        // IF _selectedBranch is null, show Company Name, ELSE show Branch Name
                                        _selectedBranch?.name ?? "All Branches",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    // Subtitle logic
                                    _selectedBranch == null
                                        ? (isBranchAdmin
                                            ? 'Branch admin dashboard'
                                            : 'Admin dashboard')
                                        : (_company?.name ??
                                            (isBranchAdmin
                                                ? 'Branch admin dashboard'
                                                : 'Admin dashboard')),
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 168, 168, 168),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        // Fallback if no branches are found
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            CompanyAvatar(name: _company?.name ?? '', size: 36),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _company?.name ?? 'Company',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  isBranchAdmin
                                      ? 'Branch admin dashboard'
                                      : 'Admin dashboard',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ],
        ),
        actions: [
          IconButton(
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
            style: TextButton.styleFrom(foregroundColor: primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // if (widget.planExpiryBanner != null)
          //   Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          //     color: Colors.orange[700],
          //     child: Text(
          //       widget.planExpiryBanner!,
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 13,
          //         fontWeight: FontWeight.w500,
          //       ),
          //       textAlign: TextAlign.center,
          //     ),
          //   ),
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadCompanyDetails();
                    await _loadBranchDetails();
                    await _loadAttendanceStats();
                    await _loadStaffList();
                    await _loadAllPendingCounts();
                    await _checkPlanStatus();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting / date row
                        Text(
                          'Today\'s overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track attendance and manage your team in one place.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Attendance summary card
                        _buildAttendanceSummaryCard(primary),

                        const SizedBox(height: 18),

                        // Quick actions grid
                        Text(
                          'Quick actions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildQuickActionsGrid(primary),

                        const SizedBox(height: 20),

                        // Staff header with "Add staff" button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Staff overview',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                            // TextButton.icon(
                            //   onPressed: widget.onAddStaff,
                            //   icon: const Icon(Icons.person_add_alt_1, size: 18),
                            //   label: const Text('Add staff'),
                            //   style: TextButton.styleFrom(
                            //     foregroundColor: primary,
                            //     padding: const EdgeInsets.symmetric(
                            //         horizontal: 12, vertical: 4),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Search bar
                        TextField(
                          controller: _searchController, // Add this
                          onChanged: (value) => _runFilter(value),
                          decoration: InputDecoration(
                            hintText: 'Search by name or phone',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _runFilter('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Staff list
                        _buildStaffSection(surface),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isPlanExpired)
            ExpiredPlanOverlay(
              isOpen: true,
              planName: _planData?['planName'] ?? "Current Plan",
              onRenew: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UpgradeProScreen(activePlan: _planData!),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddStaff,
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Staff", style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: widget.hideInternalNav
          ? null // This removes the navigation bar entirely
          : BottomNavigationBar(
              selectedItemColor: primary,
              unselectedItemColor: Colors.grey[500],
              showUnselectedLabels: true,
              currentIndex: 0,
              onTap: (idx) {
                if (idx == 0) {
                  // already on home
                } else if (idx == 1) {
                  // NAVIGATE TO CRM
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CRMScreen()),
                  );
                } else if (idx == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminSettingsScreen(
                          planExpiryBanner: widget.planExpiryBanner),
                    ),
                  );
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handshake_outlined),
                  label: 'CRM',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }

  // Attendance summary with new visual style
  Widget _buildAttendanceSummaryCard(Color primary) {
    final cardGradient = LinearGradient(
      colors: [primary, const Color(0xFF2BA98A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Constrain height to content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Attendance today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openDailyAttendance(AttendanceFilter.all),
                child: Row(
                  children: const [
                    Text(
                      'View all',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use a LayoutBuilder to detect available width
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openDailyAttendance(AttendanceFilter.inStaff),
                    child: _summaryPill(
                      label: 'Present',
                      value: _isLoadingStats ? '...' : _inCount.toString(),
                      icon: Icons.login,
                    ),
                  ),
                ),
                const SizedBox(width: 4), // Reduced spacing
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _openDailyAttendance(AttendanceFilter.outStaff),
                    child: _summaryPill(
                      label: 'Left',
                      value: _isLoadingStats ? '...' : _outCount.toString(),
                      icon: Icons.logout,
                    ),
                  ),
                ),
                const SizedBox(width: 4), // Reduced spacing
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _openDailyAttendance(AttendanceFilter.noPunchIn),
                    child: _summaryPill(
                      label: 'No punch',
                      value:
                          _isLoadingStats ? '...' : _noPunchInCount.toString(),
                      icon: Icons.error_outline,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total staff: ${_isLoadingStats ? '...' : _totalStaff}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        // Switched from Row to Column for mobile vertical stacking
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(height: 4),
          FittedBox(
            // Automatically scales text down to fit available width
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // New quick actions layout: 2 x 2 grid of cards
  Widget _buildQuickActionsGrid(Color primary) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: [
        _quickActionCard(
          icon: Icons.list_alt_outlined,
          title: 'Pending requests',
          subtitle: 'Approve or reject',
          badgeText:
              _isLoadingPendingCount ? null : _totalPendingCount.toString(),
          color: Colors.indigo,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PendingRequestsScreen(),
              ),
            );
          },
        ),
        _quickActionCard(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Invite staff',
          subtitle: 'Send invites',
          color: primary,
          onTap: () {
            // 1. Trigger the share sheet
            _shareInviteMessage();

            // 2. Also call the original callback if needed
            widget.onInviteStaff();
          },
        ),
        _quickActionCard(
          icon: Icons.campaign_outlined,
          title: 'Announcements',
          subtitle: 'Share updates',
          badgeText: 'NEW',
          color: Colors.deepOrange,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AnnouncementsScreen(),
              ),
            );
          },
        ),
        _quickActionCard(
          icon: Icons.bar_chart_outlined,
          title: 'Reports',
          subtitle: 'View insights',
          color: Colors.purple,
          onTap: () {
            // Navigate to the CompanyReportsScreen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const CompanyReportsScreen(), // Ensure you import this screen
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badgeText != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: badgeText == 'NEW'
                              ? Colors.redAccent
                              : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffSection(Color surface) {
    if (_isLoadingStaff) {
      return Column(
        children: List.generate(3, (_) => _staffSkeletonTile(surface)),
      );
    }

    if (_filteredStaffList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline,
                size: 60, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              _selectedBranch == null
                  ? 'No staff members yet'
                  : 'No staff in ${_selectedBranch!.name}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add staff to start tracking attendance.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24), // Increased space from text
            Column(
              children: [
                // Standard Add Staff Button
                SizedBox(
                  width: double
                      .infinity, // Make buttons full width for better mobile UX
                  child: OutlinedButton.icon(
                    onPressed: _navigateToAddStaff,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Add staff'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),

                const SizedBox(height: 12), // Gap between the two buttons

                // Distinctly themed Invite Staff Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _shareInviteMessage,
                    icon:
                        const Icon(Icons.share, size: 18, color: Colors.white),
                    label: const Text('Invite staff via Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF206C5E), // Your Primary Deep Teal
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredStaffList.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final staff = _filteredStaffList[index];
          return _staffTile(staff);
        },
      ),
    );
  }

  Widget _staffSkeletonTile(Color surface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffTile(Staff staff) {
    final bgColor = staff.avatarColor ?? const Color(0xFF5C6BC0);
    final initial = staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'A';
    final bool isInactive = staff.employmentStatus?.toLowerCase() == 'inactive';

    return ListTile(
      // onTap: () async {
      //   final prefs = await SharedPreferences.getInstance();
      //   final companyId = prefs.getString('companyId');
      //   if (companyId == null) return;

      //   Navigator.of(context).push(
      //     MaterialPageRoute(
      //       builder: (_) => AttendanceScreen(
      //         phoneNumber: staff.phone,
      //         companyId: companyId,
      //       ),
      //     ),
      //   );
      // },
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StaffDetailScreen(staff: staff),
          ),
        );
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bgColor,
            child: staff.imageUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : ClipOval(
                    child: Image.network(
                      staff.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (isInactive)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.white, // White border around the red circle
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        staff.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isInactive ? Colors.black54 : Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isInactive
          ? const Text(
              'Inactive',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Ph: ${staff.phone}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'ID: ${staff.employeeId}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
    );
  }
}
