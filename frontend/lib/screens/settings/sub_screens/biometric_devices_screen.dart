import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/biometric_api_service.dart';
import '../../../../models/biometric_device_model.dart';
import '../../../../models/branch_model.dart';

class BiometricDevicesScreen extends StatefulWidget {
  const BiometricDevicesScreen({Key? key}) : super(key: key);

  @override
  State<BiometricDevicesScreen> createState() => _BiometricDevicesScreenState();
}

class _BiometricDevicesScreenState extends State<BiometricDevicesScreen> {
  final BiometricApiService _api = BiometricApiService();

  List<BiometricDevice> _devices = [];
  List<Branch> _allBranches = [];
  bool _isLoading = true;
  String? _companyId;

  // Feature Toggle (Client-side state only for UI demo)
  bool _biometricsEnabled = true;

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
        _fetchDevices(),
        _fetchBranches(),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDevices() async {
    try {
      final list = await _api.getCompanyDevices(_companyId!);
      if (mounted) setState(() => _devices = list);
    } catch (e) {
      _showSnack('Failed to load devices', isError: true);
    }
  }

  Future<void> _fetchBranches() async {
    try {
      final list = await _api.getBranches(_companyId!);
      if (mounted) setState(() => _allBranches = list);
    } catch (e) {
      // Silent fail is okay for dropdown
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
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
        await _api.deleteDevice(id);
        _showSnack('Device deleted');
        _fetchDevices();
      } catch (e) {
        _showSnack('Failed to delete device', isError: true);
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

  void _openDeviceForm({BiometricDevice? device}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close
      builder: (ctx) => _DeviceFormDialog(
        companyId: _companyId!,
        existingDevice: device,
        branches: _allBranches,
        api: _api,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchDevices();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF4F6FB);
    const Color primary = Color(0xFF3B82F6); // Blue

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
          'Biometric Devices',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Enable/Disable Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Enable Biometric Attendance',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Use biometric devices for employee attendance',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _biometricsEnabled,
                      activeColor: primary,
                      onChanged: (val) =>
                          setState(() => _biometricsEnabled = val),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_biometricsEnabled) ...[
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Registered Devices',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openDeviceForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Device'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _devices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _DeviceCard(
                              device: _devices[index],
                              onEdit: () =>
                                  _openDeviceForm(device: _devices[index]),
                              onDelete: () => _handleDelete(_devices[index].id),
                            );
                          },
                        ),
            ]
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
          Icon(Icons.fingerprint, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No devices registered',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET: Device Card ---

class _DeviceCard extends StatelessWidget {
  final BiometricDevice device;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DeviceCard({
    Key? key,
    required this.device,
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fingerprint,
                      color: Color(0xFF4B5563), size: 24),
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
                              device.deviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7), // Light Green
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
                        children: device.branchNames.isNotEmpty
                            ? device.branchNames
                                .map((name) => _branchChip(name))
                                .toList()
                            : [_branchChip('All Branches')],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Serial: ${device.serialNumber} • Type: Fingerprint',
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
                  onPressed: () {}, // Dummy sync
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Sync'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(40, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child:
                      const Icon(Icons.settings, size: 18, color: Colors.grey),
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

class _DeviceFormDialog extends StatefulWidget {
  final String companyId;
  final BiometricDevice? existingDevice;
  final List<Branch> branches;
  final BiometricApiService api;
  final VoidCallback onSuccess;

  const _DeviceFormDialog({
    Key? key,
    required this.companyId,
    this.existingDevice,
    required this.branches,
    required this.api,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_DeviceFormDialog> createState() => _DeviceFormDialogState();
}

class _DeviceFormDialogState extends State<_DeviceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _serialCtrl;
  List<String> _selectedBranchIds = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existingDevice?.deviceName ?? '');
    _serialCtrl =
        TextEditingController(text: widget.existingDevice?.serialNumber ?? '');
    if (widget.existingDevice != null) {
      _selectedBranchIds = List.from(widget.existingDevice!.branchIds);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'deviceName': _nameCtrl.text.trim(),
      'serialNumber': _serialCtrl.text.trim(),
      'branchIds': _selectedBranchIds,
    };

    try {
      if (widget.existingDevice == null) {
        await widget.api.createDevice(widget.companyId, data);
      } else {
        await widget.api.updateDevice(widget.existingDevice!.id, data);
      }
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device saved successfully')),
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
    // Using a Dialog but making its content scrollable
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existingDevice == null
                    ? 'Register Device'
                    : 'Edit Device',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLabel('Device Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('e.g. Main Gate'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Serial Number *'),
                    TextFormField(
                      controller: _serialCtrl,
                      decoration: _inputDecoration('Enter Serial Number'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Branches (Select multiple)'),
                    Container(
                      height: 150, // Slightly taller for better UX
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
                                  activeColor: const Color(0xFF3B82F6),
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
                      backgroundColor: const Color(0xFF3B82F6),
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
