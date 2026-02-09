import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/incentive_api_service.dart';
import '../../../../models/incentive_type_model.dart';

class ManageIncentivesScreen extends StatefulWidget {
  const ManageIncentivesScreen({Key? key}) : super(key: key);

  @override
  State<ManageIncentivesScreen> createState() => _ManageIncentivesScreenState();
}

class _ManageIncentivesScreenState extends State<ManageIncentivesScreen> {
  final IncentiveApiService _api = IncentiveApiService();
  List<IncentiveType> _incentives = [];
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
      _fetchIncentives();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIncentives() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getIncentives(_companyId!);
      if (mounted) {
        setState(() {
          _incentives = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load data', isError: true);
      }
    }
  }

  // --- ACTIONS ---

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Incentive Type'),
        content: const Text('Are you sure you want to delete this?'),
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
        await _api.deleteIncentive(id);
        _showSnack('Incentive type deleted');
        _fetchIncentives();
      } catch (e) {
        _showSnack('Failed to delete', isError: true);
      }
    }
  }

  Future<void> _toggleActive(IncentiveType item, bool newVal) async {
    // Optimistic update logic could be added here, but for safety we await API
    try {
      await _api.updateIncentive(item.id, {'isActive': newVal});
      _showSnack('Status updated');
      _fetchIncentives();
    } catch (e) {
      _showSnack('Failed to update status', isError: true);
    }
  }

  void _openFormDialog({IncentiveType? item}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IncentiveFormDialog(
        companyId: _companyId!,
        existingItem: item,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchIncentives();
        },
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF206C5E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFF206C5E);

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
          'Incentive Types',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormDialog(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Type'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incentives.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incentives.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _incentives[index];
                    return _IncentiveCard(
                      item: item,
                      onEdit: () => _openFormDialog(item: item),
                      onDelete: () => _handleDelete(item.id),
                      onToggle: (val) => _toggleActive(item, val),
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
          Icon(Icons.card_giftcard, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No incentive types found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Incentive Card ---

class _IncentiveCard extends StatelessWidget {
  final IncentiveType item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _IncentiveCard({
    Key? key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Style based on active status
    final double opacity = item.isActive ? 1.0 : 0.6;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: opacity,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Box
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // Light Green
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monetization_on_outlined,
                        color: Color(0xFF166534)),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Taxable Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isTaxable
                                    ? const Color(0xFFFFF7ED) // Orange
                                    : const Color(0xFFDCFCE7), // Green
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isTaxable ? 'Taxable' : 'Non-Taxable',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.isTaxable
                                      ? const Color(0xFFC2410C)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description.isNotEmpty
                              ? item.description
                              : 'No description provided',
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active Toggle
                  Row(
                    children: [
                      Text(item.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey)),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: item.isActive,
                          activeColor: const Color(0xFF206C5E),
                          onChanged: onToggle,
                        ),
                      ),
                    ],
                  ),
                  // Actions
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: Colors.grey),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET: Form Dialog ---

class _IncentiveFormDialog extends StatefulWidget {
  final String companyId;
  final IncentiveType? existingItem;
  final IncentiveApiService api;
  final VoidCallback onSuccess;

  const _IncentiveFormDialog({
    Key? key,
    required this.companyId,
    this.existingItem,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_IncentiveFormDialog> createState() => _IncentiveFormDialogState();
}

class _IncentiveFormDialogState extends State<_IncentiveFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  bool _isTaxable = true;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingItem?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existingItem?.description ?? '');
    if (widget.existingItem != null) {
      _isTaxable = widget.existingItem!.isTaxable;
      _isActive = widget.existingItem!.isActive;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'isTaxable': _isTaxable,
      'isActive': _isActive,
    };

    try {
      if (widget.existingItem == null) {
        await widget.api.createIncentive(widget.companyId, data);
      } else {
        await widget.api.updateIncentive(widget.existingItem!.id, data);
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
    // Scrollable Dialog for responsiveness
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingItem == null
                    ? 'Add Incentive Type'
                    : 'Edit Incentive Type',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLabel('Incentive Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Quarterly Bonus'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecoration('Brief description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Switches Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Is Taxable?',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Switch(
                          value: _isTaxable,
                          activeColor: const Color(0xFF206C5E),
                          onChanged: (val) => setState(() => _isTaxable = val),
                        ),
                      ],
                    ),
                    if (widget.existingItem != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Active Status',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Switch(
                            value: _isActive,
                            activeColor: const Color(0xFF206C5E),
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
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
                      backgroundColor: const Color(0xFF206C5E),
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
