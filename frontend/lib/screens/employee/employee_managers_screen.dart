import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/employee_api_service.dart';
import '../../api/branch_api_service.dart';
import '../../models/company_user.dart';
import '../../models/branch_model.dart';

class EmployeeManagersScreen extends StatefulWidget {
  const EmployeeManagersScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeManagersScreen> createState() => _EmployeeManagersScreenState();
}

class _EmployeeManagersScreenState extends State<EmployeeManagersScreen> {
  final EmployeeApiService _apiService = EmployeeApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _companyId = '';
  List<CompanyUser> _allUsers = [];

  // Track updating state per user to show individual loaders
  final Set<String> _updatingUserIds = {};
  List<Branch> _companyBranches = [];

  String _activeFilter = 'All';
  final List<String> _filters = [
    'All',
    'Employee',
    'Branch Admin',
    'Attendance Manager',
    'Advanced Attendance Manager'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cId = prefs.getString('companyId');
    if (cId == null) return;

    setState(() => _companyId = cId);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getCompanyUsers(_companyId);
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Getter for filtration logic
  List<CompanyUser> get _displayUsers {
    final q = _searchController.text.toLowerCase();

    return _allUsers.where((u) {
      // 1. Hide Admins from this specific list
      if (u.role.toLowerCase() == 'admin') return false;

      // 2. Search filtering
      final matchesSearch = u.name.toLowerCase().contains(q);

      // 3. Chip selection filtering
      if (_activeFilter == 'All') return matchesSearch;

      final roleMap = {
        'Employee': 'employee',
        'Branch Admin': 'branch admin',
        'Attendance Manager': 'attendance manager',
        'Advanced Attendance Manager': 'advanced attendance manager',
      };

      return matchesSearch && u.role.toLowerCase() == roleMap[_activeFilter];
    }).toList();
  }

  Future<void> _changeRole(
      CompanyUser user, String newRole, List<String> selectedBranches) async {
    setState(() => _updatingUserIds.add(user.id));

    try {
      await _apiService.updateUserRole(
        companyId: _companyId,
        userId: user.id,
        oldRole: user.role,
        newRole: newRole.toLowerCase(),
        branchIds: selectedBranches,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Role updated successfully"),
              backgroundColor: Colors.green),
        );
        await _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingUserIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF206C5E); // Deep Green/Teal
    final filteredList = _displayUsers;

    // Split into groups for the UI
    final branchAdmins = filteredList
        .where((u) => u.role.toLowerCase() == 'branch admin')
        .toList();
    final attendanceManagers = filteredList
        .where((u) => u.role.toLowerCase() == 'attendance manager')
        .toList();
    final advancedAttendanceManagers = filteredList
        .where((u) => u.role.toLowerCase() == 'advanced attendance manager')
        .toList();
    final employees =
        filteredList.where((u) => u.role.toLowerCase() == 'employee').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Employees & Managers',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Filtration Chips
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final label = _filters[index];
                final isSelected = _activeFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _activeFilter = label),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name of employee',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (branchAdmins.isNotEmpty) ...[
                            _buildSectionHeader(
                                'BRANCH ADMINS (${branchAdmins.length})'),
                            const SizedBox(height: 12),
                            _buildGrid(branchAdmins),
                            const SizedBox(height: 24),
                          ],
                          if (attendanceManagers.isNotEmpty) ...[
                            _buildSectionHeader(
                                'ATTENDANCE MANAGERS (${attendanceManagers.length})'),
                            const SizedBox(height: 12),
                            _buildGrid(attendanceManagers),
                            const SizedBox(height: 24),
                          ],
                          if (advancedAttendanceManagers.isNotEmpty) ...[
                            _buildSectionHeader(
                                'ADVANCED ATTENDANCE MANAGERS (${advancedAttendanceManagers.length})'),
                            const SizedBox(height: 12),
                            _buildGrid(advancedAttendanceManagers),
                            const SizedBox(height: 24),
                          ],
                          if (employees.isNotEmpty) ...[
                            _buildSectionHeader(
                                'EMPLOYEES (${employees.length})'),
                            const SizedBox(height: 12),
                            _buildGrid(employees),
                          ],
                          if (filteredList.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Text("No users found",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGrid(List<CompanyUser> users) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  Widget _buildUserCard(CompanyUser user) {
    final bool isUpdating = _updatingUserIds.contains(user.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE2E8F0),
            child: Text(user.initials,
                style: const TextStyle(
                    color: Color(0xFF475569), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(user.role.toUpperCase(),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
          ),
          if (isUpdating)
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton(
              onPressed: () => _showRoleDialog(user),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text("EDIT ROLE",
                  style: TextStyle(
                      color: Color(0xFF206C5E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showRoleDialog(CompanyUser user) async {
    String tempRole = user.role.toLowerCase();
    List<String> selectedBranchIds = List.from(user.assignedBranches);

    if (_companyBranches.isEmpty) {
      final branchApi = BranchApiService(); // Assumes you have this service
      _companyBranches = await branchApi.getCompanyBranches(_companyId);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Select Role",
              style: TextStyle(fontWeight: FontWeight.bold)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _roleOption(
                  setModalState,
                  'Branch Admin',
                  'branch admin',
                  'Mark attendance & salary of all employees',
                  tempRole,
                  (v) => tempRole = v),
              if (tempRole == 'branch admin')
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Branches *",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey)),
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
                  ),
                ),
              _roleOption(
                  setModalState,
                  'Attendance Manager',
                  'attendance manager',
                  'Mark attendance of all employees',
                  tempRole,
                  (v) => tempRole = v),
              _roleOption(
                  setModalState,
                  'Advanced Attendance Manager',
                  'advanced attendance manager',
                  'Mark attendance of any day',
                  tempRole,
                  (v) => tempRole = v),
              _roleOption(setModalState, 'Employee', 'employee',
                  'Mark their own attendance', tempRole, (v) => tempRole = v),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (tempRole == 'branch admin' && selectedBranchIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please select at least one branch")));
                  return;
                }
                Navigator.pop(context);
                _changeRole(user, tempRole, selectedBranchIds);
              },
              child: const Text("UPDATE",
                  style: TextStyle(
                    color: Colors.green, // Updated to pure Green as requested
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(StateSetter setState, String title, String value,
      String sub, String groupVal, Function(String) onChange) {
    return RadioListTile<String>(
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: groupVal,
      activeColor: Colors.green, // Updated to match requested theme
      contentPadding: EdgeInsets.zero,
      onChanged: (val) => setState(() => onChange(val!)),
    );
  }
}
