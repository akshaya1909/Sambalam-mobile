import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/attendance_kiosk_api_service.dart';
import '../../../../models/attendance_kiosk_model.dart';
import '../../../../models/branch_model.dart';

class AttendanceKioskScreen extends StatefulWidget {
  const AttendanceKioskScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceKioskScreen> createState() => _AttendanceKioskScreenState();
}

class _AttendanceKioskScreenState extends State<AttendanceKioskScreen> {
  final AttendanceKioskApiService _api = AttendanceKioskApiService();

  List<AttendanceKiosk> _kiosks = [];
  List<Branch> _allBranches = [];
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
      await Future.wait([
        _fetchKiosks(),
        _fetchBranches(),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchKiosks() async {
    try {
      final list = await _api.getCompanyKiosks(_companyId!);
      if (mounted) setState(() => _kiosks = list);
    } catch (e) {
      _showSnack('Failed to load kiosks', isError: true);
    }
  }

  Future<void> _fetchBranches() async {
    try {
      final list = await _api.getBranches(_companyId!);
      if (mounted) setState(() => _allBranches = list);
    } catch (e) {
      // Silent fail okay for dropdown
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Kiosk'),
        content: const Text('Are you sure you want to delete this kiosk?'),
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
        await _api.deleteKiosk(id);
        _showSnack('Kiosk deleted');
        _fetchKiosks();
      } catch (e) {
        _showSnack('Failed to delete kiosk', isError: true);
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

  void _openKioskForm({AttendanceKiosk? kiosk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _KioskFormDialog(
        companyId: _companyId!,
        existingKiosk: kiosk,
        branches: _allBranches,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchKiosks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFFF97316); // Orange

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
          'Attendance Kiosk',
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
                const Text('Kiosk Devices',
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
                  onPressed: () => _openKioskForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Kiosk'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED), // Light Orange
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Text(
                'Setup Guide: Register your kiosk device here, then login on the tablet app using the Device ID (Phone Number).',
                style: TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
              ),
            ),
            const SizedBox(height: 16),

            // List
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kiosks.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _kiosks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _KioskCard(
                            kiosk: _kiosks[index],
                            onEdit: () => _openKioskForm(kiosk: _kiosks[index]),
                            onDelete: () => _handleDelete(_kiosks[index].id),
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
          Icon(Icons.storefront_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No kiosks registered',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Kiosk Card ---

class _KioskCard extends StatelessWidget {
  final AttendanceKiosk kiosk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KioskCard({
    Key? key,
    required this.kiosk,
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
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.storefront,
                      color: Color(0xFFF97316), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              kiosk.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dummy Status (assuming online for demo, logic can be added later)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Text('Online',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Branch Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: kiosk.branchNames.isNotEmpty
                            ? kiosk.branchNames
                                .map((name) => _branchChip(name))
                                .toList()
                            : [_branchChip('All Branches')],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${kiosk.dialCode} ${kiosk.phone} • Mode: Face Recognition',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(40, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon:
                      const Icon(Icons.settings, size: 16, color: Colors.grey),
                  label: const Text('Configure',
                      style: TextStyle(color: Colors.black87, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(40, 36),
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _branchChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
      ),
    );
  }
}

// --- WIDGET: Add/Edit Dialog ---

class _KioskFormDialog extends StatefulWidget {
  final String companyId;
  final AttendanceKiosk? existingKiosk;
  final List<Branch> branches;
  final AttendanceKioskApiService api;
  final VoidCallback onSuccess;

  const _KioskFormDialog({
    Key? key,
    required this.companyId,
    this.existingKiosk,
    required this.branches,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_KioskFormDialog> createState() => _KioskFormDialogState();
}

class _KioskFormDialogState extends State<_KioskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  String _dialCode = '+91';
  List<String> _selectedBranchIds = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingKiosk?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existingKiosk?.phone ?? '');

    if (widget.existingKiosk != null) {
      _dialCode = widget.existingKiosk!.dialCode;
      _selectedBranchIds = List.from(widget.existingKiosk!.branchIds);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'dialCode': _dialCode,
      'phoneNumber': _phoneCtrl.text.trim(), // API expects phoneNumber
      'branchIds': _selectedBranchIds,
    };

    try {
      if (widget.existingKiosk == null) {
        await widget.api.createKiosk(widget.companyId, data);
      } else {
        await widget.api.updateKiosk(widget.existingKiosk!.id, data);
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiosk saved successfully')),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingKiosk == null ? 'Register Kiosk' : 'Edit Kiosk',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLabel('Kiosk Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Lobby Tablet'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone Number Row
                    _buildLabel('Device Phone Number *'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dial Code Dropdown (Simulated with Container for now)
                        Container(
                          width: 80,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFF9FAFB),
                          ),
                          alignment: Alignment.center,
                          child: const Text('+91',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: _inputDecoration('Enter Number')
                                .copyWith(counterText: ""),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length != 10) return 'Invalid Number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _buildLabel('Branches (Select multiple)'),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: widget.branches.isEmpty
                          ? const Center(
                              child: Text('No branches available',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: widget.branches.length,
                              itemBuilder: (ctx, idx) {
                                final b = widget.branches[idx];
                                final isSelected =
                                    _selectedBranchIds.contains(b.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  activeColor:
                                      const Color(0xFFF97316), // Orange
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(b.name,
                                      style: const TextStyle(fontSize: 13)),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedBranchIds.add(b.id);
                                      } else {
                                        _selectedBranchIds.remove(b.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Static Mode Display
                    _buildLabel('Authentication Mode'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Face Recognition',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      backgroundColor: const Color(0xFFF97316),
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
