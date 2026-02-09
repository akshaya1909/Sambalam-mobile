import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/custom_field_api_service.dart';
import '../../../../models/custom_field_model.dart';

class CustomFieldsScreen extends StatefulWidget {
  const CustomFieldsScreen({Key? key}) : super(key: key);

  @override
  State<CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<CustomFieldsScreen> {
  final CustomFieldApiService _api = CustomFieldApiService();
  List<CustomField> _fields = [];
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
      _fetchFields();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFields() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCustomFields(_companyId!);
      if (mounted) {
        setState(() {
          _fields = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load fields', isError: true);
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field'),
        content:
            const Text('Are you sure you want to delete this custom field?'),
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
        await _api.deleteCustomField(id);
        _showSnack('Field deleted');
        _fetchFields();
      } catch (e) {
        _showSnack('Failed to delete field', isError: true);
      }
    }
  }

  void _openFieldForm({CustomField? field}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CustomFieldFormDialog(
        companyId: _companyId!,
        existingField: field,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchFields();
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
    const Color primary = Color(0xFFEC4899); // Pink

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
          'Custom Fields',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFieldForm(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Field'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _fields.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    return _CustomFieldCard(
                      field: field,
                      onEdit: () => _openFieldForm(field: field),
                      onDelete: () => _handleDelete(field.id),
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
          Icon(Icons.edit_note_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No custom fields found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Add fields to capture extra employee data',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Custom Field Card ---

class _CustomFieldCard extends StatelessWidget {
  final CustomField field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomFieldCard({
    Key? key,
    required this.field,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3), // Light Pink
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_input_component,
                      color: Color(0xFFBE185D)), // Dark Pink
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
                              field.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (field.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '*Required',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${field.type.toUpperCase()} ${field.placeholder.isNotEmpty ? '• ${field.placeholder}' : ''}',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (field.type == 'dropdown' || field.type == 'checkbox')
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Options: ${field.options.join(", ")}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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

// --- WIDGET: Form Dialog (Responsive & Scrollable) ---

class _CustomFieldFormDialog extends StatefulWidget {
  final String companyId;
  final CustomField? existingField;
  final CustomFieldApiService api;
  final VoidCallback onSuccess;

  const _CustomFieldFormDialog({
    Key? key,
    required this.companyId,
    this.existingField,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_CustomFieldFormDialog> createState() => _CustomFieldFormDialogState();
}

class _CustomFieldFormDialogState extends State<_CustomFieldFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _optionInputCtrl;

  String _type = 'text';
  bool _isRequired = false;
  List<String> _options = [];
  bool _isSaving = false;

  final List<String> _fieldTypes = [
    'text',
    'number',
    'date',
    'dropdown',
    'checkbox'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingField?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existingField?.placeholder ?? '');
    _optionInputCtrl = TextEditingController();

    if (widget.existingField != null) {
      _type = widget.existingField!.type;
      _isRequired = widget.existingField!.isRequired;
      _options = List.from(widget.existingField!.options);
    }
  }

  void _addOption() {
    final text = _optionInputCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _options.add(text);
        _optionInputCtrl.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if ((_type == 'dropdown' || _type == 'checkbox') && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one option'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'isRequired': _isRequired,
      'placeholder': _descCtrl.text.trim(),
      'options': _options,
    };

    try {
      if (widget.existingField == null) {
        await widget.api.createCustomField(widget.companyId, data);
      } else {
        await widget.api.updateCustomField(widget.existingField!.id, data);
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field saved successfully')),
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
    // Scrollable Dialog with constraints to fit mobile screens properly
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.85, // Max 85% height
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingField == null
                    ? 'Add Custom Field'
                    : 'Edit Custom Field',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLabel('Field Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Laptop Serial'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildLabel('Field Type'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _type,
                          isExpanded: true,
                          items: _fieldTypes.map((t) {
                            return DropdownMenuItem(
                                value: t, child: Text(t.toUpperCase()));
                          }).toList(),
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // OPTIONS SECTION (Conditional)
                    if (_type == 'dropdown' || _type == 'checkbox') ...[
                      _buildLabel('Options (e.g. S, M, L, XL)'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _optionInputCtrl,
                                    decoration: _inputDecoration('Enter option')
                                        .copyWith(
                                            contentPadding:
                                                const EdgeInsets.all(10)),
                                    onSubmitted: (_) => _addOption(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addOption,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(
                                        color: Color(0xFFE5E7EB)),
                                    padding: const EdgeInsets.all(
                                        12), // Square-ish button
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_options.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _options.asMap().entries.map((entry) {
                                  return Chip(
                                    label: Text(entry.value,
                                        style: const TextStyle(fontSize: 12)),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 14),
                                    onDeleted: () => _removeOption(entry.key),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: const BorderSide(
                                          color: Color(0xFFE5E7EB)),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildLabel('Description / Placeholder'),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecoration('Helper text for employee'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Required Field',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Switch(
                          value: _isRequired,
                          activeColor: const Color(0xFFEC4899), // Pink
                          onChanged: (val) => setState(() => _isRequired = val),
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
                      backgroundColor: const Color(0xFFEC4899), // Pink
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
