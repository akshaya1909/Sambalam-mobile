import 'package:flutter/material.dart';
import '../../../models/staff_model.dart';
import '../../../models/bank_details_model.dart';
import '../../api/bank_api_service.dart';
import '../../../utils/validators.dart';

class BankDetailsScreen extends StatefulWidget {
  final Staff staff;
  const BankDetailsScreen({Key? key, required this.staff}) : super(key: key);

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen>
    with SingleTickerProviderStateMixin {
  final BankApiService _api = BankApiService();
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  BankDetails? _savedDetails;

  // Controllers
  final TextEditingController _holderCtrl = TextEditingController();
  final TextEditingController _accNumCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();
  final TextEditingController _upiIdCtrl = TextEditingController();
  final TextEditingController _upiPhoneCtrl = TextEditingController();

  String _selectedAccType = "Savings";

  // Theme Colors
  final Color primaryDeepTeal = const Color(0xFF206C5E);
  final Color secondaryTeal = const Color(0xFF2BA98A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final data = await _api.getBankDetails(widget.staff.id);
    if (mounted) {
      setState(() {
        _savedDetails = data;
        if (data != null) {
          _holderCtrl.text = data.accountHolderName ?? "";
          _accNumCtrl.text = data.accountNumber ?? "";
          _bankNameCtrl.text = data.bankName ?? "";
          _ifscCtrl.text = data.ifscCode ?? "";
          _branchCtrl.text = data.branch ?? "";
          _selectedAccType = data.accountType ?? "Savings";
          _upiIdCtrl.text = data.upiId ?? "";
          _upiPhoneCtrl.text = data.linkedMobileNumber ?? "";
          if (data.type == "UPI") _tabController.animateTo(1);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    bool isBank = _tabController.index == 0;
    Map<String, dynamic> payload = {"employeeId": widget.staff.id};

    if (isBank) {
      if (!Validators.isValidName(_holderCtrl.text)) {
        _showToast("Invalid Account Holder Name", Colors.red);
        return;
      }
      if (!Validators.isValidIFSC(_ifscCtrl.text)) {
        _showToast("Invalid IFSC Code", Colors.red);
        return;
      }
      payload.addAll({
        "type": "Bank Account",
        "accountHolderName": _holderCtrl.text,
        "accountNumber": _accNumCtrl.text,
        "bankName": _bankNameCtrl.text,
        "ifscCode": _ifscCtrl.text,
        "branch": _branchCtrl.text,
        "accountType": _selectedAccType,
      });
    } else {
      final phoneErr = Validators.validateIndianPhoneNumber(_upiPhoneCtrl.text);
      if (_upiIdCtrl.text.isEmpty) {
        _showToast("UPI ID is required", Colors.red);
        return;
      }
      if (phoneErr != null) {
        _showToast(phoneErr, Colors.red);
        return;
      }
      payload.addAll({
        "type": "UPI",
        "upiId": _upiIdCtrl.text,
        "linkedMobileNumber": _upiPhoneCtrl.text,
      });
    }

    setState(() => _isSaving = true);
    final success = await _api.saveBankDetails(payload);
    setState(() => _isSaving = false);

    if (success) {
      _showToast("Details updated successfully", Colors.green);
      _fetchDetails();
    } else {
      _showToast("Failed to save details", Colors.red);
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.staff.name}'s Bank Details",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [primaryDeepTeal, secondaryTeal]))),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDeepTeal))
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: primaryDeepTeal,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: secondaryTeal,
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.account_balance),
                          text: "Bank Account"),
                      Tab(icon: Icon(Icons.qr_code), text: "UPI"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBankForm(),
                      _buildUpiForm(),
                    ],
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildBankForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField("Account Holder’s Name", _holderCtrl, "Enter Name"),
          _buildTextField("Account Number", _accNumCtrl, "Enter Account Number",
              isNum: true),
          _buildTextField("Bank Name", _bankNameCtrl, "Enter Bank Name"),
          _buildTextField("IFSC Code", _ifscCtrl, "Enter IFSC Code"),
          const SizedBox(height: 10),
          _buildDropdown(),
          _buildTextField("Branch Name", _branchCtrl, "Enter Branch"),
        ],
      ),
    );
  }

  Widget _buildUpiForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextField("Staff UPI ID", _upiIdCtrl, "Enter UPI ID"),
          _buildTextField(
              "Linked Mobile Number", _upiPhoneCtrl, "Enter 10 digit number",
              isNum: true),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint,
      {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: secondaryTeal, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Account Type",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAccType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          items: ["Savings", "Current", "Salary"]
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccType = v!),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5))
      ]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Save Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
