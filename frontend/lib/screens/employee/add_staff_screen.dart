import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/employee_service.dart';
import '../../../api/branch_api_service.dart';
import '../../../api/department_api_service.dart';
import '../settings/sub_screens/branches_screen.dart';
import '../settings/sub_screens/departments_screen.dart';
import '../../../models/branch_model.dart';
import '../../../models/department_model.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({Key? key}) : super(key: key);

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();

  // APIs
  final EmployeeService _employeeService = EmployeeService();
  final BranchApiService _branchApi = BranchApiService();
  final DepartmentApiService _deptApi = DepartmentApiService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Selection Data
  String? _selectedGender;
  List<Branch> _branches = [];
  List<Department> _departments = [];
  List<String> _selectedBranchIds = [];
  List<String> _selectedDeptIds = [];

  bool _isLoading = false;
  bool _fetchingMetadata = true;

  @override
  void initState() {
    super.initState();
    _loadAllMetadata();
  }

  void _showLimitReachedDialog(
      {required String planName, required String limit}) {
    const primaryDeepTeal = Color(0xFF206C5E);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amber Shield Icon
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield, color: Colors.amber[700], size: 30),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Employee Limit Reached",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(text: "With your current "),
                      TextSpan(
                        text: planName, // Dynamic Plan Name
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A), // Tailwind Slate-900
                        ),
                      ),
                      const TextSpan(text: ", you can only add up to "),
                      TextSpan(
                        text: "$limit employees.", // Dynamic Limit
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Upgrade Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDeepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close Dialog
                      // Navigate to your Upgrade/Pricing Screen here
                    },
                    child: const Text("Upgrade to Pro Plan",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                // Ghost "Maybe Later" Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Maybe Later",
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAllMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      if (companyId != null) {
        final results = await Future.wait([
          _branchApi.getCompanyBranches(companyId),
          _deptApi.getCompanyDepartments(companyId),
        ]);

        debugPrint("Branches found: ${(results[0] as List).length}"); // DEBUG
        debugPrint(
            "Departments found: ${(results[1] as List).length}"); // DEBUG

        setState(() {
          _branches = results[0] as List<Branch>;
          _departments = results[1] as List<Department>;
          _fetchingMetadata = false;
        });
      }
    } catch (e) {
      debugPrint("Metadata load error: $e");
      setState(() => _fetchingMetadata = false);
    }
  }

  void _generateOTP(String phone) {
    if (phone.length == 10) {
      setState(() {
        _otpController.text =
            (100000 + (DateTime.now().microsecondsSinceEpoch % 900000))
                .toString();
      });
    } else {
      _otpController.clear();
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    // Safety Check for Branches
    if (_selectedBranchIds.isEmpty) {
      _showSnackBar("Please select at least one branch", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId');

      // Safety Check for Company ID
      if (companyId == null || companyId.isEmpty) {
        throw Exception("Company ID not found. Please log in again.");
      }

      final Map<String, dynamic> data = {
        "fullName": _nameController.text.trim(),
        "initials": _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : "S",
        "jobTitle": _nameController.text.isNotEmpty
            ? _jobController.text.trim()
            : "", // Ensure not null
        "branches": _selectedBranchIds, // This is already a List<String>
        "departments": _selectedDeptIds, // This is already a List<String>
        "phone": _phoneController.text.trim(),
        "loginOtp": _otpController.text,
        "gender": _selectedGender ?? "Other", // Fallback to avoid null
        "officialEmail": _emailController.text.trim(),
        "currentAddress": _addressController.text.trim(),
        "companyId": companyId,
      };

      // DEBUG: Print the payload to verify before sending
      debugPrint("Payload: ${json.encode(data)}");

      final success = await _employeeService.createEmployee(data);
      if (success && mounted) {
        Navigator.pop(context, true);
        _showSnackBar("Staff member added successfully", Colors.green);
      }
    } catch (e) {
      debugPrint("Error creating employee: $e");

      // 1. Convert the error to a string
      final String errorString = e.toString();

      try {
        // 2. Extract the JSON part of the error (removing "Exception: " if present)
        final String cleanJson = errorString.startsWith("Exception: ")
            ? errorString.replaceFirst("Exception: ", "")
            : errorString;

        // 3. Decode the JSON map
        final Map<String, dynamic> errorData = json.decode(cleanJson);

        // 4. Check for specific backend error codes
        if (errorData['message'] == "LIMIT_REACHED") {
          _showLimitReachedDialog(
            planName: errorData['planName'] ?? "Current Plan",
            limit: errorData['limit']?.toString() ?? "0",
          );
        } else if (errorData['message'] == "PLAN_EXPIRED") {
          final String details =
              errorData['details'] ?? "Your plan has expired. Please renew.";
          _showSnackBar(details, Colors.red);
        } else {
          // General backend error message
          _showSnackBar(
              errorData['message'] ?? "Failed to add staff", Colors.red);
        }
      } catch (parseError) {
        // 5. Fallback if the error isn't valid JSON (e.g., network timeout)
        debugPrint("Parse error: $parseError");
        _showSnackBar(
            "A network error occurred. Please try again.", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    const primaryDeepTeal = Color(0xFF206C5E);
    const secondaryTeal = Color(0xFF2BA98A);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Staff",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeepTeal, secondaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _fetchingMetadata
          ? const Center(
              child: CircularProgressIndicator(color: primaryDeepTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("BASIC DETAILS", Icons.badge),
                    _buildTextField(_nameController, "Full Name",
                        Icons.person_outline, "Enter name"),
                    _buildTextField(_jobController, "Job Title",
                        Icons.work_outline, "e.g. Supervisor"),
                    const SizedBox(height: 25),
                    _buildSectionHeader(
                        "CONTACT & SECURITY", Icons.phone_android),
                    _buildPhoneField(),
                    _buildReadOnlyField(_otpController,
                        "Auto-generated Login OTP", Icons.vpn_key_outlined),
                    _buildTextField(_emailController, "Official Email",
                        Icons.email_outlined, "name@company.com",
                        isRequired: false),
                    const SizedBox(height: 25),
                    _buildSectionHeader(
                        "WORK ASSIGNMENT", Icons.account_tree_outlined),
                    _buildSelectionLabel("Select Branches *"),
                    _buildBranchChips(primaryDeepTeal),
                    const SizedBox(height: 15),
                    _buildSelectionLabel("Select Departments"),
                    _buildDeptChips(secondaryTeal),
                    const SizedBox(height: 25),
                    _buildSectionHeader("OTHER DETAILS", Icons.info_outline),
                    _buildGenderDropdown(),
                    _buildTextField(_addressController, "Current Address",
                        Icons.home_outlined, "Full address",
                        maxLines: 2, isRequired: false),
                    const SizedBox(height: 40),
                    _buildSubmitButton(primaryDeepTeal),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget Builders
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF206C5E)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String hint,
      {int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            isRequired ? (v) => v!.trim().isEmpty ? "Required" : null : null,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        onChanged: _generateOTP,
        decoration: InputDecoration(
          labelText: "Mobile Number",
          prefixText: "+91 ",
          counterText: "",
          prefixIcon: const Icon(Icons.phone_iphone, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) =>
            v!.length != 10 ? "Enter valid 10-digit number" : null,
      ),
    );
  }

  Widget _buildReadOnlyField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.orange.withOpacity(0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.shade100)),
        ),
      ),
    );
  }

  Widget _buildSelectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey));
  }

  Widget _buildBranchChips(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_branches.isEmpty)
          _buildEmptyAction(
            "No branches found. Add one to assign staff.",
            "Add Branch",
            Icons.add_location_alt_outlined,
            () => _navigateToSettings('branches'),
          )
        else
          Wrap(
            spacing: 8,
            children: _branches.map((b) {
              final isSelected = _selectedBranchIds.contains(b.id);
              return FilterChip(
                label: Text(b.name),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    val
                        ? _selectedBranchIds.add(b.id)
                        : _selectedBranchIds.remove(b.id);
                  });
                },
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDeptChips(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_departments.isEmpty)
          _buildEmptyAction(
            "No departments found. Add one to organize staff.",
            "Add Dept",
            Icons.domain_add_outlined,
            () => _navigateToSettings('departments'),
          )
        else
          Wrap(
            spacing: 8,
            children: _departments.map((d) {
              final isSelected = _selectedDeptIds.contains(d.id);
              return FilterChip(
                label: Text(d.name),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    val
                        ? _selectedDeptIds.add(d.id)
                        : _selectedDeptIds.remove(d.id);
                  });
                },
                selectedColor: color.withOpacity(0.2),
                checkmarkColor: color,
              );
            }).toList(),
          ),
      ],
    );
  }

  // --- NEW: Navigation Helper ---
  void _navigateToSettings(String type) async {
    // Determine the route based on the sub_screens folder structure
    Widget targetScreen;
    if (type == 'branches') {
      // Ensure you have imported these screens at the top
      targetScreen = const BranchesScreen();
    } else {
      targetScreen = const DepartmentsScreen();
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => targetScreen),
    );

    // Refresh metadata when returning from settings
    _loadAllMetadata();
  }

  // --- NEW: Empty State UI Builder ---
  Widget _buildEmptyAction(
      String message, String buttonText, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(message,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(buttonText),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF206C5E),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF206C5E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: "Gender",
          prefixIcon: const Icon(Icons.wc, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: ["Male", "Female", "Other"]
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (val) => setState(() => _selectedGender = val),
      ),
    );
  }

  Widget _buildSubmitButton(Color color) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveStaff,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("CREATE STAFF ACCOUNT",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1)),
      ),
    );
  }
}
