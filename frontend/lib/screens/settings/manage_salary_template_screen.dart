import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/salary_template_api_service.dart';
import '../../models/salary_template_model.dart';

class ManageSalaryTemplateScreen extends StatefulWidget {
  const ManageSalaryTemplateScreen({Key? key}) : super(key: key);

  @override
  State<ManageSalaryTemplateScreen> createState() =>
      _ManageSalaryTemplateScreenState();
}

class _ManageSalaryTemplateScreenState
    extends State<ManageSalaryTemplateScreen> {
  final SalaryTemplateApiService _apiService = SalaryTemplateApiService();
  bool _isLoading = true;
  List<SalaryTemplate> _templates = [];
  String _companyId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cId = prefs.getString('companyId');
    if (cId == null) return;

    setState(() => _companyId = cId);
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSalaryTemplates(_companyId);
      if (mounted) {
        setState(() {
          _templates = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(String id) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content:
            const Text('Are you sure you want to delete this salary template?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteSalaryTemplate(id);
        _refreshList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  void _showTemplateForm({SalaryTemplate? existingTemplate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateFormSheet(
        companyId: _companyId,
        existingTemplate: existingTemplate,
        onSave: _refreshList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Salary Templates',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTemplateCard(_templates[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateForm(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_copy_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No templates created yet',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Create templates to standardize salary structures.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(SalaryTemplate template) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      if (template.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            template.description,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit')
                      _showTemplateForm(existingTemplate: template);
                    if (val == 'copy') {
                      // Logic for duplicating
                      final copy = SalaryTemplate(
                        id: '', // New ID will be generated by backend
                        name: '${template.name} (Copy)',
                        description: template.description,
                        components: template.components,
                      );
                      _showTemplateForm(existingTemplate: copy);
                    }
                    if (val == 'delete') _deleteTemplate(template.id);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'copy', child: Text('Duplicate')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Components Preview (First 3)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPONENTS PREVIEW',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...template.components.take(3).map((comp) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(comp.name,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                          Text(
                            '${comp.type == 'earning' ? '+' : '-'} '
                            '${comp.value.toStringAsFixed(comp.calculationType == 'percentage' ? 1 : 0)}'
                            '${comp.calculationType == 'percentage' ? '%' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: comp.type == 'earning'
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    )),
                if (template.components.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${template.components.length - 3} more components',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- FORM SHEET ---

class _TemplateFormSheet extends StatefulWidget {
  final String companyId;
  final SalaryTemplate? existingTemplate;
  final VoidCallback onSave;

  const _TemplateFormSheet({
    Key? key,
    required this.companyId,
    this.existingTemplate,
    required this.onSave,
  }) : super(key: key);

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final SalaryTemplateApiService _apiService = SalaryTemplateApiService();

  List<SalaryComponent> _components = [];
  bool _isSaving = false;

  final List<String> _allowanceOptions = [
    "Basic",
    "HRA",
    "Special Allowance",
    "Bonus",
    "Conveyance",
    "Medical",
    "LTA"
  ];
  final List<String> _deductionOptions = [
    "PF",
    "ESI",
    "Professional Tax",
    "TDS",
    "Loan Recovery"
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTemplate != null) {
      _nameController.text = widget.existingTemplate!.name;
      _descController.text = widget.existingTemplate!.description;
      // Deep copy components
      _components = widget.existingTemplate!.components
          .map((c) => SalaryComponent(
                name: c.name,
                type: c.type,
                value: c.value,
                calculationType: c.calculationType,
                isStatutory: c.isStatutory,
              ))
          .toList();
    } else {
      // Default components
      _components = [
        SalaryComponent(
            name: 'Basic',
            type: 'earning',
            value: 50,
            calculationType: 'percentage'),
        SalaryComponent(
            name: 'HRA',
            type: 'earning',
            value: 20,
            calculationType: 'percentage'),
        SalaryComponent(
            name: 'PF',
            type: 'deduction',
            value: 12,
            calculationType: 'percentage'),
      ];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Add at least one component")));
      return;
    }

    setState(() => _isSaving = true);

    final template = SalaryTemplate(
      id: widget.existingTemplate?.id ?? '', // ID ignored on create
      name: _nameController.text,
      description: _descController.text,
      components: _components,
    );

    try {
      if (widget.existingTemplate != null &&
          widget.existingTemplate!.id.isNotEmpty) {
        await _apiService.updateSalaryTemplate(
            widget.existingTemplate!.id, template);
      } else {
        await _apiService.createSalaryTemplate(widget.companyId, template);
      }
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addComponent() {
    setState(() {
      _components.add(SalaryComponent(
        name: 'New Component',
        type: 'earning',
        value: 0,
        calculationType: 'percentage',
      ));
    });
  }

  void _removeComponent(int index) {
    setState(() {
      _components.removeAt(index);
    });
  }

  void _editComponent(int index, SalaryComponent updated) {
    setState(() {
      _components[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingTemplate != null &&
                          widget.existingTemplate!.id.isNotEmpty
                      ? 'Edit Template'
                      : 'Create Template',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        hintText: 'e.g. Senior Manager Structure',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Brief details about this template',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Salary Components',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: _addComponent,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF00BFA5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._components.asMap().entries.map((entry) {
                      final index = entry.key;
                      final comp = entry.value;
                      return _buildComponentItem(index, comp);
                    }).toList(),

                    const SizedBox(height: 40), // Spacing for FAB
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Template',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentItem(int index, SalaryComponent comp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: comp.type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'earning', child: Text('Earning')),
                    DropdownMenuItem(
                        value: 'deduction', child: Text('Deduction')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _editComponent(
                          index,
                          SalaryComponent(
                              name: comp.name,
                              type: val,
                              calculationType: comp.calculationType,
                              value: comp.value,
                              isStatutory: comp.isStatutory));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: comp.name),
                  optionsBuilder: (textEditingValue) {
                    final options = comp.type == 'earning'
                        ? _allowanceOptions
                        : _deductionOptions;
                    if (textEditingValue.text == '') return options;
                    return options.where((opt) => opt
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _editComponent(
                        index,
                        SalaryComponent(
                            name: selection,
                            type: comp.type,
                            calculationType: comp.calculationType,
                            value: comp.value,
                            isStatutory: comp.isStatutory));
                  },
                  fieldViewBuilder:
                      (context, textController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _editComponent(
                            index,
                            SalaryComponent(
                                name: val,
                                type: comp.type,
                                calculationType: comp.calculationType,
                                value: comp.value,
                                isStatutory: comp.isStatutory));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: comp.value.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _editComponent(
                        index,
                        SalaryComponent(
                            name: comp.name,
                            type: comp.type,
                            calculationType: comp.calculationType,
                            value: double.tryParse(val) ?? 0,
                            isStatutory: comp.isStatutory));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: comp.calculationType,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage', child: Text('% of CTC')),
                    DropdownMenuItem(value: 'flat', child: Text('Flat ₹')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _editComponent(
                          index,
                          SalaryComponent(
                              name: comp.name,
                              type: comp.type,
                              calculationType: val,
                              value: comp.value,
                              isStatutory: comp.isStatutory));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeComponent(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
