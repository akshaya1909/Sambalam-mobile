import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/reimbursement_api_service.dart';
import '../../models/reimbursement.dart';

class ReimbursementScreen extends StatefulWidget {
  final String employeeId;
  final String companyId;
  final String employeeName;

  const ReimbursementScreen({
    Key? key,
    required this.employeeId,
    required this.companyId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReimbursementApiService _apiService = ReimbursementApiService();

  // Primary Gradient Colors
  static const Color primaryGreen = Color(0xFF206C5E);
  static const Color secondaryGreen = Color(0xFF2BA98A);
  static const Color bgColor = Color(0xFFF4F7F6);

  // Tab 1: Form State
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;

  // Tab 2: History State
  bool _isLoadingHistory = true;
  List<Reimbursement> _history = [];
  String _filterStatus = 'All';
  DateTime _filterMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // IMPORTANT: Must set this for Web
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png'],
    );

    if (result != null) {
      setState(() {
        // Don't use result.paths. Use result.files
        _selectedFiles.addAll(result.files);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter amount"), backgroundColor: Colors.red),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? effectiveCompanyId = widget.companyId.isNotEmpty
        ? widget.companyId
        : prefs.getString('companyId');

    final String? effectiveEmployeeId = widget.employeeId.isNotEmpty
        ? widget.employeeId
        : prefs.getString('employeeId');

    if (effectiveCompanyId == null || effectiveEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session error. Please login again.")),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      await _apiService.createReimbursement(
        employeeId: effectiveEmployeeId,
        companyId: effectiveCompanyId,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        notes: _notesController.text,
        files: _selectedFiles,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Claim submitted successfully!"),
            backgroundColor: primaryGreen),
      );

      _amountController.clear();
      _notesController.clear();
      setState(() {
        _selectedFiles = [];
        _selectedDate = DateTime.now();
        _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
      });

      _tabController.animateTo(1);
      _loadHistory();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? effectiveCompanyId = widget.companyId.isNotEmpty
        ? widget.companyId
        : prefs.getString('companyId');

    if (effectiveCompanyId == null) return;
    setState(() => _isLoadingHistory = true);
    try {
      final data = await _apiService.getReimbursements(
        companyId: effectiveCompanyId,
        employeeId: widget.employeeId,
        status: _filterStatus,
        month: _filterMonth.month,
        year: _filterMonth.year,
      );
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF111827), // Modern Dark Blue/Black
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.employeeName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: secondaryGreen,
          indicatorWeight: 4,
          labelColor: secondaryGreen,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'ADD CLAIM'),
            Tab(text: 'MY HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // --- TAB 1: ADD FORM ---
  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Payment Amount",
                    style: TextStyle(
                        color: primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.currency_rupee, color: primaryGreen),
                    hintText: "0.00",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputLabel("Date of Spend")),
              const SizedBox(width: 16),
              Expanded(child: _buildInputLabel("Remarks")),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _dateController,
                  icon: Icons.calendar_today,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                            colorScheme:
                                const ColorScheme.light(primary: primaryGreen)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _dateController.text =
                            DateFormat('dd MMM yyyy').format(picked);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _notesController,
                  hint: "E.g. Travel",
                  icon: Icons.edit_note,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Evidence / Bills",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF374151))),
          const SizedBox(height: 12),
          _buildFilePicker(),
          const SizedBox(height: 40),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // --- TAB 2: HISTORY ---
  Widget _buildHistoryTab() {
    double totalApproved = _history
        .where((item) => item.status == 'approved')
        .fold(0, (sum, item) => sum + item.amount);

    return Column(
      children: [
        _buildHistoryHeader(totalApproved),
        _buildFilterBar(),
        Expanded(
          child: _isLoadingHistory
              ? const Center(
                  child: CircularProgressIndicator(color: primaryGreen))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return _buildHistoryCard(item);
                      },
                    ),
        )
      ],
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      String? hint,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, size: 18, color: primaryGreen) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen)),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        InkWell(
          onTap: _pickFiles,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: primaryGreen.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_a_photo_outlined, color: primaryGreen),
          ),
        ),
        ..._selectedFiles
            .map((file) => Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: file.name.endsWith('.pdf')
                          ? const Icon(Icons.picture_as_pdf, color: Colors.red)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(file.bytes!,
                                  fit: BoxFit.cover), // Use .bytes
                            ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFiles.remove(file)),
                        child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close,
                                size: 12, color: Colors.white)),
                      ),
                    )
                  ],
                ))
            .toList(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [primaryGreen, secondaryGreen]),
        boxShadow: [
          BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Submit Claim",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
      ),
    );
  }

  Widget _buildHistoryHeader(double approvedAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL APPROVED",
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text("₹ ${approvedAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['All', 'Pending', 'Approved', 'Rejected'].map((status) {
          final isSelected = _filterStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _filterStatus = status);
                _loadHistory();
              },
              selectedColor: primaryGreen,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Reimbursement item) {
    Color statusColor = item.status == 'approved'
        ? primaryGreen
        : (item.status == 'rejected' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.receipt_long, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("₹ ${item.amount}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(DateFormat('dd MMM yyyy').format(item.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(item.status.toUpperCase(),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No reimbursement history found",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
