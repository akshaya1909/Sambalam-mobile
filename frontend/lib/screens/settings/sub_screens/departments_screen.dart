import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/department_api_service.dart';
import '../../../models/department_model.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentApiService _api = DepartmentApiService();

  List<Department> _departments = [];
  List<Employee> _allEmployees = [];

  bool _isLoading = true;
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');

    if (_companyId != null) {
      await _refreshData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      // Run both fetches in parallel for speed
      final results = await Future.wait([
        _api.getCompanyDepartments(_companyId!),
        _api.getCompanyEmployees(_companyId!),
      ]);

      setState(() {
        _departments = results[0] as List<Department>;
        _allEmployees = results[1] as List<Employee>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to load data', isError: true);
    }
  }

  // --- ACTIONS ---

  Future<void> _createDepartment(String name) async {
    try {
      await _api.createDepartment(_companyId!, name);
      _showSnack('Department created');
      _refreshData();
    } catch (e) {
      _showSnack('Failed to create department', isError: true);
    }
  }

  Future<void> _deleteDepartment(String id) async {
    try {
      await _api.deleteDepartment(id);
      _showSnack('Department deleted');
      _refreshData();
    } catch (e) {
      _showSnack('Failed to delete department', isError: true);
    }
  }

  // --- HELPERS ---

  // Get full employee objects for a specific department
  List<Employee> _getDeptStaff(Department dept) {
    return dept.staffIds
        .map((id) => _allEmployees.firstWhere(
              (e) => e.id == id,
              orElse: () => Employee(id: id, name: 'Unknown'),
            ))
        .toList();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF206C5E),
      ),
    );
  }

  // --- DIALOGS ---

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Department'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g., Engineering',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF206C5E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _createDepartment(controller.text.trim());
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManageStaffSheet(Department dept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageStaffSheet(
        department: dept,
        allEmployees: _allEmployees,
        api: _api,
        onSave: () {
          Navigator.pop(ctx);
          _refreshData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F4F6);
    const Color primary = Color(0xFF206C5E);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Departments',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Dept'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _departments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final dept = _departments[index];
                    final staffList = _getDeptStaff(dept);

                    return _DepartmentCard(
                      department: dept,
                      staff: staffList,
                      onManage: () => _showManageStaffSheet(dept),
                      onDelete: () => _deleteDepartment(dept.id),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.apartment_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No departments added yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Department Card (Expandable) ---

class _DepartmentCard extends StatelessWidget {
  final Department department;
  final List<Employee> staff;
  final VoidCallback onManage;
  final VoidCallback onDelete;

  const _DepartmentCard({
    Key? key,
    required this.department,
    required this.staff,
    required this.onManage,
    required this.onDelete,
  }) : super(key: key);

  // Helper method to show the popup
  void _confirmDeletion(
      BuildContext context, String deptName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department?'),
        content: Text(
            'Are you sure you want to delete "$deptName"? This will remove all staff from this department.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              onConfirm(); // Execute deletion logic
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          department.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          _getSubtitle(),
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          if (staff.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No staff assigned to this department',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: staff.map((emp) => _buildStaffChip(emp)).toList(),
            ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end, // Aligns buttons to the right
            spacing: 12, // Horizontal space between buttons
            runSpacing: 10, // Vertical space if buttons wrap to a new line
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _confirmDeletion(context, department.name, onDelete),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
              ElevatedButton.icon(
                onPressed: onManage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF206C5E),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.people_outline,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Manage Staff',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _getSubtitle() {
    if (staff.isEmpty) return 'No staff added';
    if (staff.length == 1) return staff.first.name;
    return '${staff.first.name} and ${staff.length - 1} others';
  }

  Widget _buildStaffChip(Employee emp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF206C5E),
            backgroundImage:
                emp.profilePic != null ? NetworkImage(emp.profilePic!) : null,
            child: emp.profilePic == null
                ? Text(emp.name[0],
                    style: const TextStyle(fontSize: 10, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            emp.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Manage Staff Sheet (BottomSheet) ---

class _ManageStaffSheet extends StatefulWidget {
  final Department department;
  final List<Employee> allEmployees;
  final DepartmentApiService api;
  final VoidCallback onSave;

  const _ManageStaffSheet({
    Key? key,
    required this.department,
    required this.allEmployees,
    required this.api,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_ManageStaffSheet> createState() => _ManageStaffSheetState();
}

class _ManageStaffSheetState extends State<_ManageStaffSheet> {
  // Store status: { employeeId: isSelected }
  final Map<String, bool> _tempStatus = {};
  String _search = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize status based on current department members
    for (var emp in widget.allEmployees) {
      _tempStatus[emp.id] = widget.department.staffIds.contains(emp.id);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final currentIds = widget.department.staffIds;
    final desiredIds =
        _tempStatus.entries.where((e) => e.value).map((e) => e.key).toList();

    // Calculate Diffs
    final toAdd = desiredIds.where((id) => !currentIds.contains(id)).toList();
    final toRemove =
        currentIds.where((id) => !desiredIds.contains(id)).toList();

    try {
      // Execute all API calls in parallel
      await Future.wait([
        ...toAdd.map((id) => widget.api.addStaff(widget.department.id, id)),
        ...toRemove
            .map((id) => widget.api.removeStaff(widget.department.id, id)),
      ]);

      widget.onSave();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update staff'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allEmployees
        .where((e) => e.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manage ${widget.department.name} Staff',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          const Divider(height: 1),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search employees...',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),

          // Employee List
          Expanded(
            child: widget.allEmployees.isEmpty
                ? const Center(child: Text('No employees found in company'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final emp = filtered[index];
                      final isSelected = _tempStatus[emp.id] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: const Color(0xFF206C5E),
                          onChanged: (val) {
                            setState(() => _tempStatus[emp.id] = val!);
                          },
                          secondary: CircleAvatar(
                            backgroundColor: const Color(0xFFEEF2FF),
                            backgroundImage: emp.profilePic != null
                                ? NetworkImage(emp.profilePic!)
                                : null,
                            child: emp.profilePic == null
                                ? Text(emp.name[0],
                                    style: const TextStyle(
                                        color: Color(0xFF206C5E)))
                                : null,
                          ),
                          title: Text(emp.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      );
                    },
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF206C5E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
