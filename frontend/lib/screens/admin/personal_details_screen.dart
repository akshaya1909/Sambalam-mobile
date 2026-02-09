import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/employee_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String employeeUserId;

  const PersonalDetailsScreen({Key? key, required this.employeeUserId})
      : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _employeeId;

  // Theme Colors
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color sectionBg = const Color(0xFFF8FAFB);

  // --- Controllers ---
  // Basic
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  // Emergency
  final TextEditingController _guardianController = TextEditingController();
  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _emergencyRelController = TextEditingController();
  final TextEditingController _emergencyAddrController =
      TextEditingController();
  // Government IDs
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _voterController = TextEditingController();
  final TextEditingController _uanController = TextEditingController();
  // Address
  final TextEditingController _currentAddrController = TextEditingController();
  final TextEditingController _permAddrController = TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedBloodGroup;
  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _aadharRegex = RegExp(r'^[2-9]{1}[0-9]{3}[0-9]{4}[0-9]{4}$');
  final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  final RegExp _voterRegex = RegExp(r'^[A-Z]{3}[0-9]{7}$');
  final RegExp _uanRegex = RegExp(r'^10[0-9]{10}$');

  String? _selectedRelationship;
  final List<String> _relationships = [
    "Father",
    "Mother",
    "Spouse",
    "Son",
    "Daughter",
    "Brother",
    "Sister",
    "Guardian",
    "Friend",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";
      final data = await _employeeService.getEmployeeByUserId(
          widget.employeeUserId, companyId);

      setState(() {
        _employeeId = data['_id'];
        // Basic
        _nameController.text = data['basic']?['fullName'] ?? "";
        _phoneController.text = data['basic']?['phone'] ?? "";
        _emailController.text = data['personal']?['personalEmail'] ?? "";
        _selectedGender = data['basic']?['gender'];
        _selectedMaritalStatus = data['personal']?['maritalStatus'];
        _selectedBloodGroup = data['personal']?['bloodGroup'];
        if (data['personal']?['dob'] != null) {
          _dobController.text = DateFormat('yyyy-MM-dd')
              .format(DateTime.parse(data['personal']['dob']));
        }
        // Emergency
        _guardianController.text = data['personal']?['guardianName'] ?? "";
        _emergencyNameController.text =
            data['personal']?['emergencyContactName'] ?? "";
        _emergencyPhoneController.text =
            data['personal']?['emergencyContactNumber'] ?? "";
        _selectedRelationship =
            data['personal']?['emergencyContactRelationship'];
        _emergencyAddrController.text =
            data['personal']?['emergencyContactAddress'] ?? "";
        // IDs
        _aadharController.text = data['personal']?['aadharNumber'] ?? "";
        _panController.text = data['personal']?['panNumber'] ?? "";
        _voterController.text = data['personal']?['voterIdNumber'] ?? "";
        _uanController.text = data['personal']?['uanNumber'] ?? "";
        // Addresses
        _currentAddrController.text = data['basic']?['currentAddress'] ?? "";
        _permAddrController.text = data['personal']?['permanentAddress'] ?? "";

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    // 2. Email Validation
    if (_emailController.text.isNotEmpty &&
        !_emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid email address"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // 3. Age Validation (Must be 18+)
    if (_dobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select Date of Birth"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    DateTime dob = DateTime.parse(_dobController.text);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User must be at least 18 years old"),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_aadharController.text.isNotEmpty &&
        !_aadharRegex.hasMatch(_aadharController.text)) {
      _showErrorSnack("Enter a valid 12-digit Aadhaar Number");
      return;
    }

    // PAN: 5 Alphabets, 4 Digits, 1 Alphabet
    if (_panController.text.isNotEmpty &&
        !_panRegex.hasMatch(_panController.text.toUpperCase())) {
      _showErrorSnack("Enter a valid PAN Number (e.g., ABCDE1234F)");
      return;
    }

    // Voter ID: 3 Alphabets, 7 Digits (Standard format)
    if (_voterController.text.isNotEmpty &&
        !_voterRegex.hasMatch(_voterController.text.toUpperCase())) {
      _showErrorSnack("Enter a valid Voter ID (e.g., ABC1234567)");
      return;
    }

    // UAN: 12 Digits starting with 10
    if (_uanController.text.isNotEmpty &&
        !_uanRegex.hasMatch(_uanController.text)) {
      _showErrorSnack("Enter a valid 12-digit UAN starting with 10");
      return;
    }

    // 4. Proceed to Save
    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "personalEmail": _emailController.text.trim(),
        "dob": _dobController.text,
        "gender": _selectedGender,
        "maritalStatus": _selectedMaritalStatus,
        "bloodGroup": _selectedBloodGroup,
        "guardianName": _guardianController.text.trim(),
        "emergencyContactName": _emergencyNameController.text.trim(),
        "emergencyContactNumber": _emergencyPhoneController.text.trim(),
        "emergencyContactRelationship": _selectedRelationship,
        "emergencyContactAddress": _emergencyAddrController.text.trim(),
        "aadharNumber": _aadharController.text.trim(),
        "panNumber": _panController.text.trim(),
        "voterIdNumber": _voterController.text.trim(),
        "uanNumber": _uanController.text.trim(),
        "currentAddress": _currentAddrController.text.trim(),
        "permanentAddress": _permAddrController.text.trim(),
      };

      await _employeeService.updateEmployee(widget.employeeUserId!, updateData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Profile Updated!"), backgroundColor: Colors.teal));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [primaryDeepTeal, secondaryTeal])),
        ),
        title: const Text("Edit Personal Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDeepTeal))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSectionHeader("BASIC IDENTITY", Icons.person_outline),
                    _buildSectionCard([
                      _buildField("Full Name", _nameController),
                      _buildField("Mobile Number", _phoneController,
                          keyboardType: TextInputType.phone),
                      _buildField("Personal Email ID", _emailController,
                          keyboardType: TextInputType.emailAddress),
                      _buildDatePicker("Date of Birth"),
                      _buildDropdown(
                          "Gender",
                          ["Male", "Female", "Other"],
                          _selectedGender,
                          (v) => setState(() => _selectedGender = v)),
                      _buildDropdown(
                          "Marital Status",
                          ["Unmarried", "Married", "Divorced", "Widow"],
                          _selectedMaritalStatus,
                          (v) => setState(() => _selectedMaritalStatus = v)),
                      _buildDropdown(
                          "Blood Group",
                          ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
                          _selectedBloodGroup,
                          (v) => setState(() => _selectedBloodGroup = v)),
                    ]),
                    _buildSectionHeader(
                        "EMERGENCY CONTACTS", Icons.contact_emergency_outlined),
                    _buildSectionCard([
                      _buildField("Guardian's Name", _guardianController),
                      _buildField(
                          "Emergency Contact Name", _emergencyNameController),
                      _buildDropdown(
                        "Relationship",
                        _relationships,
                        _selectedRelationship,
                        (v) => setState(() => _selectedRelationship = v),
                      ),
                      _buildField("Emergency Mobile", _emergencyPhoneController,
                          keyboardType: TextInputType.phone),
                      _buildField("Emergency Address", _emergencyAddrController,
                          maxLines: 2),
                    ]),
                    _buildSectionHeader("GOVERNMENT IDS", Icons.badge_outlined),
                    _buildSectionCard([
                      _buildField("Aadhaar Number", _aadharController,
                          keyboardType: TextInputType.number),
                      _buildField("PAN Number", _panController,
                          textCapitalization: TextCapitalization.characters),
                      _buildField("Voter ID Number", _voterController,
                          textCapitalization: TextCapitalization.characters),
                      _buildField("UAN Number", _uanController,
                          keyboardType: TextInputType.number),
                    ]),
                    _buildSectionHeader(
                        "ADDRESS DETAILS", Icons.location_on_outlined),
                    _buildSectionCard([
                      _buildField("Current Address", _currentAddrController,
                          maxLines: 3),
                      _buildField("Permanent Address", _permAddrController,
                          maxLines: 3),
                    ]),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryDeepTeal),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                  letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        // validator: (value) {
        //   if (value == null || value.isEmpty) return "$label is required";
        //   return null;
        // },
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        onTap: () async {
          DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now());
          if (picked != null)
            setState(() =>
                _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryDeepTeal, secondaryTeal]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: secondaryTeal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveDetails,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("UPDATE ALL DETAILS",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
