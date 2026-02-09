import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/employee_service.dart';
import '../../api/custom_field_api_service.dart';
import '../../../models/custom_field_model.dart';

class CustomDetailsScreen extends StatefulWidget {
  final String employeeUserId;

  const CustomDetailsScreen({Key? key, required this.employeeUserId})
      : super(key: key);

  @override
  State<CustomDetailsScreen> createState() => _CustomDetailsScreenState();
}

class _CustomDetailsScreenState extends State<CustomDetailsScreen> {
  final CustomFieldApiService _customFieldApi = CustomFieldApiService();
  final EmployeeService _employeeService = EmployeeService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _employeeDbId; // Internal MongoDB _id

  List<CustomField> _availableFields = [];
  Map<String, dynamic> _values = {}; // fieldId -> value

  // Theme colors matching EditStaffScreen
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);
  final Color scaffoldBg = const Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getString('companyId') ?? "";

      final fields = await _customFieldApi.getCustomFields(companyId);

      final empData = await _employeeService.getEmployeeByUserId(
          widget.employeeUserId, companyId);

      // Internal MongoDB _id handling
      if (empData['_id'] is Map && empData['_id'].containsKey('\$oid')) {
        _employeeDbId = empData['_id']['\$oid'];
      } else {
        _employeeDbId = empData['_id'];
      }

      final List<dynamic> currentValues = empData['customFieldValues'] ?? [];
      final Map<String, dynamic> mappedValues = {};
      for (var item in currentValues) {
        String fId = "";
        if (item['customField'] is Map) {
          // Use \$oid to escape the dollar sign
          fId =
              item['customField']['_id'] ?? item['customField']['\$oid'] ?? "";
        } else {
          fId = item['customField'].toString();
        }
        mappedValues[fId] = item['value'];
      }

      setState(() {
        _availableFields = fields;
        _values = mappedValues;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_employeeDbId == null) return;
    setState(() => _isSaving = true);

    try {
      final payload = _values.entries
          .map((e) => {"customField": e.key, "value": e.value.toString()})
          .toList();

      await _customFieldApi.updateEmployeeCustomValues(
        employeeId: _employeeDbId!,
        values: payload,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Custom details updated!"),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Custom Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryDeepTeal, secondaryTeal]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDeepTeal))
          : _availableFields.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10)
                          ],
                        ),
                        child: Column(
                          children: _availableFields
                              .map((field) => _buildDynamicField(field))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFieldDialog(),
        label: const Text("Add New Field"),
        icon: const Icon(Icons.add),
        backgroundColor: secondaryTeal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("No custom fields defined",
              style: TextStyle(
                  color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Click 'Add New Field' to create one."),
        ],
      ),
    );
  }

  Widget _buildDynamicField(CustomField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.name,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInputByType(field),
        ],
      ),
    );
  }

  Widget _buildInputByType(CustomField field) {
    if (field.type == 'dropdown') {
      return DropdownButtonFormField<String>(
        value: field.options.contains(_values[field.id])
            ? _values[field.id]
            : null,
        decoration: _inputDecoration(),
        items: field.options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) => setState(() => _values[field.id] = val),
      );
    } else if (field.type == 'date') {
      return TextFormField(
        readOnly: true,
        controller: TextEditingController(text: _values[field.id] ?? ""),
        decoration: _inputDecoration()
            .copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 20)),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() =>
                _values[field.id] = DateFormat('yyyy-MM-dd').format(picked));
          }
        },
      );
    } else {
      return TextFormField(
        initialValue: _values[field.id]?.toString() ?? "",
        keyboardType:
            field.type == 'number' ? TextInputType.number : TextInputType.text,
        decoration:
            _inputDecoration().copyWith(hintText: "Enter ${field.name}"),
        onChanged: (val) => _values[field.id] = val,
      );
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryTeal, width: 2)),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryDeepTeal, secondaryTeal]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: secondaryTeal.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SAVE CUSTOM DETAILS",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
        ),
      ),
    );
  }

  void _showAddFieldDialog() {
    String name = "";
    String type = "text";
    List<String> options = [];
    TextEditingController optionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create New Field"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Field Name"),
                  onChanged: (v) => name = v,
                ),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: ["text", "number", "date", "dropdown"]
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                if (type == "dropdown") ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: optionCtrl,
                              decoration: const InputDecoration(
                                  hintText: "Add option"))),
                      IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            if (optionCtrl.text.isNotEmpty) {
                              setDialogState(
                                  () => options.add(optionCtrl.text.trim()));
                              optionCtrl.clear();
                            }
                          }),
                    ],
                  ),
                  Wrap(
                      children: options
                          .map((o) => Chip(
                              label: Text(o),
                              onDeleted: () =>
                                  setDialogState(() => options.remove(o))))
                          .toList()),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryDeepTeal),
              onPressed: () async {
                if (name.isEmpty) return;
                final prefs = await SharedPreferences.getInstance();
                final companyId = prefs.getString('companyId') ?? "";
                await _customFieldApi.createCustomField(companyId, {
                  "name": name,
                  "type": type,
                  "options": options,
                });
                Navigator.pop(context);
                _loadData(); // Refresh list
              },
              child: const Text("Create"),
            )
          ],
        ),
      ),
    );
  }
}
