import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/work_report_api_service.dart';

class ReportFormScreen extends StatefulWidget {
  final dynamic template;
  final String employeeId;
  final String companyId;
  final DateTime date;
  final List<dynamic>? initialEntries;

  const ReportFormScreen({
    Key? key,
    required this.template,
    required this.employeeId,
    required this.companyId,
    required this.date,
    this.initialEntries,
  }) : super(key: key);

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final WorkReportApiService _api = WorkReportApiService();
  final Map<String, dynamic> _formData = {};
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int? _editingIndex;

  // Track values for the CURRENT entry being typed
  final Map<String, dynamic> _currentEntryData = {};

  // List to store completed entries before final submission
  final List<Map<String, dynamic>> _allEntries = [];

  // Modern Color Palette
  final Color primaryGreen = const Color(0xFF059669);
  final Color accentSlate = const Color(0xFF1E293B);
  final Color bgSurface = const Color(0xFFF8FAFC);
  final Color errorRed = const Color(0xFFE11D48);

  @override
  void initState() {
    super.initState();
    // PREFILL LOGIC
    if (widget.initialEntries != null) {
      for (var entry in widget.initialEntries!) {
        Map<String, dynamic> mappedData = {};
        for (var dataObj in entry['data']) {
          String label = dataObj['fieldLabel'];
          dynamic val = dataObj['value'];

          // Convert back to DateTime if it's a date field
          if (val is String && val.contains('T')) {
            mappedData[label] = DateTime.tryParse(val) ?? val;
          } else {
            mappedData[label] = val;
          }
        }
        _allEntries.add(mappedData);
      }
    }
  }

  void _editEntry(int index) {
    setState(() {
      _editingIndex = index;
      _formData.clear();

      // Create a copy of the entry
      Map<String, dynamic> entryToEdit =
          Map<String, dynamic>.from(_allEntries[index]);

      // Important: Convert ISO Strings back to DateTime objects so the UI works
      entryToEdit.forEach((key, value) {
        // Check if the value looks like an ISO date string
        if (value is String && value.contains('T') && value.length >= 10) {
          try {
            entryToEdit[key] = DateTime.parse(value);
          } catch (_) {
            // Keep as string if parsing fails
          }
        }
      });

      _formData.addAll(entryToEdit);
    });
  }

