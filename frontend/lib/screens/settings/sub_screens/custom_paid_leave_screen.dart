import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/leave_type_api_service.dart';
import '../../../../models/leave_type_model.dart';

class CustomPaidLeaveScreen extends StatefulWidget {
  const CustomPaidLeaveScreen({Key? key}) : super(key: key);

  @override
  State<CustomPaidLeaveScreen> createState() => _CustomPaidLeaveScreenState();
}

class _CustomPaidLeaveScreenState extends State<CustomPaidLeaveScreen> {
  final LeaveTypeApiService _api = LeaveTypeApiService();

  List<LeaveType> _leaveTypes = [];
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
      _fetchLeaveTypes();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLeaveTypes() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getLeaveTypes(_companyId!);
      if (mounted) {
        setState(() {
          _leaveTypes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load leave types', isError: true);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Leave Type'),
        content: const Text('Are you sure you want to delete this leave type?'),
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
        await _api.deleteLeaveType(id);
        _showSnack('Leave type deleted');
        _fetchLeaveTypes();
      } catch (e) {
        _showSnack('Failed to delete leave type', isError: true);
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

  void _openLeaveForm({LeaveType? leaveType}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _LeaveTypeFormDialog(
        companyId: _companyId!,
        existingLeave: leaveType,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchLeaveTypes();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFF8B5CF6); // Violet

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
          'Custom Paid Leaves',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Leave Types',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openLeaveForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Leave Type'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _leaveTypes.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaveTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _LeaveTypeCard(
                            leaveType: _leaveTypes[index],
                            onEdit: () =>
                                _openLeaveForm(leaveType: _leaveTypes[index]),
                            onDelete: () =>
                                _handleDelete(_leaveTypes[index].id),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 40),
          Icon(Icons.event_available, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No leave types configured',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Add leave types to manage employee leave policies.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Leave Type Card ---

class _LeaveTypeCard extends StatelessWidget {
  final LeaveType leaveType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LeaveTypeCard({
    Key? key,
    required this.leaveType,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          leaveType.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7), // Green bg
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF15803D), // Green text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF206C5E)),
                      SizedBox(width: 4),
                      Text('Active',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: Colors.grey),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: Add/Edit Dialog ---

class _LeaveTypeFormDialog extends StatefulWidget {
  final String companyId;
  final LeaveType? existingLeave;
  final LeaveTypeApiService api;
  final VoidCallback onSuccess;

  const _LeaveTypeFormDialog({
    Key? key,
    required this.companyId,
    this.existingLeave,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_LeaveTypeFormDialog> createState() => _LeaveTypeFormDialogState();
}

class _LeaveTypeFormDialogState extends State<_LeaveTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingLeave?.name ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.existingLeave == null) {
        await widget.api
            .createLeaveType(widget.companyId, _nameCtrl.text.trim());
      } else {
        await widget.api
            .updateLeaveType(widget.existingLeave!.id, _nameCtrl.text.trim());
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '')),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingLeave == null
                  ? 'Add New Leave Type'
                  : 'Edit Leave Type',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildLabel('Leave Type Name *'),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration('e.g. Casual Leave'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6), // Violet
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
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
