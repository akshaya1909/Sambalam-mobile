import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/department_api_service.dart';
import '../../api/work_report_api_service.dart';
import '../../models/department_model.dart';

class WorkReportSettingsScreen extends StatefulWidget {
  final Map<String, dynamic>? template;
  const WorkReportSettingsScreen({Key? key, this.template}) : super(key: key);

  @override
  State<WorkReportSettingsScreen> createState() =>
      _WorkReportSettingsScreenState();
}

class _WorkReportSettingsScreenState extends State<WorkReportSettingsScreen> {
  final DepartmentApiService _deptApi = DepartmentApiService();
  final WorkReportApiService _workReportApi = WorkReportApiService();
  final TextEditingController _titleController =
      TextEditingController(text: "Daily Work Report");

  // Theme Colors
  final Color primaryGreen = const Color(0xFF206C5E);
  final Color secondaryGreen = const Color(0xFF2BA98A);
  final Color bgGrey = const Color(0xFFF8FAFC);
  final Color textDark = const Color(0xFF1E293B);
  final Color textLight = const Color(0xFF64748B);

  bool _isLoading = true;
  bool _isSaving = false;
  List<Department> _departments = [];
  List<String> _selectedDeptIds = [];
  bool _isAllDepartments = true;

  // --- UPDATED: Initial fields are now removable (is_removable: true) ---
  List<Map<String, dynamic>> _fields = [
    {
      'label': 'Date',
      'type': 'date',
      'is_required': true,
      'is_removable': true // Change from false to true
    },
    {
      'label': 'Work Done Summary',
      'type': 'text',
      'is_required': true,
      'is_removable': true // Change from false to true
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleController.text = widget.template!['title'] ?? "Daily Work Report";
      // PREFILL DATA IF EDITING
      _isAllDepartments = widget.template!['isForAllDepartments'];
      _selectedDeptIds = List<String>.from(
          widget.template!['departmentIds'].map((d) => d['_id']));
      _fields = (widget.template!['fields'] as List)
          .map((f) => {
                'label': f['label'],
                'type': f['fieldType'],
                'is_required': f['isRequired'],
                'is_removable': true,
                'options': List<String>.from(f['options'] ?? []),
              })
          .toList();
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? '';
      final depts = await _deptApi.getCompanyDepartments(companyId);
      setState(() {
        _departments = depts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addNewField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateFieldSheet(onFieldAdded: (newField) {
        setState(() => _fields.add(newField));
      }),
    );
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a template name")),
      );
      return;
    }
    // 1. Mandatory Department Check
    if (!_isAllDepartments && _selectedDeptIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Please select at least one department"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Mandatory Fields Check
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Template must have at least one field")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? '';

      final success = await _workReportApi.saveTemplate(
        templateId: widget.template?['_id'],
        companyId: companyId,
        departmentIds: _selectedDeptIds,
        isAllDepartments: _isAllDepartments,
        fields: _fields,
        title: _titleController.text.trim(),
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Work Report Template Applied"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect to server")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryGreen, secondaryGreen]),
          ),
        ),
        title: const Text("Work Report Configuration",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 17)),
        actions: [
          IconButton(
            tooltip: "Preview Form",
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () => _showPreviewSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                            "Template Name", Icons.edit_note_rounded),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "e.g., Sales Daily Report",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Target Departments",
                            Icons.corporate_fare_outlined),
                        _buildDeptSelector(),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                            "Report Template Fields", Icons.list_alt_rounded),
                        const SizedBox(height: 12),
                        _buildFieldsList(),
                        const SizedBox(height: 24),
                        _buildQuickAddActions(),
                      ],
                    ),
                  ),
                ),
                _buildSaveFooter(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPreviewField(Map<String, dynamic> field) {
    if (field['type'] == 'dropdown') {
      List<String> options =
          List<String>.from(field['options'] ?? ["No Options"]);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            hint: Text("Select ${field['label']}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (_) {}, // Static for preview
          ),
        ),
      );
    }
    if (field['type'] == 'image' || field['type'] == 'file') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(
                field['type'] == 'image'
                    ? Icons.camera_alt_outlined
                    : Icons.upload_file,
                color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text("Tap to upload ${field['label']}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      );
    }

    // Default for text, number, date, dropdown, etc.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        "Enter ${field['label']}...",
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    );
  }

  Widget _buildDeptSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _isAllDepartments,
            onChanged: (v) => setState(() {
              _isAllDepartments = v!;
              if (v) _selectedDeptIds.clear();
            }),
            title: const Text("All Departments",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: Text("Template will apply to every staff member",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            activeColor: primaryGreen,
            contentPadding: EdgeInsets.zero,
          ),
          if (!_isAllDepartments) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 0,
                children: _departments.map((dept) {
                  final isSelected = _selectedDeptIds.contains(dept.id);
                  return FilterChip(
                    label: Text(dept.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected)
                          _selectedDeptIds.add(dept.id);
                        else
                          _selectedDeptIds.remove(dept.id);
                      });
                    },
                    selectedColor: primaryGreen.withOpacity(0.1),
                    checkmarkColor: primaryGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color:
                            isSelected ? primaryGreen : Colors.grey.shade300),
                    labelStyle: TextStyle(
                        color: isSelected ? primaryGreen : Colors.black87,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal),
                  );
                }).toList(),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    if (_fields.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.layers_clear_outlined,
                color: Colors.grey.shade300, size: 40),
            const SizedBox(height: 12),
            const Text("No fields added yet",
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fields.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final field = _fields[index];
        bool isMandatory = field['is_required'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Icon Section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: bgGrey, borderRadius: BorderRadius.circular(10)),
                    child: Icon(_getFieldIcon(field['type']),
                        size: 18, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  // 2. Label and Type Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field['label'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(field['type'].toString().toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  // 3. Top Action Section (Mandatory + Delete)
                  Row(
                    children: [
                      Column(
                        children: [
                          const Text("Mandatory",
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: Checkbox(
                              activeColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              value: isMandatory,
                              onChanged: (val) {
                                setState(() {
                                  _fields[index]['is_required'] = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent, size: 24),
                        onPressed: () =>
                            setState(() => _fields.removeAt(index)),
                      ),
                    ],
                  ),
                ],
              ),

              // --- DROPDOWN OPTIONS SECTION BELOW DIVIDER ---
              if (field['type'] == 'dropdown' && field['options'] != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  children: [
                    const Icon(Icons.list_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Options: ${(field['options'] as List).join(', ')}",
                        style: TextStyle(
                            fontSize: 11,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "SUGGESTED FIELDS",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade200)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _modernSuggestionTile(
                "Date", Icons.event_available_rounded, "date"),
            _modernSuggestionTile(
                "Serial No.", Icons.format_list_numbered_rounded, "text"),
            _modernSuggestionTile("Description", Icons.notes_rounded, "text"),
            _modernSuggestionTile(
                "Percentage Done", Icons.percent_rounded, "number"),
            _modernSuggestionTile(
                "Deadline Date", Icons.event_available_rounded, "date"),
            _modernSuggestionTile(
                "Work Done Summary", Icons.notes_rounded, "text"),
            _modernSuggestionTile(
                "Task Status", Icons.rule_rounded, "dropdown"),
            _modernSuggestionTile(
              "Photos",
              Icons.camera_alt_outlined,
              "image", // Updated from 'text' to 'image'
            ),
            _modernSuggestionTile(
              "Attachments",
              Icons.file_present_rounded,
              "file", // Updated from 'text' to 'file'
            ),
            InkWell(
              onTap: _addNewField,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Custom Field",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modernSuggestionTile(String label, IconData icon, String type) {
    return InkWell(
      onTap: () {
        List<String> defaultOptions = [];
        // Set default options for Task Status
        if (label == "Task Status") {
          defaultOptions = ["In Progress", "Completed"];
        }
        setState(() => _fields.add({
              'label': label,
              'type': type,
              'is_required': true,
              'is_removable': true,
              'options': defaultOptions,
            }));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryGreen, secondaryGreen]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent),
          child: Text(
              widget.template != null ? "Update Template" : "Apply Template",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }

  void _showPreviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Employee View Preview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("This is how the report form will appear to staff.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const Divider(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: _fields.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  bool isRequired = field['is_required'] ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(field['label'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          if (isRequired)
                            const Text(" *",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPreviewField(field),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'date':
        return Icons.calendar_today_rounded;
      case 'number':
        return Icons.pin_rounded;
      case 'dropdown':
        return Icons.arrow_drop_down_circle_outlined;
      case 'image': // Added image case
        return Icons.image_outlined;
      case 'file': // Added file case
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.text_fields_rounded;
    }
  }
}

// --- CUSTOM FIELD CREATION SHEET ---
class _CreateFieldSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onFieldAdded;
  const _CreateFieldSheet({required this.onFieldAdded, Key? key})
      : super(key: key);

  @override
  State<_CreateFieldSheet> createState() => _CreateFieldSheetState();
}

class _CreateFieldSheetState extends State<_CreateFieldSheet> {
  final _labelController = TextEditingController();
  final _optionController = TextEditingController();
  String _selectedType = 'text';
  List<String> _dropdownOptions = [];

  void _addOption() {
    if (_optionController.text.trim().isNotEmpty) {
      setState(() {
        _dropdownOptions.add(_optionController.text.trim());
        _optionController.clear();
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        // Ensures the sheet rises above the mobile keyboard
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        // Added to prevent overflow on small screens
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Custom Field",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: "Field Label",
                hintText: "e.g. Lead Reference Number",
                labelStyle: const TextStyle(fontSize: 14),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF206C5E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Input Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'text', child: Text("Text Input")),
                DropdownMenuItem(value: 'number', child: Text("Number Only")),
                DropdownMenuItem(value: 'date', child: Text("Date Picker")),
                DropdownMenuItem(
                    value: 'dropdown', child: Text("Dropdown Menu")),
                DropdownMenuItem(value: 'image', child: Text("Image Upload")),
                DropdownMenuItem(
                    value: 'file', child: Text("File Upload (PDF/Doc)")),
              ],
              onChanged: (v) => setState(() {
                _selectedType = v!;
                if (_selectedType != 'dropdown') _dropdownOptions.clear();
              }),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // --- DYNAMIC DROPDOWN OPTIONS SECTION ---
            if (_selectedType == 'dropdown') ...[
              const SizedBox(height: 20),
              const Text(
                "Dropdown Options",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _optionController,
                      decoration: InputDecoration(
                        hintText: "Enter an option...",
                        hintStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF206C5E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _dropdownOptions.map((opt) {
                  return Chip(
                    label: Text(opt, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.cancel, size: 16),
                    onDeleted: () =>
                        setState(() => _dropdownOptions.remove(opt)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF206C5E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_labelController.text.isNotEmpty) {
                    if (_selectedType == 'dropdown' &&
                        _dropdownOptions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Please add at least one option for the dropdown")),
                      );
                      return;
                    }

                    widget.onFieldAdded({
                      'label': _labelController.text,
                      'type': _selectedType,
                      'is_required': true,
                      'is_removable': true,
                      'options': _dropdownOptions,
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Add to Template",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12), // Extra padding for bottom safety
          ],
        ),
      ),
    );
  }
}
