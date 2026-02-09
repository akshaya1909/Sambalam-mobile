import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../api/custom_field_api_service.dart';
import '../../../api/employee_api_service.dart'; // For fetching profile
import '../../../models/custom_field_model.dart';

class CustomDetailsScreen extends StatefulWidget {
  final String employeeId;
  final String companyId;

  const CustomDetailsScreen({
    Key? key,
    required this.employeeId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CustomDetailsScreen> createState() => _CustomDetailsScreenState();
}

class _CustomDetailsScreenState extends State<CustomDetailsScreen> {
  final _customApi = CustomFieldApiService();
  final _employeeApi = EmployeeApiService();

  bool _isLoading = true;
  List<CustomField> _fieldDefinitions = [];
  Map<String, String> _currentValues = {}; // fieldId -> value
  Map<String, String> _newValues = {}; // fieldId -> value (only for edits)

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch Company Field Definitions
      final fields = await _customApi.getCustomFields(widget.companyId);

      // 2. Fetch Employee's Current Values
      final profile = await _employeeApi.getEmployeeProfileById(
          employeeId: widget.employeeId);
      final List<dynamic> savedValues = profile['customFieldValues'] ?? [];

      // Map saved values for easy lookup
      final Map<String, String> valueMap = {};
      for (var item in savedValues) {
        if (item['customField'] != null) {
          valueMap[item['customField']] = item['value'].toString();
        }
      }

      if (mounted) {
        setState(() {
          _fieldDefinitions = fields;
          _currentValues = valueMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading custom details: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_newValues.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Combine existing locked values with new values
      final List<Map<String, dynamic>> payload = [];

      // Add existing (locked) values
      _currentValues.forEach((key, value) {
        payload.add({'customField': key, 'value': value});
      });

      // Add/Overwrite with new values
      _newValues.forEach((key, value) {
        // Remove old entry if exists to avoid duplicates (though map handles it logic-wise)
        payload.removeWhere((element) => element['customField'] == key);
        payload.add({'customField': key, 'value': value});
      });

      await _customApi.updateEmployeeCustomValues(
        employeeId: widget.employeeId,
        values: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom details updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4F46E5);
    const Color bg = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Custom Details',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fieldDefinitions.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Information',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fields with existing values are locked.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ..._fieldDefinitions
                                .map((field) => _buildFieldInput(field)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: !_isLoading && _fieldDefinitions.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _newValues.isNotEmpty && !_isSaving
                        ? _saveChanges
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Save Changes',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFieldInput(CustomField field) {
    final bool hasValue = _currentValues.containsKey(field.id) &&
        _currentValues[field.id]!.isNotEmpty;
    final String initialValue = _currentValues[field.id] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
              if (hasValue)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.lock, size: 14, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInputWidget(field, hasValue, initialValue),
        ],
      ),
    );
  }

  Widget _buildInputWidget(
      CustomField field, bool isLocked, String initialValue) {
    // If locked, show disabled input styling
    if (isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Grey bg
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          field.type == 'date'
              ? DateFormat('dd MMM yyyy')
                  .format(DateTime.tryParse(initialValue) ?? DateTime.now())
              : initialValue,
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
      );
    }

    // --- EDITABLE WIDGETS ---

    // 1. DROPDOWN
    if (field.type == 'dropdown') {
      return DropdownButtonFormField<String>(
        decoration: _inputDecoration(field.placeholder),
        items: field.options.map((opt) {
          return DropdownMenuItem(value: opt, child: Text(opt));
        }).toList(),
        onChanged: (val) {
          setState(() => _newValues[field.id] = val!);
        },
      );
    }

    // 2. DATE PICKER
    if (field.type == 'date') {
      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _newValues[field.id] = picked.toIso8601String();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _newValues[field.id] != null
                    ? DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(_newValues[field.id]!))
                    : 'Select Date',
                style: GoogleFonts.inter(
                  color: _newValues[field.id] != null
                      ? Colors.black87
                      : Colors.grey,
                ),
              ),
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // 3. TEXT / NUMBER INPUT
    return TextFormField(
      initialValue: _newValues[field.id], // Keeps state if widget rebuilds
      keyboardType:
          field.type == 'number' ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(field.placeholder),
      onChanged: (val) {
        _newValues[field.id] = val;
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint.isNotEmpty ? hint : 'Enter value',
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F46E5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Custom Fields',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask admin to add custom fields in settings.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