  void _addEntryToList() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_editingIndex != null) {
          // UPDATE existing entry
          _allEntries[_editingIndex!] = Map<String, dynamic>.from(_formData);
          _editingIndex = null;
        } else {
          // ADD NEW entry
          _allEntries.add(Map<String, dynamic>.from(_formData));
        }

        // RESET form for next entry
        _formData.clear();
        _formKey.currentState!.reset();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_editingIndex != null ? "Entry Updated" : "Entry Added")),
      );
    }
  }

  void _showExcelPreview(BuildContext context) {
    final fields = widget.template['fields'] as List;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                      backgroundColor: primaryGreen.withOpacity(0.1),
                      child: Icon(Icons.table_chart_outlined,
                          color: primaryGreen)),
                  const SizedBox(width: 12),
                  const Text("Report Preview",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close))
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(bgSurface),
                      columnSpacing: 24,
                      border: TableBorder.all(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8)),
                      columns: fields
                          .map((f) => DataColumn(
                              label: Text(f['label'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                      fontSize: 12))))
                          .toList(),
                      rows: _allEntries
                          .map((entry) => DataRow(
                                  cells: fields.map((f) {
                                // Get the label defined in the template
                                String fieldLabel = f['label'];
                                // Look up the value in the entry map using that label
                                var val = entry[fieldLabel];

                                return DataCell(
                                  Text(
                                    val == null || val.toString().isEmpty
                                        ? "-"
                                        : (val is DateTime
                                            ? DateFormat('dd/MM/yy').format(val)
                                            : val.toString()),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList()))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFinalSubmit() async {
    if (_allEntries.isEmpty) {
      _formKey.currentState!.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one entry first.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      for (var entryMap in _allEntries) {
        // FIX: Map the entryMap (which contains your form data) to the required 'data' format
        final processedData = entryMap.entries.map((e) {
          dynamic val = e.value;
          return {
            "fieldLabel": e.key,
            "value": val is DateTime ? val.toIso8601String() : val,
          };
        }).toList();

        // Call API for each individual entry
        bool success = await _api.submitReport({
          "companyId": widget.companyId,
          "employeeId": widget.employeeId,
          "templateId": widget.template['_id'],
          "date": DateFormat('yyyy-MM-dd').format(widget.date),
          "data": processedData // This matches your backend req.body.data
        });

        if (!success) throw Exception("Failed to submit one of the entries");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("All reports submitted successfully"),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.template['fields'] as List;

    return Scaffold(
      backgroundColor: bgSurface,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- ELEGANT SLIVER APP BAR ---
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    leadingWidth: 40,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: accentSlate, size: 17),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(
                          left: 56, right: 20, bottom: 16),
                      centerTitle: false,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              widget.template['title'] ?? "Daily Report",
                              style: TextStyle(
                                  color: accentSlate,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('EEEE,').format(widget.date),
                                style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3),
                              ),
                              Text(
                                DateFormat('MMM dd yyyy').format(widget.date),
                                style: TextStyle(
                                    color: accentSlate.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- ENTRY COUNT HEADER ---
                  if (_allEntries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildEntryCountHeader(),
                    ),

                  // --- FORM FIELDS LIST ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildAnimatedField(fields[index], index),
                        childCount: fields.length,
                      ),
                    ),
                  ),

                  // --- ADD ENTRY BUTTON (Integrated into single scroll) ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    sliver: SliverToBoxAdapter(
                      child: OutlinedButton.icon(
                        onPressed: _addEntryToList,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(_editingIndex != null
                            ? "UPDATE THIS ENTRY"
                            : "ADD THIS ENTRY"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: BorderSide(color: primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer stays fixed at bottom
            _buildElegantFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCountHeader() {
    if (_allEntries.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryGreen.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: accentSlate.withOpacity(0.02), blurRadius: 10)
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: primaryGreen, size: 20),
              const SizedBox(width: 10),
              Text("${_allEntries.length} Entries Added",
                  style: TextStyle(
                      color: accentSlate, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showExcelPreview(context),
                icon: Icon(Icons.remove_red_eye_outlined,
                    size: 16, color: primaryGreen),
                label: Text("Review All",
                    style: TextStyle(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Divider(
              height: 20,
              thickness: 0.5,
              color: Color.fromARGB(255, 190, 197, 206)),
          // List of small chips representing added entries
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _allEntries.asMap().entries.map((entry) {
              int idx = entry.key;
              bool isEditing = _editingIndex == idx;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isEditing ? primaryGreen.withOpacity(0.1) : bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEditing ? primaryGreen : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min, // Prevents the row from expanding
                  children: [
                    Text(
                      "Entry ${idx + 1}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isEditing ? primaryGreen : accentSlate,
                      ),
                    ),
                    const SizedBox(
                        width: 4), // Small gap between text and icons
                    // EDIT BUTTON
                    IconButton(
                      visualDensity:
                          VisualDensity.compact, // Shrinks the button size
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(), // Removes default 48px padding
                      icon: Icon(Icons.edit_rounded,
                          size: 16, color: accentSlate.withOpacity(0.6)),
                      onPressed: () => _editEntry(idx),
                    ),
                    const SizedBox(
                        width: 10), // Precise small gap between the two icons
                    // DELETE BUTTON
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.redAccent),
                      onPressed: () => setState(() {
                        _allEntries.removeAt(idx);
                        if (_editingIndex == idx) _editingIndex = null;
                      }),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _entryActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.transparent,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildAnimatedField(dynamic field, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accentSlate.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field['label'],
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: accentSlate.withOpacity(0.8)),
              ),
              if (field['isRequired'] ?? true)
                Text(" *",
                    style: TextStyle(
                        color: errorRed, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _generateInputWidget(field),
        ],
      ),
    );
  }

  Widget _generateInputWidget(dynamic field) {
    final String type = field['fieldType'];
    final String label = field['label'];
    final bool isReq = field['isRequired'] ?? true;

    if (type == 'dropdown') {
      return DropdownButtonFormField<String>(
        key: ValueKey("${_editingIndex ?? 'new'}_$label"),
        value: _formData[label],
        style: TextStyle(
            color: accentSlate, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: _inputDecoration(Icons.arrow_drop_down_circle_outlined),
        items: (field['options'] as List)
            .map((opt) => DropdownMenuItem(
                value: opt.toString(), child: Text(opt.toString())))
            .toList(),
        onChanged: (val) => _formData[label] = val,
        validator:
            isReq ? (v) => v == null ? "Please select $label" : null : null,
      );
    }

    if (type == 'date') {
      // Use DateFormat to show a clean date instead of the raw string with time
      String displayDate = "";
      if (_formData[label] != null) {
        if (_formData[label] is DateTime) {
          displayDate = DateFormat('dd/MM/yyyy').format(_formData[label]);
        } else {
          // If it's already a string (from prefill), parse and format it
          displayDate = DateFormat('dd/MM/yyyy')
              .format(DateTime.parse(_formData[label].toString()));
        }
      }

      return TextFormField(
        readOnly: true,
        // Use Key to force the UI to refresh when the value changes
        key: ValueKey(_formData[label]),
        controller: TextEditingController(text: displayDate),
        decoration: _inputDecoration(Icons.calendar_today_rounded),
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _formData[label] is DateTime
                ? _formData[label]
                : DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(primary: primaryGreen)),
              child: child!,
            ),
          );
          if (picked != null) {
            setState(() => _formData[label] = picked);
          }
        },
        validator: isReq
            ? (v) => (displayDate.isEmpty) ? "Date is required" : null
            : null,
      );
    }

    if (type == 'file' || type == 'image') {
      return _buildFilePicker(label, isReq);
    }

    // Default Text / Number
    return TextFormField(
      key: ValueKey("${_editingIndex ?? 'new'}_$label"),
      initialValue: _formData[label]?.toString() ?? "",
      keyboardType:
          type == 'number' ? TextInputType.number : TextInputType.multiline,
      maxLines: label.toLowerCase().contains("summary") ? 4 : 1,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _inputDecoration(
          type == 'number' ? Icons.pin_rounded : Icons.edit_note_rounded),
      onChanged: (val) => _formData[label] = val,
      validator: (v) {
        if (isReq && (v == null || v.isEmpty)) return "This field is required";
        if (type == 'number' &&
            v != null &&
            v.isNotEmpty &&
            double.tryParse(v) == null) return "Enter a valid number";
        return null;
      },
    );
  }

  Widget _buildFilePicker(String label, bool isReq) {
    bool hasFile = _formData[label] != null;
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result != null) {
          if (result.files.single.size > 10 * 1024 * 1024) {
            // 10MB Check
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  backgroundColor: errorRed,
                  content: const Text("File size exceeds 10MB limit")),
            );
          } else {
            setState(() => _formData[label] = result.files.single.name);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: primaryGreen.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: hasFile ? primaryGreen : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasFile ? _formData[label] : "Tap to upload (Max 10MB)",
                style: TextStyle(
                    color: hasFile ? accentSlate : Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasFile)
              IconButton(
                  onPressed: () => setState(() => _formData.remove(label)),
                  icon: const Icon(Icons.cancel, size: 20))
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
      filled: true,
      fillColor: bgSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.5)),
    );
  }

  Widget _buildElegantFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: [primaryGreen, const Color(0xFF10B981)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18))),
            onPressed: _isSubmitting ? null : _handleFinalSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text("SUBMIT REPORT",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Convert the map entries while handling DateTime objects
      final processedData = _formData.entries.map((e) {
        dynamic value = e.value;

        // FIX: Convert DateTime instances to String before encoding
        if (value is DateTime) {
          value = value.toIso8601String();
        }

        return {
          "fieldLabel": e.key,
          "value": value,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        "companyId": widget.companyId,
        "employeeId": widget.employeeId,
        "templateId": widget.template['_id'],
        "date": DateFormat('yyyy-MM-dd').format(widget.date),
        "data": processedData
      };

      bool success = await _api.submitReport(payload);

      setState(() => _isSubmitting = false);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Report Submitted Successfully")));
        Navigator.pop(context, true);
      }
    }
  }
}
