import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/employee_service.dart';
import '../../api/branch_api_service.dart';
import '../../api/department_api_service.dart';
import '../../../models/branch_model.dart';
import '../../../models/department_model.dart';

class EmploymentDetailsScreen extends StatefulWidget {
  final String employeeUserId;

  const EmploymentDetailsScreen({Key? key, required this.employeeUserId})
      : super(key: key);

  @override
  State<EmploymentDetailsScreen> createState() =>
      _EmploymentDetailsScreenState();
}

class _EmploymentDetailsScreenState extends State<EmploymentDetailsScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final BranchApiService _branchApi = BranchApiService();
  final DepartmentApiService _deptApi = DepartmentApiService();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _dojController = TextEditingController();
  final TextEditingController _dolController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _officialEmailController =
      TextEditingController();
  final TextEditingController _pfController = TextEditingController();
  final TextEditingController _esiController = TextEditingController();

  // Selection States
  String? _selectedEmployeeType;
  int _probationMonths = 6;
  List<String> _selectedBranchIds = [];
  List<String> _selectedDeptIds = [];

  // Master Data
  List<Branch> _allBranches = [];
  List<Department> _allDepartments = [];
  final RegExp _pfRegex = RegExp(r'^[A-Z]{2}[A-Z]{3}[0-9]{7}[0-9]{3}[0-9]{7}$');
// ESI Format: 17 digits
  final RegExp _esiRegex = RegExp(r'^[0-9]{17}$');
