import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/bank_api_service.dart';
import '../../models/bank_details_model.dart';

class BankDetailsScreen extends StatefulWidget {
  final String employeeId;

  const BankDetailsScreen({Key? key, required this.employeeId})
      : super(key: key);

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen>
    with SingleTickerProviderStateMixin {
  final BankApiService _api = BankApiService();
  static const Color _primary = Color(0xFF206C5E);
  static const Color _bg = Color(0xFFF5F7FA);

  late TabController _tabController;
  bool _isLoading = true;
  BankDetails? _details;

  // Edit States
  bool _isEditingBank = false;
  bool _isEditingUpi = false;
  bool _isSaving = false;

  // Bank Controllers
  final _bankNameCtrl = TextEditingController();
  final _accHolderCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  String _selectedAccType = 'Savings';

  // UPI Controllers
  final _upiIdCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bankNameCtrl.dispose();
    _accHolderCtrl.dispose();
    _accNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiIdCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _api.getBankDetails(widget.employeeId);
    if (mounted) {
      setState(() {
        _details = data;
        _isLoading = false;

        // If data exists, populate controllers
        if (data != null) {
          _populateControllers(data);

          // Determine initial edit state
          _isEditingBank =
              (data.accountNumber == null || data.accountNumber!.isEmpty);
          _isEditingUpi = (data.upiId == null || data.upiId!.isEmpty);

          // Switch tab based on existing data type if needed,
          // or default to Bank (index 0)
        } else {
          // No data, default to edit mode for both
          _isEditingBank = true;
          _isEditingUpi = true;
        }
      });
    }
  }

  void _populateControllers(BankDetails data) {
    _bankNameCtrl.text = data.bankName ?? '';
    _accHolderCtrl.text = data.accountHolderName ?? '';
    _accNumberCtrl.text = data.accountNumber ?? '';
    _ifscCtrl.text = data.ifscCode ?? '';
    _branchCtrl.text = data.branch ?? '';
    _selectedAccType = data.accountType ?? 'Savings';

    _upiIdCtrl.text = data.upiId ?? '';
    _mobileCtrl.text = data.linkedMobileNumber ?? '';
  }

