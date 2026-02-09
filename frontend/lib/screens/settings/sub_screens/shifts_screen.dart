import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/shift_api_service.dart';
import '../../../../models/shift_model.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({Key? key}) : super(key: key);

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftApiService _api = ShiftApiService();
  List<Shift> _shifts = [];
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
      _fetchShifts();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchShifts() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCompanyShifts(_companyId!);
      if (mounted) {
        setState(() {
          _shifts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load shifts', isError: true);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteShift(id);
        _showSnack('Shift deleted');
        _fetchShifts();
      } catch (e) {
        _showSnack('Failed to delete shift', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF206C5E),
      ),
    );
  }

  void _openShiftForm({Shift? shift}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShiftFormSheet(
        companyId: _companyId!,
        existingShift: shift,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchShifts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFFF59E0B); // Amber for Shifts

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Shifts',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openShiftForm(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Shift'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shifts.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final shift = _shifts[index];
                    return _ShiftCard(
                      shift: shift,
                      onEdit: () => _openShiftForm(shift: shift),
                      onDelete: () => _handleDelete(shift.id),
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
          Icon(Icons.access_time, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No shifts found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Shift Card ---

class _ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftCard({
    Key? key,
    required this.shift,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Light Amber
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.access_time_filled,
                      color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shift.startTime} - ${shift.endTime}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: Colors.grey),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: Add/Edit Form Sheet ---

class _ShiftFormSheet extends StatefulWidget {
  final String companyId;
  final Shift? existingShift;
  final ShiftApiService api;
  final VoidCallback onSuccess;

  const _ShiftFormSheet({
    Key? key,
    required this.companyId,
    this.existingShift,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_ShiftFormSheet> createState() => _ShiftFormSheetState();
}

class _ShiftFormSheetState extends State<_ShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  // Time Strings
  String _startTime = "09:00 AM";
  String _endTime = "06:00 PM";

  // Rules
  String _punchInRule = "Anytime";
  String _punchOutRule = "Anytime";

  // Limits (Controllers for numbers)
  final TextEditingController _inHrsCtrl = TextEditingController();
  final TextEditingController _inMinCtrl = TextEditingController();
  final TextEditingController _outHrsCtrl = TextEditingController();
  final TextEditingController _outMinCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingShift?.name ?? '');

    if (widget.existingShift != null) {
      _startTime = widget.existingShift!.startTime;
      _endTime = widget.existingShift!.endTime;
      _punchInRule = widget.existingShift!.punchInRule;
      _punchOutRule = widget.existingShift!.punchOutRule;

      _inHrsCtrl.text = widget.existingShift!.punchInHours > 0
          ? widget.existingShift!.punchInHours.toString()
          : '';
      _inMinCtrl.text = widget.existingShift!.punchInMinutes > 0
          ? widget.existingShift!.punchInMinutes.toString()
          : '';
      _outHrsCtrl.text = widget.existingShift!.punchOutHours > 0
          ? widget.existingShift!.punchOutHours.toString()
          : '';
      _outMinCtrl.text = widget.existingShift!.punchOutMinutes > 0
          ? widget.existingShift!.punchOutMinutes.toString()
          : '';
    }
  }

  // --- TIME PICKER HELPER ---
  Future<void> _pickTime(bool isStart) async {
    // Parse current string "HH:MM AM" to TimeOfDay
    TimeOfDay initial = _parseTimeString(isStart ? _startTime : _endTime);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime =
              picked.format(context); // Returns localized string e.g. "9:00 AM"
        } else {
          _endTime = picked.format(context);
        }
      });
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      // Basic parser for "HH:MM AM" format if localization matches US
      // For robust parsing, use DateFormat from intl package, but TimeOfDay works for simple picker logic
      // Here we assume standard "9:00 AM" format
      final parts = timeStr.split(" ");
      final timeParts = parts[0].split(":");
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts[1] == "PM" && hour != 12) hour += 12;
      if (parts[1] == "AM" && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'startTime': _startTime,
      'endTime': _endTime,
      'punchInRule': _punchInRule,
      'punchOutRule': _punchOutRule,
      'punchInHours': int.tryParse(_inHrsCtrl.text) ?? 0,
      'punchInMinutes': int.tryParse(_inMinCtrl.text) ?? 0,
      'punchOutHours': int.tryParse(_outHrsCtrl.text) ?? 0,
      'punchOutMinutes': int.tryParse(_outMinCtrl.text) ?? 0,
    };

    try {
      if (widget.existingShift == null) {
        await widget.api.createShift(widget.companyId, data);
      } else {
        await widget.api.updateShift(widget.existingShift!.id, data);
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift saved successfully')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFF59E0B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingShift == null ? 'Add Shift' : 'Edit Shift',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    _buildLabel('Shift Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Morning Shift'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // TIME PICKERS
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Start Time *'),
                              GestureDetector(
                                onTap: () => _pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_startTime),
                                      const Icon(Icons.access_time,
                                          size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('End Time *'),
                              GestureDetector(
                                onTap: () => _pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_endTime),
                                      const Icon(Icons.access_time,
                                          size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // PUNCH IN RULE
                    _buildRuleSection(
                      title: 'Can Punch In',
                      groupValue: _punchInRule,
                      onChanged: (val) => setState(() => _punchInRule = val!),
                      limitHoursCtrl: _inHrsCtrl,
                      limitMinsCtrl: _inMinCtrl,
                      suffixText: 'before start',
                    ),

                    const SizedBox(height: 16),

                    // PUNCH OUT RULE
                    _buildRuleSection(
                      title: 'Can Punch Out',
                      groupValue: _punchOutRule,
                      onChanged: (val) => setState(() => _punchOutRule = val!),
                      limitHoursCtrl: _outHrsCtrl,
                      limitMinsCtrl: _outMinCtrl,
                      suffixText: 'after end',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      widget.existingShift == null
                          ? 'Create Shift'
                          : 'Update Shift',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildRuleSection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required TextEditingController limitHoursCtrl,
    required TextEditingController limitMinsCtrl,
    required String suffixText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Row(
            children: [
              Radio<String>(
                value: 'Anytime',
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: const Color(0xFFF59E0B),
              ),
              const Text('Anytime'),
              const SizedBox(width: 16),
              Radio<String>(
                value: 'Add Limit',
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: const Color(0xFFF59E0B),
              ),
              const Text('Add Limit'),
            ],
          ),
          if (groupValue == 'Add Limit') ...[
            const Divider(),
            Row(
              children: [
                const Text('Allow',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 8),
                _smallInput(limitHoursCtrl, 'Hrs'),
                const SizedBox(width: 4),
                const Text('hrs', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                _smallInput(limitMinsCtrl, 'Min'),
                const SizedBox(width: 4),
                Text('$suffixText',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _smallInput(TextEditingController ctrl, String hint) {
    return SizedBox(
      width: 50,
      height: 36,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
