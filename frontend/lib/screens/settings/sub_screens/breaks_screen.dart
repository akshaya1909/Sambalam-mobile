import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/break_api_service.dart';
import '../../../../models/break_model.dart';

class BreaksScreen extends StatefulWidget {
  const BreaksScreen({Key? key}) : super(key: key);

  @override
  State<BreaksScreen> createState() => _BreaksScreenState();
}

class _BreaksScreenState extends State<BreaksScreen> {
  final BreakApiService _api = BreakApiService();
  List<CompanyBreak> _breaks = [];
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
      _fetchBreaks();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBreaks() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCompanyBreaks(_companyId!);
      if (mounted) {
        setState(() {
          _breaks = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load breaks', isError: true);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Break'),
        content: const Text('Are you sure you want to delete this break?'),
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
        await _api.deleteBreak(id);
        _showSnack('Break deleted');
        _fetchBreaks();
      } catch (e) {
        _showSnack('Failed to delete break', isError: true);
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

  void _openBreakForm({CompanyBreak? breakItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BreakFormSheet(
        companyId: _companyId!,
        existingBreak: breakItem,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchBreaks();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFFA855F7); // Purple for Breaks

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
          'Breaks',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBreakForm(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Break'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _breaks.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _breaks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _breaks[index];
                    return _BreakCard(
                      breakItem: item,
                      onEdit: () => _openBreakForm(breakItem: item),
                      onDelete: () => _handleDelete(item.id),
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
          Icon(Icons.coffee_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No breaks added yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Break Card ---

class _BreakCard extends StatelessWidget {
  final CompanyBreak breakItem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BreakCard({
    Key? key,
    required this.breakItem,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPaid = breakItem.type == 'Paid';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF), // Light Purple
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.coffee, color: Color(0xFFA855F7), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breakItem.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          breakItem.type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? const Color(0xFF166534)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      if (isPaid) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${breakItem.durationHours}h ${breakItem.durationMinutes}m',
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: Add/Edit Form Sheet ---

class _BreakFormSheet extends StatefulWidget {
  final String companyId;
  final CompanyBreak? existingBreak;
  final BreakApiService api;
  final VoidCallback onSuccess;

  const _BreakFormSheet({
    Key? key,
    required this.companyId,
    this.existingBreak,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_BreakFormSheet> createState() => _BreakFormSheetState();
}

class _BreakFormSheetState extends State<_BreakFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  // Type
  String _type = 'Unpaid'; // Default

  // Duration
  final TextEditingController _hrsCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingBreak?.name ?? '');

    if (widget.existingBreak != null) {
      _type = widget.existingBreak!.type;
      _hrsCtrl.text = widget.existingBreak!.durationHours > 0
          ? widget.existingBreak!.durationHours.toString()
          : '';
      _minCtrl.text = widget.existingBreak!.durationMinutes > 0
          ? widget.existingBreak!.durationMinutes.toString()
          : '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'durationHours': _type == 'Paid' ? (int.tryParse(_hrsCtrl.text) ?? 0) : 0,
      'durationMinutes':
          _type == 'Paid' ? (int.tryParse(_minCtrl.text) ?? 0) : 0,
    };

    try {
      if (widget.existingBreak == null) {
        await widget.api.createBreak(widget.companyId, data);
      } else {
        await widget.api.updateBreak(widget.existingBreak!.id, data);
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break saved successfully')),
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
    const Color primary = Color(0xFFA855F7);

    return Container(
      height:
          MediaQuery.of(context).size.height * 0.75, // Shorter height needed
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
                widget.existingBreak == null ? 'Add Break' : 'Edit Break',
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
                    _buildLabel('Break Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Lunch Break'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // TYPE RADIO
                    _buildLabel('Break Type *'),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'Unpaid',
                            groupValue: _type,
                            activeColor: primary,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const Text('Unpaid'),
                          const SizedBox(width: 20),
                          Radio<String>(
                            value: 'Paid',
                            groupValue: _type,
                            activeColor: primary,
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                          const Text('Paid'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // DURATION (Only if Paid)
                    if (_type == 'Paid') ...[
                      _buildLabel('Duration *'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            _smallInput(_hrsCtrl, 'Hrs'),
                            const SizedBox(width: 8),
                            const Text('hours',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 16),
                            _smallInput(_minCtrl, 'Min'),
                            const SizedBox(width: 8),
                            const Text('minutes',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
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
                      widget.existingBreak == null
                          ? 'Create Break'
                          : 'Update Break',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _smallInput(TextEditingController ctrl, String hint) {
    return SizedBox(
      width: 60,
      height: 40,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
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