  Future<void> _saveBank() async {
    if (_accNumberCtrl.text.isEmpty || _ifscCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory bank fields')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      "employeeId": widget.employeeId,
      "type": "Bank Account",
      "bankName": _bankNameCtrl.text,
      "accountHolderName": _accHolderCtrl.text,
      "accountNumber": _accNumberCtrl.text,
      "ifscCode": _ifscCtrl.text.toUpperCase(),
      "branch": _branchCtrl.text,
      "accountType": _selectedAccType,
    };

    final success = await _api.saveBankDetails(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank details saved successfully')),
        );
        setState(() => _isEditingBank = false);
        _loadData(); // Refresh to get updated object
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save details')),
        );
      }
    }
  }

  Future<void> _saveUpi() async {
    if (_upiIdCtrl.text.isEmpty || _mobileCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter valid UPI ID and 10-digit Mobile')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      "employeeId": widget.employeeId,
      "type": "UPI",
      "upiId": _upiIdCtrl.text,
      "linkedMobileNumber": _mobileCtrl.text,
    };

    final success = await _api.saveBankDetails(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI details saved successfully')),
        );
        setState(() => _isEditingUpi = false);
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Information',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bank Account', icon: Icon(Icons.account_balance)),
            Tab(text: 'UPI Details', icon: Icon(Icons.qr_code)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBankTab(),
                _buildUpiTab(),
              ],
            ),
    );
  }

  // --- BANK TAB UI ---
  Widget _buildBankTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status Card
          _buildStatusCard(
              isVerified: _details?.isAccnVerified ?? false,
              type: 'Bank Account'),
          const SizedBox(height: 20),

          // Content
          if (!_isEditingBank && _details?.accountNumber != null)
            _buildBankReadOnly()
          else
            _buildBankForm(),
        ],
      ),
    );
  }

  Widget _buildBankReadOnly() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bank Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, color: _primary),
                onPressed: () => setState(() => _isEditingBank = true),
              )
            ],
          ),
          const Divider(),
          _DataRow(label: 'Bank Name', value: _details?.bankName),
          _DataRow(label: 'Account Holder', value: _details?.accountHolderName),
          _DataRow(
              label: 'Account Number',
              value: _details?.accountNumber,
              isMono: true),
          _DataRow(label: 'IFSC Code', value: _details?.ifscCode, isMono: true),
          _DataRow(label: 'Account Type', value: _details?.accountType),
          _DataRow(label: 'Branch', value: _details?.branch),
        ],
      ),
    );
  }

  Widget _buildBankForm() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Bank Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _CustomTextField(
              label: 'Bank Name',
              controller: _bankNameCtrl,
              hint: 'e.g. HDFC Bank'),
          _CustomTextField(
              label: 'Account Holder Name',
              controller: _accHolderCtrl,
              hint: 'As per passbook'),
          _CustomTextField(
              label: 'Account Number',
              controller: _accNumberCtrl,
              inputType: TextInputType.number),
          _CustomTextField(
              label: 'IFSC Code', controller: _ifscCtrl, hint: 'ABCD0123456'),
          _CustomDropdown(
            label: 'Account Type',
            value: _selectedAccType,
            items: const ['Savings', 'Current', 'Salary', 'NRE/NRO'],
            onChanged: (val) => setState(() => _selectedAccType = val!),
          ),
          _CustomTextField(label: 'Branch', controller: _branchCtrl),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_details?.accountNumber !=
                  null) // Show Cancel only if data exists
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isEditingBank = false;
                      _populateControllers(_details!); // Revert changes
                    }),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              if (_details?.accountNumber != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBank,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Details',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- UPI TAB UI ---
  Widget _buildUpiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatusCard(
              isVerified: _details?.isUpiVerified ?? false, type: 'UPI ID'),
          const SizedBox(height: 20),
          if (!_isEditingUpi && _details?.upiId != null)
            _buildUpiReadOnly()
          else
            _buildUpiForm(),
        ],
      ),
    );
  }

  Widget _buildUpiReadOnly() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('UPI Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, color: _primary),
                onPressed: () => setState(() => _isEditingUpi = true),
              )
            ],
          ),
          const Divider(),
          _DataRow(label: 'UPI ID', value: _details?.upiId, isMono: true),
          _DataRow(
              label: 'Linked Mobile',
              value: '+91 ${_details?.linkedMobileNumber}',
              isMono: true),
        ],
      ),
    );
  }

  Widget _buildUpiForm() {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit UPI Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _CustomTextField(
              label: 'UPI ID', controller: _upiIdCtrl, hint: 'example@okhdfc'),
          _CustomTextField(
            label: 'Linked Mobile Number',
            controller: _mobileCtrl,
            inputType: TextInputType.phone,
            maxLength: 10,
            prefix: Container(
              padding: const EdgeInsets.all(12),
              child: const Text('+91', style: TextStyle(color: Colors.black54)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_details?.upiId != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isEditingUpi = false;
                      _populateControllers(_details!);
                    }),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              if (_details?.upiId != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUpi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save Details',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- COMMON WIDGETS ---

  Widget _buildStatusCard({required bool isVerified, required String type}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified ? Colors.teal.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.teal.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.error_outline,
            color: isVerified ? Colors.teal : Colors.amber.shade800,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Verified' : 'Not Verified',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVerified
                        ? Colors.teal.shade900
                        : Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified
                      ? '$type has been verified.'
                      : '$type is pending verification.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isVerified
                        ? Colors.teal.shade700
                        : Colors.amber.shade800,
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

class _ContentCard extends StatelessWidget {
  final Widget child;
  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isMono;

  const _DataRow({required this.label, this.value, this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value ?? '--',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: isMono ? 'monospace' : null,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType inputType;
  final Widget? prefix;
  final int? maxLength;

  const _CustomTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.inputType = TextInputType.text,
    this.prefix,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: inputType,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefix,
              counterText: "", // Hide character counter
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF206C5E), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF206C5E), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }
}