// Email Regex
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // Theme Colors
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _loadAllData();
    debugPrint("Master Branch IDs: ${_allBranches.map((e) => e.id).toList()}");
    debugPrint("Selected Branch IDs: $_selectedBranchIds");
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      final results = await Future.wait([
        _employeeService.getEmployeeByUserId(widget.employeeUserId, companyId),
        _branchApi.getCompanyBranches(companyId),
        _deptApi.getCompanyDepartments(companyId),
      ]);

      final empData = results[0] as Map<String, dynamic>;
      final branchesMaster = results[1] as List<Branch>;
      final departmentsMaster = results[2] as List<Department>;

      final basic = empData['basic'] ?? {};
      final employment =
          (empData['employment'] != null && empData['employment'].isNotEmpty)
              ? empData['employment'][0]
              : {};

      setState(() {
        _allBranches = branchesMaster;
        _allDepartments = departmentsMaster;

        _jobTitleController.text = basic['jobTitle'] ?? "";
        _officialEmailController.text = basic['officialEmail'] ?? "";
        _employeeIdController.text = employment['employeeId'] ?? "";
        _pfController.text = employment['pfNumber'] ?? "";
        _esiController.text = employment['esiNumber'] ?? "";
        _selectedEmployeeType = employment['employeeType'];
        _probationMonths = employment['probationPeriod'] ?? 6;

        // EXTRACT IDs Safely
        if (basic['branches'] != null) {
          _selectedBranchIds = (basic['branches'] as List).map((item) {
            if (item is Map) {
              if (item.containsKey('\$oid')) return item['\$oid'].toString();
              if (item.containsKey('_id')) return item['_id'].toString();
            }
            return item.toString();
          }).toList();
        }

        if (basic['departments'] != null) {
          _selectedDeptIds = (basic['departments'] as List).map((item) {
            if (item is Map) {
              if (item.containsKey('\$oid')) return item['\$oid'].toString();
              if (item.containsKey('_id')) return item['_id'].toString();
            }
            return item.toString();
          }).toList();
        }

        // Handle Date parsing for MongoDB format
        _parseAndSetDate(basic['dateOfJoining'], _dojController);
        _parseAndSetDate(employment['dateOfLeaving'], _dolController);

        _isLoading = false;
      });

      debugPrint("Master IDs: ${_allBranches.map((e) => e.id).toList()}");
      debugPrint("Selected IDs: $_selectedBranchIds");
    } catch (e) {
      debugPrint("Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseAndSetDate(dynamic rawDate, TextEditingController controller) {
    if (rawDate == null) return;
    String? dateStr;
    if (rawDate is Map && rawDate.containsKey('\$date')) {
      dateStr = rawDate['\$date'];
    } else {
      dateStr = rawDate.toString();
    }
    try {
      controller.text =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(dateStr!));
    } catch (e) {
      debugPrint("Date error: $e");
    }
  }

  Future<void> _updateDetails() async {
    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least one branch")));
      return;
    }

    // 2. Official Email Validation
    String email = _officialEmailController.text.trim();
    if (email.isNotEmpty && !_emailRegex.hasMatch(email)) {
      _showErrorSnack("Please enter a valid official email address");
      return;
    }

    // 3. PF Number Validation (Optional but validated if provided)
    String pf = _pfController.text.trim().toUpperCase();
    if (pf.isNotEmpty && !_pfRegex.hasMatch(pf)) {
      _showErrorSnack(
          "Invalid PF format. Expected 22 alphanumeric characters (e.g., DLCPM00123450000000001)");
      return;
    }

    // 4. ESI Number Validation (Optional but validated if provided)
    String esi = _esiController.text.trim();
    if (esi.isNotEmpty && !_esiRegex.hasMatch(esi)) {
      _showErrorSnack("Invalid ESI format. Expected 17 digits");
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. Get companyId from local storage
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      final employeeData = await _employeeService.getEmployeeByUserId(
          widget.employeeUserId, companyId);
      final String phone = employeeData['basic']['phone'];

      final payload = {
        "phone": phone,
        "branches": _selectedBranchIds,
        "departments": _selectedDeptIds,
        "employeeType": _selectedEmployeeType,
        "dateOfJoining": _dojController.text,
        "dateOfLeaving":
            _dolController.text.isEmpty ? null : _dolController.text,
        "employeeId": _employeeIdController.text.trim(),
        "jobTitle": _jobTitleController.text.trim(),
        "officialEmail": email,
        "esiNumber": esi,
        "pfNumber": pf,
        "probationPeriod": _probationMonths,
      };

      await _employeeService.updateEmploymentDetails(
          widget.employeeUserId, payload);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Employment Updated Successfully")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update Failed: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Current Employment",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [primaryDeepTeal, secondaryTeal])),
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDeepTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildMultiSelectTile(
                        "Branch",
                        _allBranches.map((e) => e.name).toList(),
                        _allBranches.map((e) => e.id).toList(),
                        _selectedBranchIds),
                    _buildMultiSelectTile(
                        "Departments",
                        _allDepartments.map((e) => e.name).toList(),
                        _allDepartments.map((e) => e.id).toList(),
                        _selectedDeptIds),
                    _buildDropdownField(
                        "Employee Type",
                        [
                          "Full Time",
                          "Permanent",
                          "Part Time",
                          "Contract",
                          "Intern"
                        ],
                        _selectedEmployeeType,
                        (val) => setState(() => _selectedEmployeeType = val)),
                    _buildTextField("Job Title", _jobTitleController),
                    _buildDatePicker("Date Of Joining", _dojController),
                    _buildDatePicker("Date Of Leaving", _dolController),
                    _buildTextField("Employee ID", _employeeIdController),
                    _buildTextField(
                        "Official Email ID", _officialEmailController),
                    _buildTextField("PF A/C No.", _pfController,
                        maxLength: 22,
                        hint: "Region(2)Office(3)Est(7)Ext(3)Mem(7)"),
                    _buildTextField("ESI A/C No.", _esiController,
                        maxLength: 17,
                        keyboardType: TextInputType.number,
                        hint: "17 digit number"),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int? maxLength,
      TextInputType keyboardType = TextInputType.text,
      String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboardType,
            decoration: _inputDecoration().copyWith(
              hintText: hint,
              counterText: "", // Hide character counter
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            decoration: _inputDecoration(),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() =>
                    controller.text = DateFormat('yyyy-MM-dd').format(picked));
              }
            },
            decoration: _inputDecoration().copyWith(
                suffixIcon: const Icon(Icons.calendar_today, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectTile(String label, List<String> names,
      List<String> ids, List<String> selectedList) {
    String displayValue = "Select $label";
    if (selectedList.isNotEmpty && names.isNotEmpty && ids.isNotEmpty) {
      displayValue = selectedList
          .map((id) {
            int idx = ids.indexOf(id);
            return idx != -1 ? names[idx] : null;
          })
          .whereType<String>()
          .join(", ");

      if (displayValue.isEmpty) displayValue = "Select $label";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () =>
                _showMultiSelectDialog(label, names, ids, selectedList),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Expanded(
                      child: Text(displayValue,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectDialog(String title, List<String> names,
      List<String> ids, List<String> selectedList) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Select $title"),
            content: SingleChildScrollView(
              child: Column(
                children: List.generate(names.length, (index) {
                  return CheckboxListTile(
                    title: Text(names[index]),
                    value: selectedList.contains(ids[index]),
                    activeColor: secondaryTeal,
                    onChanged: (bool? checked) {
                      setDialogState(() {
                        if (checked!) {
                          selectedList.add(ids[index]);
                        } else {
                          selectedList.remove(ids[index]);
                        }
                      });
                      setState(() {}); // Update main screen
                    },
                  );
                }),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Done", style: TextStyle(color: primaryDeepTeal)))
            ],
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondaryTeal, width: 2)),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryDeepTeal, secondaryTeal]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _updateDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Save Details",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
