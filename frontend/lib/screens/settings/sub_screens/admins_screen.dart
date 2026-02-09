import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/admin_api_service.dart';
import '../../../../models/admin_model.dart';

class AdminsScreen extends StatefulWidget {
  const AdminsScreen({Key? key}) : super(key: key);

  @override
  State<AdminsScreen> createState() => _AdminsScreenState();
}

class _AdminsScreenState extends State<AdminsScreen> {
  final AdminApiService _api = AdminApiService();

  List<Admin> _allAdmins = [];
  List<Admin> _filteredAdmins = [];
  bool _isLoading = true;
  String? _companyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _companyId = prefs.getString('companyId');
    if (_companyId != null) {
      _fetchAdmins();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getCompanyAdmins(_companyId!);
      if (mounted) {
        setState(() {
          _allAdmins = list;
          _filteredAdmins = list;
          _isLoading = false;
        });
        _filterList(_searchQuery); // Re-apply search if exists
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _filterList(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAdmins = _allAdmins;
      } else {
        _filteredAdmins = _allAdmins
            .where((admin) =>
                admin.name.toLowerCase().contains(query.toLowerCase()) ||
                admin.phone.contains(query) ||
                admin.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --- ACTIONS ---

  Future<void> _handleDelete(String adminId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin'),
        content: const Text('Are you sure you want to remove this admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteAdmin(adminId, _companyId!);
        _showSnack('Admin removed successfully');
        _fetchAdmins();
      } catch (e) {
        _showSnack(e.toString(), isError: true);
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

  void _openAdminForm({Admin? admin}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminFormSheet(
        companyId: _companyId!,
        existingAdmin: admin,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchAdmins();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF3F4F6);
    const Color primary = Color(0xFF4F46E5); // Matching Users Screen Indigo

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Admins',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdminForm(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Admin'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: _filterList,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAdmins.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAdmins.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _AdminCard(
                            admin: _filteredAdmins[index],
                            onEdit: () =>
                                _openAdminForm(admin: _filteredAdmins[index]),
                            onDelete: () =>
                                _handleDelete(_filteredAdmins[index].id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shield_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No admins found',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Admin Card ---

class _AdminCard extends StatelessWidget {
  final Admin admin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminCard({
    Key? key,
    required this.admin,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  String getInitials(String name) {
    if (name.isEmpty) return 'A';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEEF2FF), // Light Indigo
              child: Text(
                getInitials(admin.name),
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (admin.email.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, admin.email),
                  if (admin.phone.isNotEmpty)
                    _buildInfoRow(Icons.phone_outlined, admin.phone),

                  const SizedBox(height: 8),
                  // Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4338CA),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Actions
            Column(
              children: [
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Add/Edit Form Sheet ---

class _AdminFormSheet extends StatefulWidget {
  final String companyId;
  final Admin? existingAdmin;
  final AdminApiService api;
  final VoidCallback onSuccess;

  const _AdminFormSheet({
    Key? key,
    required this.companyId,
    this.existingAdmin,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends State<_AdminFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingAdmin?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existingAdmin?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.existingAdmin?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.existingAdmin == null) {
        // Create
        await widget.api.createAdmin(
          companyId: widget.companyId,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      } else {
        // Update
        await widget.api.updateAdmin(
          adminId: widget.existingAdmin!.id,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4F46E5);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                widget.existingAdmin == null ? 'Add Admin' : 'Edit Admin',
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
                    _buildLabel('Full Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Enter full name'),
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Phone Number *'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      readOnly: widget.existingAdmin !=
                          null, // Prevents keyboard from opening
                      enabled: widget.existingAdmin == null,
                      decoration: _inputDecoration(widget.existingAdmin == null
                                  ? 'Enter 10 digit number'
                                  : 'Phone number cannot be changed' // Optional hint change
                              )
                          .copyWith(
                        // Optional: make it look slightly greyed out when disabled
                        fillColor: widget.existingAdmin != null
                            ? Colors.grey[200]
                            : const Color(0xFFF9FAFB),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone is required';
                        if (v.length != 10)
                          return 'Enter valid 10 digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildLabel('Email *'),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Enter email address'),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Email is required';
                        }
                        // Basic format check using Regex
                        if (!_emailRegex.hasMatch(v.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                      widget.existingAdmin == null
                          ? 'Create Admin'
                          : 'Update Admin',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
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
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
}
